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
  late AnimationController _circlePositionController;
  late AnimationController _circleExpandController;
  late AnimationController _textColorController;
  late Animation<Offset> _carSlideAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<Offset> _circlePositionAnimation;
  late Animation<double> _circleScaleAnimation;
  late Animation<Color?> _textColorAnimation;

  @override
  void initState() {
    super.initState();

    // Car animation controller
    _carController = AnimationController(
      duration: const Duration(seconds: 4),
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

    // Circle position animation controller (moves from bottom to center)
    _circlePositionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _circlePositionAnimation = Tween<Offset>(
      begin: const Offset(0, 1.5), // Start from bottom
      end: Offset.zero, // Move to center
    ).animate(CurvedAnimation(
      parent: _circlePositionController,
      curve: Curves.easeInOut,
    ));

    // Circle expand animation controller (expands to fill screen)
    _circleExpandController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _circleScaleAnimation = Tween<double>(
      begin: 0.1, // Start small
      end: 10.0, // Expand to fill screen
    ).animate(CurvedAnimation(
      parent: _circleExpandController,
      curve: Curves.easeInOut,
    ));

    // Text color animation controller (changes from green to white)
    _textColorController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _textColorAnimation = ColorTween(
      begin: Color(ConstColors.mainColor),
      end: Colors.white,
    ).animate(CurvedAnimation(
      parent: _textColorController,
      curve: Curves.easeIn,
    ));

    // Start car animation, then text animation, then circle animations
    _carController.forward().then((_) {
      _textController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          // Start circle position animation
          _circlePositionController.forward().then((_) {
            // Start circle expand and text color change simultaneously
            _circleExpandController.forward();
            _textColorController.forward().then((_) {
              Future.delayed(const Duration(milliseconds: 500), () {
                _initializeApp();
              });
            });
          });
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
    _circlePositionController.dispose();
    _circleExpandController.dispose();
    _textColorController.dispose();
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
          // Green circle animation (behind text)
          Center(
            child: SlideTransition(
              position: _circlePositionAnimation,
              child: ScaleTransition(
                scale: _circleScaleAnimation,
                child: Container(
                  width: 100.w,
                  height: 100.h,
                  decoration: BoxDecoration(
                    color: Color(ConstColors.mainColor),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          // Text animation with color change
          Center(
            child: FadeTransition(
              opacity: _textOpacityAnimation,
              child: SlideTransition(
                position: _textSlideAnimation,
                child: AnimatedBuilder(
                  animation: _textColorAnimation,
                  builder: (context, child) {
                    return Text(
                      'MUVAM',
                      style: TextStyle(
                        color: _textColorAnimation.value ?? Color(ConstColors.mainColor),
                        fontSize: 36.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
