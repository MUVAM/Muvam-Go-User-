import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/services/biometric_auth_service.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';

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
  String _biometricType = 'Biometric';

  @override
  void initState() {
    super.initState();
    _loadBiometricType();
    // Auto-trigger authentication when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _loadBiometricType() async {
    final type = await _biometricService.getBiometricTypeName();
    if (mounted) {
      setState(() {
        _biometricType = type;
      });
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
    });

    try {
      final authenticated = await _biometricService.authenticate(
        reason: widget.isLoginScreen
            ? 'Authenticate to login to MuvamGo'
            : 'Authenticate to unlock MuvamGo',
        biometricOnly: false,
      );

      if (authenticated) {
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
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo or Icon
                Container(
                  width: 120.w,
                  height: 120.h,
                  decoration: BoxDecoration(
                    color: Color(ConstColors.mainColor).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 60.sp,
                    color: Color(ConstColors.mainColor),
                  ),
                ),
                SizedBox(height: 40.h),
                Text(
                  'MuvamGo is Locked',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Use $_biometricType to unlock',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 60.h),
                // Biometric Icon
                GestureDetector(
                  onTap: _isAuthenticating ? null : _authenticate,
                  child: Container(
                    width: 80.w,
                    height: 80.h,
                    decoration: BoxDecoration(
                      color: Color(ConstColors.mainColor),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(ConstColors.mainColor).withOpacity(0.3),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: _isAuthenticating
                        ? Padding(
                            padding: EdgeInsets.all(20.w),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : Icon(
                            _biometricType == 'Face ID'
                                ? Icons.face
                                : Icons.fingerprint,
                            size: 40.sp,
                            color: Colors.white,
                          ),
                  ),
                ),
                SizedBox(height: 20.h),
                if (!_isAuthenticating)
                  TextButton(
                    onPressed: _authenticate,
                    child: Text(
                      'Tap to Authenticate',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Color(ConstColors.mainColor),
                      ),
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
