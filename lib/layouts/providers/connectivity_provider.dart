import 'dart:async';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

enum NetworkState { connected, disconnected, reconnecting }

class ConnectivityProvider extends ChangeNotifier {
  static final ConnectivityProvider _instance =
      ConnectivityProvider._internal();
  factory ConnectivityProvider() => _instance;
  ConnectivityProvider._internal();

  // ── State ──────────────────────────────────────────────────────────────────
  NetworkState _state = NetworkState.connected;
  bool _isInitialized = false;
  bool _wasDisconnected = false;
  DateTime? _disconnectedAt;

  final List<VoidCallback> _onReconnectListeners = [];
  StreamSubscription<InternetStatus>? _subscription;

  final _connection = InternetConnection.createInstance(
    checkInterval: const Duration(seconds: 5),
    customCheckOptions: [
      InternetCheckOption(
        uri: Uri.parse('https://one.one.one.one'),
        responseStatusFn: (response) =>
            response.statusCode >= 200 && response.statusCode < 300,
      ),
      InternetCheckOption(
        uri: Uri.parse('https://www.google.com'),
        responseStatusFn: (response) =>
            response.statusCode >= 200 && response.statusCode < 300,
      ),
    ],
  );

  // ── Getters ────────────────────────────────────────────────────────────────
  NetworkState get state => _state;
  bool get isConnected => _state == NetworkState.connected;
  bool get isDisconnected => _state == NetworkState.disconnected;
  bool get isReconnecting => _state == NetworkState.reconnecting;
  bool get isInitialized => _isInitialized;

  // ── Initialize ─────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_isInitialized) return;

    final hasAccess = await _connection.hasInternetAccess;
    _state = hasAccess ? NetworkState.connected : NetworkState.disconnected;
    if (!hasAccess) _disconnectedAt = DateTime.now();
    _isInitialized = true;

    _subscription = _connection.onStatusChange.listen(_onStatusChanged);

    notifyListeners();
  }

  void _onStatusChanged(InternetStatus status) {
    if (status == InternetStatus.connected) {
      if (_wasDisconnected) {
        // Brief "reconnecting" flash, then connected
        _state = NetworkState.reconnecting;
        notifyListeners();

        Future.delayed(const Duration(milliseconds: 1200), () {
          _state = NetworkState.connected;
          _wasDisconnected = false;
          _disconnectedAt = null;
          notifyListeners();

          for (final cb in _onReconnectListeners) {
            cb();
          }
        });
      } else {
        _state = NetworkState.connected;
        notifyListeners();
      }
    } else {
      _wasDisconnected = true;
      _disconnectedAt ??= DateTime.now();
      _state = NetworkState.disconnected;
      notifyListeners();
    }
  }

  // ── Public helpers ─────────────────────────────────────────────────────────
  Future<bool> checkNow() => _connection.hasInternetAccess;

  void addReconnectListener(VoidCallback cb) {
    _onReconnectListeners.add(cb);
  }

  void removeReconnectListener(VoidCallback cb) {
    _onReconnectListeners.remove(cb);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
