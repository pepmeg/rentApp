import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService extends ChangeNotifier {
  List<ConnectivityResult> _status = [ConnectivityResult.none];
  List<ConnectivityResult> get status => _status;

  Stream<List<ConnectivityResult>> get onConnectivityChanged => Connectivity().onConnectivityChanged;

  ConnectivityService() {
    _init();
  }

  Future<void> _init() async {
    _status = await Connectivity().checkConnectivity();
    notifyListeners();

    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _status = results;
      notifyListeners();
    });
  }

  bool get hasInternet {
    return _status.any((result) => result != ConnectivityResult.none);
  }
}