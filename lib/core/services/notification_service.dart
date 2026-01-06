import 'package:flutter/material.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/features/chat/presentation/widgets/in_app_notification.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  OverlayEntry? _currentNotification;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  void showMessageNotification({
    required String title,
    required String message,
    required VoidCallback onTap,
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    try {
      final overlay = Overlay.of(context, rootOverlay: true);
      if (overlay == null) return;

      _removeCurrentNotification();

      _currentNotification = OverlayEntry(
        builder: (context) => InAppNotification(
          title: title,
          message: message,
          onTap: () {
            _removeCurrentNotification();
            onTap();
          },
          onDismiss: _removeCurrentNotification,
        ),
      );

      overlay.insert(_currentNotification!);
    } catch (e) {
      AppLogger.log('Failed to show notification: $e');
    }
  }

  void _removeCurrentNotification() {
    _currentNotification?.remove();
    _currentNotification = null;
  }
}
