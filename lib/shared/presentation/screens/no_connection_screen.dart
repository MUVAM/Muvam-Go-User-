import 'package:flutter/material.dart';
import 'package:muvam/shared/providers/connectivity_provider.dart';
import 'package:provider/provider.dart';

class NoConnectionScreen extends StatefulWidget {
  /// Called when the user taps "Try again".
  final Future<void> Function() onRetry;

  /// Optional title override.
  final String title;

  /// Optional subtitle override.
  final String subtitle;

  const NoConnectionScreen({
    super.key,
    required this.onRetry,
    this.title = 'No internet connection',
    this.subtitle =
        "We couldn't load your data. Check your network and try again.",
  });

  @override
  State<NoConnectionScreen> createState() => _NoConnectionScreenState();
}

class _NoConnectionScreenState extends State<NoConnectionScreen> {
  bool _isRetrying = false;

  Future<void> _retry() async {
    setState(() => _isRetrying = true);
    await widget.onRetry();
    if (mounted) setState(() => _isRetrying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, provider, _) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    provider.isConnected
                        ? Icons.refresh_rounded
                        : Icons.wifi_off_rounded,
                    size: 38,
                    color: const Color(0xFF8E8E93),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  provider.isConnected ? 'Something went wrong' : widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 10),

                // Subtitle
                Text(
                  provider.isConnected
                      ? 'An error occurred loading your data.'
                      : widget.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8E8E93),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Retry button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: provider.isConnected || _isRetrying
                        ? (_isRetrying ? null : _retry)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFD1D1D6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isRetrying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            'Try again',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                if (!provider.isConnected) ...[
                  const SizedBox(height: 14),
                  // "Waiting for connection" hint
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation(Color(0xFF8E8E93)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Waiting for connection…',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
