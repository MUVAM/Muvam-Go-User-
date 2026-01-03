import 'package:flutter/material.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/shared/providers/connectivity_provider.dart';
import 'package:provider/provider.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  bool? _previousConnectionStatus;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize on first build
    if (!_isInitialized) {
      _isInitialized = true;
      final connectivityProvider = Provider.of<ConnectivityProvider>(
        context,
        listen: false,
      );
      _previousConnectionStatus = connectivityProvider.isConnected;

      AppLogger.log(
        'ConnectivityWrapper initialized. Initial status: ${connectivityProvider.isConnected}',
        tag: 'CONNECTIVITY_WRAPPER',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivityProvider, child) {
        final currentStatus = connectivityProvider.isConnected;

        // Schedule notification check after build completes
        if (_previousConnectionStatus != null &&
            _previousConnectionStatus != currentStatus) {
          AppLogger.log(
            'Status CHANGED! Previous: $_previousConnectionStatus, Current: $currentStatus',
            tag: 'CONNECTIVITY_WRAPPER',
          );

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              AppLogger.log(
                'Showing notification for: ${currentStatus ? "Connected" : "Disconnected"}',
                tag: 'CONNECTIVITY_WRAPPER',
              );
              _showConnectivityNotification(currentStatus);
              _previousConnectionStatus = currentStatus;
            }
          });
        } else {
          _previousConnectionStatus ??= currentStatus;
        }

        return widget.child;
      },
    );
  }

  void _showConnectivityNotification(bool isConnected) {
    try {
      AppLogger.log(
        'Attempting to show flushbar. Connected: $isConnected, Context valid: $context',
        tag: 'CONNECTIVITY_WRAPPER',
      );

      if (isConnected) {
        CustomFlushbar.showConnected(context: context);
        AppLogger.log('Connected flushbar called', tag: 'CONNECTIVITY_WRAPPER');
      } else {
        CustomFlushbar.showDisconnected(context: context);
        AppLogger.log(
          'Disconnected flushbar called',
          tag: 'CONNECTIVITY_WRAPPER',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Error showing connectivity notification',
        error: e,
        tag: 'CONNECTIVITY_WRAPPER',
      );
    }
  }
}
