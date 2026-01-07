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
  bool _authenticationSuccessful = false;
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
        setState(() {
          _authenticationSuccessful = true;
        });

        // Wait a moment to show success state
        await Future.delayed(Duration(milliseconds: 500));

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

  bool get _isFaceUnlock =>
      _biometricType == 'Face ID' ||
      _biometricType.toLowerCase().contains('face');

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
                // Title
                Text(
                  'MuvamGo is Locked',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 40.h),

                // Biometric type heading
                Text(
                  _isFaceUnlock ? 'Place your head' : 'Place your finger',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 12.h),

                // Instruction text based on biometric type
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Text(
                    _isFaceUnlock
                        ? 'In the middle of the circle to add your face.'
                        : 'On the sensor and lift after you feel a vibration',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: 60.h),

                // Biometric Visual
                GestureDetector(
                  onTap: _isAuthenticating ? null : _authenticate,
                  child: _isFaceUnlock
                      ? _buildFaceUnlockUI()
                      : _buildFingerprintUI(),
                ),

                SizedBox(height: 40.h),

                // Action button
                if (!_isAuthenticating && !_authenticationSuccessful)
                  ElevatedButton(
                    onPressed: _authenticate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(ConstColors.mainColor),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 40.w,
                        vertical: 14.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'Tap to Authenticate',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
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

  Widget _buildFingerprintUI() {
    return Container(
      width: 200.w,
      height: 200.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Fingerprint image
          Image.asset(
            _authenticationSuccessful
                ? 'assets/images/fingerGreen.png'
                : 'assets/images/fingerGrey.png',
            width: 150.w,
            height: 150.h,
            fit: BoxFit.contain,
          ),

          // Loading indicator overlay
          if (_isAuthenticating)
            Container(
              width: 200.w,
              height: 200.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SizedBox(
                  width: 50.w,
                  height: 50.h,
                  child: CircularProgressIndicator(
                    color: Color(ConstColors.mainColor),
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFaceUnlockUI() {
    return Container(
      width: 250.w,
      height: 300.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Oval frame for face
          Container(
            width: 200.w,
            height: 260.h,
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(130.r),
              border: Border.all(
                color: _authenticationSuccessful
                    ? Colors.green
                    : _isAuthenticating
                    ? Color(ConstColors.mainColor)
                    : Colors.grey.shade400,
                width: 4.w,
              ),
            ),
          ),

          // Corner guides
          ..._buildCornerGuides(),

          // Center icon
          if (!_isAuthenticating && !_authenticationSuccessful)
            Icon(Icons.face, size: 80.sp, color: Colors.grey.shade300),

          // Success icon
          if (_authenticationSuccessful)
            Container(
              width: 80.w,
              height: 80.h,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, size: 50.sp, color: Colors.white),
            ),

          // Loading indicator
          if (_isAuthenticating)
            SizedBox(
              width: 60.w,
              height: 60.h,
              child: CircularProgressIndicator(
                color: Color(ConstColors.mainColor),
                strokeWidth: 4,
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildCornerGuides() {
    final guideColor = _authenticationSuccessful
        ? Colors.green
        : _isAuthenticating
        ? Color(ConstColors.mainColor)
        : Colors.grey.shade400;

    return [
      // Top-left corner
      Positioned(
        top: 10.h,
        left: 25.w,
        child: Container(
          width: 30.w,
          height: 30.h,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: guideColor, width: 3.w),
              left: BorderSide(color: guideColor, width: 3.w),
            ),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(15.r)),
          ),
        ),
      ),
      // Top-right corner
      Positioned(
        top: 10.h,
        right: 25.w,
        child: Container(
          width: 30.w,
          height: 30.h,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: guideColor, width: 3.w),
              right: BorderSide(color: guideColor, width: 3.w),
            ),
            borderRadius: BorderRadius.only(topRight: Radius.circular(15.r)),
          ),
        ),
      ),
      // Bottom-left corner
      Positioned(
        bottom: 10.h,
        left: 25.w,
        child: Container(
          width: 30.w,
          height: 30.h,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: guideColor, width: 3.w),
              left: BorderSide(color: guideColor, width: 3.w),
            ),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15.r)),
          ),
        ),
      ),
      // Bottom-right corner
      Positioned(
        bottom: 10.h,
        right: 25.w,
        child: Container(
          width: 30.w,
          height: 30.h,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: guideColor, width: 3.w),
              right: BorderSide(color: guideColor, width: 3.w),
            ),
            borderRadius: BorderRadius.only(bottomRight: Radius.circular(15.r)),
          ),
        ),
      ),
    ];
  }
}
