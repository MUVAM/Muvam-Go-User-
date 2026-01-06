import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/features/auth/data/providers/auth_provider.dart';
import 'package:muvam/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:muvam/features/home/presentation/screens/home_screen.dart';
import 'package:muvam/features/wallet/data/providers/wallet_provider.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _carController;
  late AnimationController _textController;
  late Animation<Offset> _carSlideAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _textOpacityAnimation;

  @override
  void initState() {
    super.initState();

    // Car animation controller
    _carController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _carSlideAnimation = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end: const Offset(-1.5, 0),
    ).animate(CurvedAnimation(parent: _carController, curve: Curves.easeInOut));

    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    // Start car animation, then text animation, then initialize app
    _carController.forward().then((_) {
      _textController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _initializeApp();
        });
      });
    });
  }

  Future<void> _initializeApp() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isTokenValid = await authProvider.checkTokenValidity();

      if (isTokenValid) {
        try {
          await context.read<WalletProvider>().checkVirtualAccount();
          AppLogger.log('Virtual account check completed');
        } catch (e) {
          AppLogger.log('Failed to check virtual account: $e');
        }
      }

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
    _carController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Car animation
          Center(
            child: SlideTransition(
              position: _carSlideAnimation,
              child: Image.asset(
                ConstImages.onboardCar1,
                width: 411.w,
                height: 411.h,
              ),
            ),
          ),
          // Text animation
          Center(
            child: FadeTransition(
              opacity: _textOpacityAnimation,
              child: SlideTransition(
                position: _textSlideAnimation,
                child: Text(
                  'MUVAM',
                  style: TextStyle(
                    color: Color(ConstColors.mainColor),
                    fontSize: 36.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
