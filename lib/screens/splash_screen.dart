import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:muvam/features/wallet/data/providers/wallet_provider.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end: const Offset(-1.5, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward().then((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      // Check token validity first
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isTokenValid = await authProvider.checkTokenValidity();

      // If token is valid, initialize wallet
      if (isTokenValid) {
        try {
          await context.read<WalletProvider>().checkVirtualAccount();
          AppLogger.log('Virtual account check completed');
        } catch (e) {
          AppLogger.log('Failed to check virtual account: $e');
          // Continue even if wallet check fails
        }
      }

      // Navigate based on token validity
      if (mounted) {
        if (isTokenValid) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        }
      }
    } catch (e) {
      AppLogger.log('Initialization error: $e');
      // On error, navigate to onboarding
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SlideTransition(
          position: _slideAnimation,
          child: Image.asset(
            ConstImages.onboardCar1,
            width: 411.w,
            height: 411.h,
          ),
        ),
      ),
    );
  }
}
