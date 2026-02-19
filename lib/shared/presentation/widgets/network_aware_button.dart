import 'package:flutter/material.dart';
import 'package:muvam/shared/providers/connectivity_provider.dart';
import 'package:provider/provider.dart';

class NetworkAwareButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;

  /// Optional message shown when tapped while offline
  final String offlineMessage;

  /// Style forwarded to ElevatedButton
  final ButtonStyle? style;

  const NetworkAwareButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.offlineMessage = 'No internet connection. Please check your network.',
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, provider, _) {
        final isOnline = provider.isConnected;

        return ElevatedButton(
          style: style,
          onPressed: isOnline
              ? onPressed
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(
                            Icons.wifi_off_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              offlineMessage,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF1C1C1E),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
          child: isOnline
              ? child
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 16),
                    const SizedBox(width: 6),
                    child,
                  ],
                ),
        );
      },
    );
  }
}
