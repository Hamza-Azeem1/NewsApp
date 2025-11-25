import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

enum AppConnectionStatus { online, offline }

class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final _controller = StreamController<AppConnectionStatus>.broadcast();
  AppConnectionStatus _currentStatus = AppConnectionStatus.online;

  Stream<AppConnectionStatus> get statusStream => _controller.stream;
  AppConnectionStatus get currentStatus => _currentStatus;

  Future<void> init() async {
    // Initial check (real internet, not just wifi on)
    final hasNet = await InternetConnectionChecker().hasConnection;
    _updateStatus(hasNet ? AppConnectionStatus.online : AppConnectionStatus.offline);

    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((_) async {
      // When connection type changes, verify real internet
      final hasInternet = await InternetConnectionChecker().hasConnection;
      _updateStatus(
        hasInternet ? AppConnectionStatus.online : AppConnectionStatus.offline,
      );
    });
  }

  void _updateStatus(AppConnectionStatus newStatus) {
    if (newStatus == _currentStatus) return;
    _currentStatus = newStatus;
    _controller.add(newStatus);
  }

  void dispose() {
    _controller.close();
  }
}
