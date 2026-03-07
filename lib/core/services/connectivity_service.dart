import 'package:flutter/material.dart';
import 'package:muvam/layouts/providers/connectivity_provider.dart';
import 'package:provider/provider.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  void initialize(BuildContext context) {
    final provider = Provider.of<ConnectivityProvider>(context, listen: false);
    provider.initialize();
  }

  void dispose() {
    // Provider handles its own lifecycle; nothing extra needed.
  }
}
