import 'package:flutter/material.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/layouts/providers/connectivity_provider.dart';
import 'package:provider/provider.dart';

class NetworkBanner extends StatefulWidget {
  final Widget child;

  const NetworkBanner({super.key, required this.child});

  @override
  State<NetworkBanner> createState() => _NetworkBannerState();
}

class _NetworkBannerState extends State<NetworkBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sync(NetworkState state) {
    if (state == NetworkState.disconnected ||
        state == NetworkState.reconnecting) {
      _controller.forward();
    } else {
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) _controller.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, provider, child) {
        _sync(provider.state);

        return Stack(
          children: [
            widget.child,
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: _BannerContent(state: provider.state),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BannerContent extends StatelessWidget {
  final NetworkState state;

  const _BannerContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isOffline = state == NetworkState.disconnected;
    final isReconnecting = state == NetworkState.reconnecting;

    final bgColor = isOffline
        ? const Color(0xFF1C1C1E)
        : AppColors.kSuccessColor;

    final icon = isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded;

    final message = isOffline
        ? 'No internet connection'
        : isReconnecting
        ? 'Reconnecting…'
        : 'Back online';

    final sub = isOffline
        ? 'Check your network settings'
        : isReconnecting
        ? 'Please wait a moment'
        : 'Your connection was restored';

    return Material(
      color: Colors.transparent,
      child: Container(
        color: bgColor,
        padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 12),
        child: Row(
          children: [
            if (isReconnecting)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.kWhiteColor,
                  ),
                ),
              )
            else
              Icon(icon, color: AppColors.kWhiteColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  MuvamTexts.bodyMedium14(
                    context,
                    text: message,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kWhiteColor,
                  ),
                  const SizedBox(height: 2),
                  MuvamTexts.bodySmall12(
                    context,
                    text: sub,
                    color: AppColors.kWhiteColor.withOpacity(0.75),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
