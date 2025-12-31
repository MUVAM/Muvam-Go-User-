import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:local_auth/local_auth.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockSettingsScreen extends StatefulWidget {
  const AppLockSettingsScreen({super.key});

  @override
  State<AppLockSettingsScreen> createState() => _AppLockSettingsScreenState();
}

class _AppLockSettingsScreenState extends State<AppLockSettingsScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  late SharedPreferences _prefs;
  bool _isBiometricEnabled = false;
  String _lockTiming = 'immediately'; // 'immediately', '1_minute', '30_minutes'
  bool _isLoading = true;
  bool _canCheckBiometrics = false;
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _checkBiometricSupport();
    await _loadSettings();
  }

  Future<void> _checkBiometricSupport() async {
    try {
      _canCheckBiometrics = await auth.canCheckBiometrics;
      _availableBiometrics = await auth.getAvailableBiometrics();
      print(
        'Biometric support check: canCheck=$_canCheckBiometrics, available=$_availableBiometrics',
      );
    } on PlatformException catch (e) {
      print('Error checking biometric support: $e');
    }
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBiometricEnabled = _prefs.getBool('biometric_enabled') ?? false;
      _lockTiming = _prefs.getString('lock_timing') ?? 'immediately';
      _isLoading = false;
    });
    print(
      'Loaded settings: biometric=$_isBiometricEnabled, timing=$_lockTiming',
    );
  }

  Future<void> _saveSettings() async {
    await _prefs.setBool('biometric_enabled', _isBiometricEnabled);
    await _prefs.setString('lock_timing', _lockTiming);
    print(
      'Settings saved: biometric=$_isBiometricEnabled, timing=$_lockTiming',
    );

    // Verify the save
    final savedBiometric = _prefs.getBool('biometric_enabled');
    final savedTiming = _prefs.getString('lock_timing');
    print(
      'Verified saved settings: biometric=$savedBiometric, timing=$savedTiming',
    );
  }

  Future<bool> _authenticate() async {
    try {
      bool authenticated = await auth.authenticate(
        localizedReason: 'Authenticate to enable app lock',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow PIN/Pattern as fallback
        ),
      );
      return authenticated;
    } on PlatformException catch (e) {
      print('Authentication error: $e');
      return false;
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (!_canCheckBiometrics || _availableBiometrics.isEmpty) {
      CustomFlushbar.showError(
        context: context,
        message: 'Biometric authentication is not available on this device',
      );
      return;
    }

    if (value) {
      // Enabling biometric - authenticate first
      bool authenticated = await _authenticate();
      if (authenticated) {
        setState(() {
          _isBiometricEnabled = true;
        });
        await _saveSettings();
        if (mounted) {
          CustomFlushbar.showSuccess(
            context: context,
            message: 'Biometric authentication enabled successfully',
          );
        }
      } else {
        if (mounted) {
          CustomFlushbar.showError(
            context: context,
            message: 'Authentication failed. Please try again.',
          );
        }
      }
    } else {
      // Disabling biometric
      setState(() {
        _isBiometricEnabled = false;
      });
      await _saveSettings();
      if (mounted) {
        CustomFlushbar.showSuccess(
          context: context,
          message: 'Biometric authentication disabled',
        );
      }
    }
  }

  void _setLockTiming(String value) {
    setState(() {
      _lockTiming = value;
    });
    _saveSettings();
  }

  String _getBiometricTypeText() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      return 'Iris';
    }
    return 'Biometric';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(ConstColors.mainColor)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back, color: Colors.black, size: 24.sp),
        ),
        title: Text(
          'App Lock Settings',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(20.w),
        children: [
          // Biometric Unlock Card
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unlock with ${_getBiometricTypeText()}',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'When enabled, you will need to use ${_getBiometricTypeText().toLowerCase()}, face, or other unique identification to open Muvam.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Switch(
                      value: _isBiometricEnabled,
                      onChanged: _toggleBiometric,
                      activeThumbColor: Color(ConstColors.mainColor),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // Lock Timing Options (only show if biometric is enabled)
          if (_isBiometricEnabled) ...[
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey.shade200, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Automatically Lock In',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildRadioOption(
                    'Immediately when leaving the app',
                    'immediately',
                  ),
                  Divider(color: Colors.grey.shade200, height: 1),
                  _buildRadioOption('After 1 minute', '1_minute'),
                  Divider(color: Colors.grey.shade200, height: 1),
                  _buildRadioOption('After 30 minutes', '30_minutes'),
                ],
              ),
            ),
          ],

          SizedBox(height: 20.h),

          // Info card
          if (!_canCheckBiometrics || _availableBiometrics.isEmpty)
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.orange.shade200, width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade700,
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Biometric authentication is not available on this device',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRadioOption(String title, String value) {
    final isSelected = _lockTiming == value;
    return GestureDetector(
      onTap: () => _setLockTiming(value),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        color: Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 20.w,
              height: 20.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Color(ConstColors.mainColor)
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10.w,
                        height: 10.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(ConstColors.mainColor),
                        ),
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
