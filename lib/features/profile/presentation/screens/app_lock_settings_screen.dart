import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:local_auth/local_auth.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/core/utils/extension.dart';
import 'package:muvam/features/profile/presentation/widgets/app_lock_radio_option.dart';
import 'package:muvam/features/profile/presentation/widgets/settings_card.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';
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
  String _lockTiming = 'immediately';
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
      AppLogger.log(
        'Biometric support: canCheck=$_canCheckBiometrics, available=$_availableBiometrics',
      );
    } on PlatformException catch (e) {
      AppLogger.log('Error checking biometric support: $e');
    }
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBiometricEnabled = _prefs.getBool('biometric_enabled') ?? false;
      _lockTiming = _prefs.getString('lock_timing') ?? 'immediately';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await _prefs.setBool('biometric_enabled', _isBiometricEnabled);
    await _prefs.setString('lock_timing', _lockTiming);
  }

  Future<bool> _authenticate() async {
    try {
      return await auth.authenticate(
        localizedReason: 'Authenticate to enable app lock',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException catch (e) {
      AppLogger.log('Authentication error: $e');
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
      final authenticated = await _authenticate();
      if (authenticated) {
        setState(() => _isBiometricEnabled = true);
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
      setState(() => _isBiometricEnabled = false);
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
    setState(() => _lockTiming = value);
    _saveSettings();
  }

  String _getBiometricTypeText() {
    if (_availableBiometrics.contains(BiometricType.face)) return 'Face ID';
    if (_availableBiometrics.contains(BiometricType.fingerprint))
      return 'Fingerprint';
    if (_availableBiometrics.contains(BiometricType.iris)) return 'Iris';
    return 'Biometric';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppScaffold(
        backgroundColor: AppColors.kWhiteColor,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.kMainColor),
        ),
      );
    }

    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      appBar: AppBar(
        backgroundColor: AppColors.kWhiteColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: GestureDetector(
            onTap: () => context.pop(),
            child: Image.asset(ConstImages.back, width: 30.w, height: 30.h),
          ),
        ),
        title: MuvamTexts.titleMedium18(
          context,
          text: 'App Lock Settings',
          isTextWidget: true,
          fontWeight: FontWeight.w600,
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(20.w),
        children: [
          SettingsCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MuvamTexts.bodyLarge16(
                        context,
                        text: 'Unlock with ${_getBiometricTypeText()}',
                        isTextWidget: true,
                        fontWeight: FontWeight.w600,
                      ),
                      SizedBox(height: 8.h),
                      MuvamTexts.bodySmall12(
                        context,
                        text:
                            'When enabled, you will need to use ${_getBiometricTypeText().toLowerCase()}, face, or other unique identification to open Muvam.',
                        isTextWidget: true,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10.w),
                Switch(
                  value: _isBiometricEnabled,
                  onChanged: _toggleBiometric,
                  activeThumbColor: AppColors.kMainColor,
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          if (_isBiometricEnabled) ...[
            SettingsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MuvamTexts.bodyLarge16(
                    context,
                    text: 'Automatically Lock In',
                    isTextWidget: true,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(height: 16.h),
                  AppLockRadioOption(
                    title: 'Immediately when leaving the app',
                    value: 'immediately',
                    selectedValue: _lockTiming,
                    onSelected: _setLockTiming,
                  ),
                  Divider(color: Colors.grey.shade200, height: 1),
                  AppLockRadioOption(
                    title: 'After 1 minute',
                    value: '1_minute',
                    selectedValue: _lockTiming,
                    onSelected: _setLockTiming,
                  ),
                  Divider(color: Colors.grey.shade200, height: 1),
                  AppLockRadioOption(
                    title: 'After 30 minutes',
                    value: '30_minutes',
                    selectedValue: _lockTiming,
                    onSelected: _setLockTiming,
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 20.h),
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
                    child: MuvamTexts.bodySmall12(
                      context,
                      text:
                          'Biometric authentication is not available on this device',
                      isTextWidget: true,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
