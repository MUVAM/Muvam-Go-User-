import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:muvam/shared/providers/connectivity_provider.dart';

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
      // Delay so "Back online" message is briefly visible before dismissing
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
            // Banner sits at the very top, above all other content
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
        ? const Color(0xFF1C1C1E) // dark — offline
        : const Color(0xFF057642); // green — back online / reconnecting

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
            // Icon or spinner
            if (isReconnecting)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            else
              Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 11.5,
                      height: 1.2,
                    ),
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
