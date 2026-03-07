import 'package:flutter/material.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/layouts/providers/connectivity_provider.dart';
import 'package:provider/provider.dart';

class NetworkAwareButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;

  final String offlineMessage;

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
                            color: AppColors.kWhiteColor,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: MuvamTexts.bodyMedium14(
                              context,
                              text: offlineMessage,
                              color: AppColors.kWhiteColor,
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
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 16,
                      color: AppColors.kWhiteColor,
                    ),
                    const SizedBox(width: 6),
                    child,
                  ],
                ),
        );
      },
    );
  }
}
