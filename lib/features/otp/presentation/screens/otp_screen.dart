import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/text_styles.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/auth/data/providers/auth_provider.dart';
import 'package:muvam/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:provider/provider.dart';
import 'package:muvam/features/auth/presentation/screens/create_account_screen.dart';
import 'package:pinput/pinput.dart';
import 'dart:async';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController pinController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  Timer? _timer;
  int _countdown = 20;

  @override
  void initState() {
    super.initState();
    startTimer();
    pinController.addListener(() {
      setState(() {});
    });
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    pinController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  bool get isOtpComplete {
    return pinController.text.length == 6;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                ConstImages.onboardBackground,
                height: 353.h,
                width: 393.w,
                fit: BoxFit.cover,
              ),
            ),
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    SizedBox(height: 60.h),
                    Image.asset(ConstImages.otp, width: 426.w, height: 426.h),
                    Text(
                      'Phone Verification',
                      style: ConstTextStyles.boldTitle,
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      'Enter the 6 digit code sent to you',
                      style: ConstTextStyles.lightSubtitle,
                    ),
                    SizedBox(height: 42.h),
                    Pinput(
                      controller: pinController,
                      focusNode: focusNode,
                      length: 6,
                      defaultPinTheme: PinTheme(
                        width: 45.w,
                        height: 50.h,
                        textStyle: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      focusedPinTheme: PinTheme(
                        width: 45.w,
                        height: 50.h,
                        textStyle: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(ConstColors.mainColor),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      submittedPinTheme: PinTheme(
                        width: 45.w,
                        height: 50.h,
                        textStyle: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(ConstColors.mainColor),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      hapticFeedbackType: HapticFeedbackType.lightImpact,
                      onCompleted: (pin) {
                        // Auto-submit when OTP is complete (optional)
                      },
                      cursor: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            margin: EdgeInsets.only(bottom: 9.h),
                            width: 22.w,
                            height: 1,
                            color: Color(ConstColors.mainColor),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30.h),
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return GestureDetector(
                          onTap: _countdown == 0 && !authProvider.isLoading
                              ? () async {
                                  final success = await authProvider.resendOtp(
                                    widget.phoneNumber,
                                  );
                                  if (success) {
                                    setState(() {
                                      _countdown = 20;
                                    });
                                    startTimer();
                                  }
                                }
                              : null,
                          child: Text(
                            _countdown > 0
                                ? 'Didn\'t receive code? Resend code in: 0:${_countdown.toString().padLeft(2, '0')}'
                                : 'Resend code',
                            style: _countdown == 0
                                ? TextStyle(
                                    color: Color(ConstColors.mainColor),
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                  )
                                : ConstTextStyles.lightSubtitle,
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 20.h),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Edit my number',
                        style: TextStyle(
                          color: Color(ConstColors.mainColor),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 40.h),
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return GestureDetector(
                          onTap: isOtpComplete && !authProvider.isLoading
                              ? () async {
                                  final otpCode = pinController.text;
                                  final success = await authProvider.verifyOtp(
                                    otpCode,
                                    widget.phoneNumber,
                                  );

                                  if (success) {
                                    final response =
                                        authProvider.verifyOtpResponse!;
                                    AppLogger.log(
                                      'User data: ${response.user}',
                                    );
                                    AppLogger.log('Token: ${response.token}');
                                    AppLogger.log('IsNew: ${response.isNew}');

                                    final userRole =
                                        response.user?['Role'] as String?;
                                    if (userRole != null &&
                                        userRole.toLowerCase() != 'passenger') {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text('Account Mismatch'),
                                          content: Text(
                                            'This phone number is registered on the driver app. Please use another number to log in to the passenger app.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: Text(
                                                'OK',
                                                style: TextStyle(
                                                  color: Color(
                                                    ConstColors.mainColor,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      return;
                                    }

                                    if (response.isNew) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const CreateAccountScreen(),
                                        ),
                                      );
                                    } else {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const MainNavigationScreen(),
                                        ),
                                      );
                                    }
                                  } else {
                                    CustomFlushbar.showOtpResent(
                                      context: context,
                                      message:
                                          authProvider.errorMessage ??
                                          'Invalid OTP',
                                    );
                                  }
                                }
                              : null,
                          child: Container(
                            width: 353.w,
                            height: 48.h,
                            decoration: BoxDecoration(
                              color: isOtpComplete && !authProvider.isLoading
                                  ? Color(ConstColors.mainColor)
                                  : Color(ConstColors.fieldColor),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Center(
                              child: authProvider.isLoading
                                  ? SizedBox(
                                      width: 20.w,
                                      height: 20.h,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Continue',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
