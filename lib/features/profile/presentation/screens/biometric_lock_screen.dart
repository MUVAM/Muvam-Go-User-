import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/core/services/biometric_auth_service.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/profile/presentation/widgets/face_unlock_ui.dart';
import 'package:muvam/features/profile/presentation/widgets/fingerprint_ui.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';

class BiometricLockScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;
  final bool isLoginScreen;

  const BiometricLockScreen({
    super.key,
    required this.onAuthenticated,
    this.isLoginScreen = false,
  });

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  final BiometricAuthService _biometricService = BiometricAuthService();
  bool _isAuthenticating = false;
  bool _authenticationSuccessful = false;
  String _biometricType = 'Biometric';

  @override
  void initState() {
    super.initState();
    _loadBiometricType();
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _loadBiometricType() async {
    final type = await _biometricService.getBiometricTypeName();
    if (mounted) setState(() => _biometricType = type);
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _authenticationSuccessful = false;
    });

    try {
      final authenticated = await _biometricService.authenticate(
        reason: widget.isLoginScreen
            ? 'Authenticate to login to MuvamGo'
            : 'Authenticate to unlock MuvamGo',
        biometricOnly: false,
      );

      if (authenticated) {
        setState(() => _authenticationSuccessful = true);
        await Future.delayed(const Duration(milliseconds: 500));
        _biometricService.clearBackgroundTime();
        widget.onAuthenticated();
      } else {
        if (mounted) {
          CustomFlushbar.showError(
            context: context,
            message: 'Authentication failed. Please try again.',
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  bool get _isFaceUnlock =>
      _biometricType == 'Face ID' ||
      _biometricType.toLowerCase().contains('face');

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MuvamTexts.headlineSmall24(
                  context,
                  text: 'MuvamGo is Locked',
                  isTextWidget: true,
                  fontWeight: FontWeight.w700,
                ),
                SizedBox(height: 40.h),
                MuvamTexts.titleLarge22(
                  context,
                  text: _isFaceUnlock ? 'Place your head' : 'Place your finger',
                  isTextWidget: true,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: 12.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: MuvamTexts.bodyMedium14(
                    context,
                    text: _isFaceUnlock
                        ? 'In the middle of the circle to add your face.'
                        : 'On the sensor and lift after you feel a vibration',
                    isTextWidget: true,
                    color: Colors.grey.shade600,
                    center: true,
                  ),
                ),
                SizedBox(height: 60.h),
                GestureDetector(
                  onTap: _isAuthenticating ? null : _authenticate,
                  child: _isFaceUnlock
                      ? FaceUnlockUI(
                          isAuthenticating: _isAuthenticating,
                          authenticationSuccessful: _authenticationSuccessful,
                        )
                      : FingerprintUI(
                          isAuthenticating: _isAuthenticating,
                          authenticationSuccessful: _authenticationSuccessful,
                        ),
                ),
                SizedBox(height: 40.h),
                if (!_isAuthenticating && !_authenticationSuccessful)
                  ElevatedButton(
                    onPressed: _authenticate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kMainColor,
                      foregroundColor: AppColors.kWhiteColor,
                      padding: EdgeInsets.symmetric(
                        horizontal: 40.w,
                        vertical: 14.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: MuvamTexts.bodyMedium14(
                      context,
                      text: 'Tap to Authenticate',
                      isTextWidget: true,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kWhiteColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
