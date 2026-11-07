import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  Timer? _bannerTimer;

  bool _isOnline = true;
  bool _hasEstablishedStatus = false;
  int _redirectToken = 0;
  bool _showTransitionBanner = false;
  bool _transitionToOnline = false;

  bool get isOnline => _isOnline;

  /// Aumenta solo cuando el estado pasa de online a offline o al revés.
  int get redirectToken => _redirectToken;

  bool get showTransitionBanner => _showTransitionBanner;

  /// Verdadero si el último cambio fue hacia online.
  bool get transitionToOnline => _transitionToOnline;

  String get transitionMessage =>
      _transitionToOnline
          ? 'Cambiando de modo offline a modo online'
          : 'Cambiando de modo online a modo offline';

  ConnectivityProvider() {
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      _hasEstablishedStatus = true;
      _isOnline = true;
      notifyListeners();
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    final online =
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet;

    if (!_hasEstablishedStatus) {
      _hasEstablishedStatus = true;
      _isOnline = online;
      notifyListeners();
      return;
    }

    if (online == _isOnline) return;

    _isOnline = online;
    _transitionToOnline = online;
    _redirectToken++;
    _showTransitionBanner = true;
    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(seconds: 6), () {
      _showTransitionBanner = false;
      notifyListeners();
    });
    notifyListeners();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
