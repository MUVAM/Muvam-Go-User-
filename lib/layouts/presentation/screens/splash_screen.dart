import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/app_routes.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/features/auth/data/providers/auth_provider.dart';
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

    _carController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _carSlideAnimation = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end: const Offset(-1.5, 0),
    ).animate(CurvedAnimation(parent: _carController, curve: Curves.easeInOut));

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

    _circlePositionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _circlePositionAnimation =
        Tween<Offset>(begin: const Offset(0, 5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _circlePositionController,
            curve: Curves.easeInOut,
          ),
        );

    _circleExpandController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _circleScaleAnimation = Tween<double>(begin: 0.1, end: 10.0).animate(
      CurvedAnimation(parent: _circleExpandController, curve: Curves.easeInOut),
    );

    _textColorController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _textColorAnimation =
        ColorTween(
          begin: AppColors.kMainColor,
          end: AppColors.kWhiteColor,
        ).animate(
          CurvedAnimation(parent: _textColorController, curve: Curves.easeIn),
        );

    _carController.forward().then((_) {
      _textController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _circlePositionController.forward().then((_) {
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
      AppLogger.log('Initializing app', tag: 'SPLASH');

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isTokenValid = await authProvider.checkTokenValidity();

      AppLogger.log('Token valid: $isTokenValid', tag: 'SPLASH');

      if (isTokenValid) {
        AppLogger.log('User is authenticated', tag: 'SPLASH');
        try {
          await context.read<WalletProvider>().checkVirtualAccount();
          AppLogger.log('Virtual account check completed', tag: 'SPLASH');
        } catch (e) {
          AppLogger.log('Failed to check virtual account: $e', tag: 'SPLASH');
        }
      }

      if (mounted) {
        if (isTokenValid) {
          AppLogger.log('Navigating to Main App', tag: 'SPLASH');
          context.goNamed(AppRoutes.home.name);
        } else {
          AppLogger.log(
            'No valid token, navigating to Onboarding',
            tag: 'SPLASH',
          );
          context.goNamed(AppRoutes.onboarding.name);
        }
      }
    } catch (e) {
      AppLogger.log('Initialization error: $e', tag: 'SPLASH');
      if (mounted) {
        context.goNamed(AppRoutes.onboarding.name);
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
      backgroundColor: AppColors.kWhiteColor,
      body: Stack(
        children: [
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
          Center(
            child: SlideTransition(
              position: _circlePositionAnimation,
              child: ScaleTransition(
                scale: _circleScaleAnimation,
                child: Container(
                  width: 100.w,
                  height: 100.h,
                  decoration: const BoxDecoration(
                    color: AppColors.kMainColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
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
                        color:
                            _textColorAnimation.value ?? AppColors.kMainColor,
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
