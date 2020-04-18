import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:intl/intl.dart';
import 'package:ncov_tracker/models/location_model.dart';
import 'package:ncov_tracker/models/more_results.dart';

class LocationData extends ChangeNotifier {
  String _searchTxt = "";
  int _counter = 0;
  int _initialPage = 0;
  int _numberOfCols;
  bool _loading = true;
  dom.Document _document;
  MoreResults _moreResults;

  List<String> _countriesList = [];
  List<String> _totalCasesList = [];
  List<String> _newCasesList = [];
  List<String> _totalDeathsList = [];
  List<String> _newDeathsList = [];
  List<String> _totalRecoveredList = [];
  List<String> _activeCasesList = [];
  List<String> _seriousCriticalList = [];
  List<dom.Element> _totalCases = [];
  List<dom.Element> _countryRow = [];
  List<LocationModel> _locationList = [];

  DateTime _date = DateTime.now();

  TextEditingController _controller = TextEditingController();

  LocationData() {
    loadData();
    notifyListeners();
  }

  int get initialPage => _initialPage;

  setInitialPage(int index) {
    _initialPage = index;
    notifyListeners();
  }

  String get searchTxt {
    return _searchTxt;
  }

  TextEditingController get controller {
    return _controller;
  }

  int get numberOfCols => _numberOfCols;
  setNumberOfCols(int num) {
    _numberOfCols = num;
  }

  search(String str) {
    _controller.addListener(() {
      _searchTxt = _controller.text;
    });
    notifyListeners();
  }

  dom.Document get document {
    return _document;
  }

  MoreResults get moreResults {
    return _moreResults;
  }

  _setMoreResults(MoreResults moreResults) {
    _moreResults = moreResults;
  }

  _setDocument(dom.Document doc) {
    _document = doc;
  }

  void clearTxt() {
    _controller.clear();
    Timer(Duration(seconds: 1), () {
      setLoading(true);
    });
    Timer(Duration(seconds: 1), () {
      setLoading(false);
    });

    notifyListeners();
  }

  int get counter {
    return _counter;
  }

  String get date {
    return DateFormat.yMMMd().add_jm().format(_date);
  }

  _setDate(DateTime theDate) {
    _date = theDate;
  }

  bool get loading => _loading;

  setLoading(bool l) {
    _loading = l;
    notifyListeners();
  }

  List<String> get countriesList {
    return _countriesList;
  }

  List<String> get totalCasesList {
    return _totalCasesList;
  }

  List<String> get newCasesList {
    return _newCasesList;
  }

  List<String> get totalDeathsList {
    return _totalDeathsList;
  }

  List<String> get newDeathsList {
    return _newDeathsList;
  }

  List<String> get totalRecoveredList {
    return _totalRecoveredList;
  }

  List<String> get activeCasesList {
    return _activeCasesList;
  }

  List<String> get seriousCriticalList {
    return _seriousCriticalList;
  }

  List<dom.Element> totalCases() {
    return _totalCases;
  }

  List<dom.Element> countryRow() {
    return _countryRow;
  }

  setCountryRow(List<dom.Element> row) {
    _countryRow = row;
  }

  List<LocationModel> get locationList {
    return _locationList;
  }

  void _removeLastItem() {
    _countriesList.removeLast();
    _totalCasesList.removeLast();
    _newCasesList.removeLast();
    _totalDeathsList.removeLast();
    _newDeathsList.removeLast();
    _totalRecoveredList.removeLast();
    _activeCasesList.removeLast();
    _seriousCriticalList.removeLast();
    _locationList.removeLast();
    notifyListeners();
  }

  void _clearLists() {
    _countriesList.clear();
    _totalCasesList.clear();
    _newCasesList.clear();
    _totalDeathsList.clear();
    _newDeathsList.clear();
    _totalRecoveredList.clear();
    _activeCasesList.clear();
    _seriousCriticalList.clear();
    _locationList.clear();
    notifyListeners();
  }

  void _addToDataList() {
    for (int i = 0; i < _countriesList.length; i++) {
      Map<String, dynamic> json = {
        'country': _countriesList[i],
        'totalCases': _totalCasesList[i],
        'newCases': _newCasesList[i],
        'totalDeaths': _totalDeathsList[i],
        'newDeaths': _newDeathsList[i],
        'totalRecovered': _totalRecoveredList[i],
        'activeCases': _activeCasesList[i],
        'seriousCritical': _seriousCriticalList[i],
      };
      locationList.add(LocationModel.fromJson(json));
    }
  }

  void loadData() async {
    // clear list
    _clearLists();
    _setDate(DateTime.now());
    setLoading(true);
    // make http request
    http.Client client = http.Client();
    http.Response response =
        await client.get('https://www.worldometers.info/coronavirus/');
    http.Response cols =
        await client.get('https://jaimebis.000webhostapp.com/get.php');
    var colNum = jsonDecode(cols.body);
    int col = int.parse(colNum[2]['selected_bg']);
    print(col);
    setNumberOfCols(col);
    // parse response body
    var document = parse(response.body);
    _setDocument(document);
    _getTotals();
    // select table data
    _totalCases =
        document.querySelectorAll('#main_table_countries_today > tbody > tr');
    // loop and extract data

    for (var i = 0; i < _totalCases.length; i++) {
      if (!_totalCases[i].attributes.containsKey('data-continent')) {
        List<dom.Element> row = _totalCases[i].querySelectorAll('td');

        for (int x = 0; x < row.length; x++) {
          if (!row[x].attributes.containsKey('data-continent')) {
            if (x % numberOfCols == 0) {
              if (row[x].innerHtml.contains('<a')) {
                _countriesList.add(row[x].querySelector('a').innerHtml.trim());
              } else if (row[x].innerHtml.contains('<span')) {
                _countriesList
                    .add(row[x].querySelector('span').innerHtml.trim());
              } else {
                _countriesList.add(row[x].innerHtml.trim());
              }
            } else if (x % numberOfCols == 1) {
              _totalCasesList.add(row[x].innerHtml.trim());
            } else if (x % numberOfCols == 2) {
              if (row[x].innerHtml.trim().length != 0) {
                _newCasesList.add(row[x].innerHtml.trim());
              } else {
                _newCasesList.add('NO');
              }
            } else if (x % numberOfCols == 3) {
              if (row[x].innerHtml.trim().length != 0) {
                _totalDeathsList.add(row[x].innerHtml.trim());
              } else {
                _totalDeathsList.add('NONE');
              }
            } else if (x % numberOfCols == 4) {
              if (row[x].innerHtml.trim().length != 0) {
                _newDeathsList.add(row[x].innerHtml.trim());
              } else {
                _newDeathsList.add('NO');
              }
            } else if (x % numberOfCols == 5) {
              if (row[x].innerHtml.trim().length != 0) {
                _totalRecoveredList.add(row[x].innerHtml.trim() == "N/A"
                    ? "NONE"
                    : row[x].innerHtml.trim());
              } else {
                _totalRecoveredList.add('NONE');
              }
            } else if (x % numberOfCols == 6) {
              if (row[x].innerHtml.trim().length != 0) {
                _activeCasesList.add(row[x].innerHtml.trim());
              } else {
                _activeCasesList.add('NONE');
              }
            } else if (x % numberOfCols == 7) {
              if (row[x].innerHtml.trim().length != 0) {
                _seriousCriticalList.add(row[x].innerHtml.trim());
              } else {
                _seriousCriticalList.add('NONE');
              }
            }
          }
        }
      }
    }

    print(_countriesList.length);
    print(_activeCasesList.length);

    _addToDataList();
    setLoading(false);
    _removeLastItem();
  }

  void _getTotals() {
    List<dom.Element> totalsCDR = document
        .querySelectorAll('body div#maincounter-wrap .maincounter-number span');
    print('printing');
    List<dom.Element> totalsARC =
        document.querySelectorAll('body div.panel_front div.number-table-main');
    List<dom.Element> totalsSD =
        document.querySelectorAll('body div.panel_front span.number-table');
    _setMoreResults(MoreResults(
      totalCases: totalsCDR[0].innerHtml.trim() ?? 'NONE',
      totalDeaths: totalsCDR[1].innerHtml.trim() ?? 'NONE',
      totalRecovered: totalsCDR[2].innerHtml.trim() ?? 'NONE',
      totalActiveCases: totalsARC[0].innerHtml.trim() ?? 'NONE',
      totalClosedCases: totalsARC[1].innerHtml.trim() ?? 'NONE',
      totalMild: totalsSD[0].innerHtml.trim() ?? 'NONE',
      totalSeriousCritical: totalsSD[1].innerHtml.trim() ?? 'NONE',
      totalDischarged: totalsSD[2].innerHtml.trim() ?? 'NONE',
    ));
  }
}
