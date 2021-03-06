import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:loading_animations/loading_animations.dart';
import 'package:ncov_tracker/constants/const_vars.dart';
import 'package:ncov_tracker/models/location_data_model.dart';
import 'package:ncov_tracker/models/location_model.dart';
import 'package:http/http.dart' as http;
import 'package:latlong/latlong.dart';
import 'package:ncov_tracker/pages/countrydetails_page.dart';
import 'package:ncov_tracker/widgets/data_container.dart';

class MapsPage extends StatefulWidget {
  final List<LocationModel> locationData;

  MapsPage({this.locationData});

  @override
  _MapsPageState createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> with TickerProviderStateMixin {
  LatLng initialPos = LatLng(12, 121);
  bool didTap = false;
  MapController mapController = MapController();
  LocationModel initialLocation;

  List<Marker> markerList = [];
  List<LocationDataModel> locData = [];
  bool _loading = true;

  Future<void> loadLocations() async {
    setState(() {
      _loading = true;
    });
    http.Client client = http.Client();
    http.Response response = await client
        .get('https://coronavirus-tracker-api.herokuapp.com/confirmed');
    var body = jsonDecode(response.body);

    var urlLocArr = body['locations'];

    for (int i = 0; i < urlLocArr.length; i++) {
      Map<String, dynamic> data = {
        'country': urlLocArr[i]['country'],
        'lat': urlLocArr[i]['coordinates']['lat'],
        'long': urlLocArr[i]['coordinates']['long'],
      };
      locData.add(LocationDataModel.fromJson(data));
    }
    client.close();
    setState(() {
      _loading = false;
    });
  }

  loadData() {
    loadLocations();

    Future<MapController> mc = mapController.onReady;
    mc.whenComplete(() {}).catchError((onError) {
      setState(() {
        _loading = false;
      });
    });
  }

  void _animateMapMove(LatLng destLoc, double destZoom) {
    final _latTween = Tween<double>(
        begin: mapController.center.latitude, end: destLoc.latitude);
    final _lngTween = Tween<double>(
        begin: mapController.center.longitude, end: destLoc.longitude);
    final _zoomTween = Tween<double>(begin: mapController.zoom, end: destZoom);

    var controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    Animation<double> animation =
        CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      mapController.move(
        LatLng(
          _latTween.evaluate(animation),
          _lngTween.evaluate(animation),
        ),
        _zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    setState(() {
      locData.clear();
    });
    super.dispose();
  }

  _flutterMap() {
    return FlutterMap(
      key: Key('mapss'),
      mapController: mapController,
      options: new MapOptions(
          center: initialPos,
          zoom: 1.5,
          maxZoom: 4.0,
          minZoom: 1,
          interactive: true,
          debug: true,
          onPositionChanged: (pos, b) {
            initialPos = pos.center;
          }),
      layers: [
        TileLayerOptions(
          backgroundColor: Color(0xff191a1a),
          urlTemplate:
              'https://tile.jawg.io/dark/{z}/{x}/{y}.png?api-key=community',
          subdomains: ['a', 'b', 'c'],
        ),
        MarkerLayerOptions(
          markers: List.generate(
            widget.locationData.length,
            (i) {
              for (int x = 0; x < locData.length; x++) {
                if (locData[x].country == widget.locationData[i].country) {
                  var data = locData[x];
                  return Marker(
                    point: LatLng(
                      double.parse(data.lat),
                      double.parse(data.long),
                    ),
                    builder: (context) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            didTap = true;
                            initialLocation = widget.locationData[i];
                            _animateMapMove(
                                LatLng(
                                  double.parse(data.lat),
                                  double.parse(data.long),
                                ),
                                4.0);
                            initialPos = LatLng(
                              double.parse(data.lat),
                              double.parse(data.long),
                            );
                          });
                        },
                        child: Icon(
                          Icons.location_on,
                          color: int.parse(widget.locationData[i].totalCases
                                      .replaceAll(',', '')) >=
                                  10
                              ? Colors.redAccent[100]
                              : Colors.greenAccent[100],
                          size: 40.0,
                        ),
                      );
                    },
                  );
                }
              }
              return Marker();
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    return Scaffold(
      backgroundColor: richBlack,
      appBar: AppBar(
        title: Text(
          'Maps',
          style: TextStyle(
            fontFamily: pBold,
          ),
        ),
        centerTitle: true,
        backgroundColor: box,
      ),
      body: Container(
        color: box,
        child: _loading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    LoadingBouncingGrid.square(
                      backgroundColor: one,
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Text(
                      'Loading',
                      style: TextStyle(
                        color: dustStorm,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: <Widget>[
                  Expanded(
                    flex: 4,
                    child: Stack(
                      children: <Widget>[
                        _flutterMap(),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: EdgeInsets.only(right: 10.0, bottom: 10.0),
                            child: IconButton(
                              icon: Icon(
                                Icons.my_location,
                                size: 30.0,
                              ),
                              color: Colors.white,
                              onPressed: () {
                                _animateMapMove(initialPos, 3.0);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: !didTap
                        ? Container(
                            width: double.infinity,
                            color: box,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  Icons.location_on,
                                  color: Colors.redAccent[100],
                                  size: 30.0,
                                ),
                                Text(
                                  'Select a Marker',
                                  style: Theme.of(context)
                                      .textTheme
                                      .body2
                                      .copyWith(
                                        fontSize: 25.0,
                                        fontFamily: pBold,
                                      ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            color: box,
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 5.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Icon(
                                      Icons.location_on,
                                      color: Colors.redAccent[100],
                                    ),
                                    Text(
                                      '${initialLocation.country}',
                                      style: TextStyle(
                                        fontSize: 20.0,
                                        color: antiFlashWhite,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 5.0,
                                ),
                                Row(
                                  children: <Widget>[
                                    DataContainer(
                                      data: initialLocation.totalCases,
                                      type: 'Total Cases',
                                      dataColor: int.parse(initialLocation
                                                  .totalCases
                                                  .replaceAll(',', '')) >
                                              10
                                          ? Colors.amberAccent[100]
                                          : Colors.greenAccent[100],
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 5.0,
                                ),
                                Row(
                                  children: <Widget>[
                                    DataContainer(
                                      data: initialLocation.totalRecovered,
                                      type: 'Total Recovered',
                                      dataColor: initialLocation
                                                  .totalRecovered ==
                                              'NONE'
                                          ? Colors.greenAccent[100]
                                          : int.parse(initialLocation
                                                      .totalRecovered
                                                      .replaceAll(',', '')) >
                                                  10
                                              ? Colors.greenAccent[100]
                                              : Colors.redAccent[100],
                                    ),
                                    DataContainer(
                                      data: initialLocation.totalDeaths,
                                      type: 'Total Deaths',
                                      dataColor: initialLocation.totalDeaths ==
                                              'NONE'
                                          ? Colors.greenAccent[100]
                                          : int.parse(initialLocation
                                                      .totalDeaths
                                                      .replaceAll(',', '')) >
                                                  10
                                              ? Colors.redAccent[100]
                                              : Colors.greenAccent[100],
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 5.0,
                                ),
                                Expanded(
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: FlatButton(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      color: one,
                                      onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  CountryDetails(
                                                    locationModel:
                                                        initialLocation,
                                                  ))),
                                      child: Text(
                                        'Historical',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: pBold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 5.0,
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
