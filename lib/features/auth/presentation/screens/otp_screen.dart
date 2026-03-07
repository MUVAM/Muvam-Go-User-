import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/app_routes.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/auth/data/providers/auth_provider.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';
import 'package:muvam/layouts/presentation/shared/bottom_padding.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

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
    _startTimer();
    pinController.addListener(() => setState(() {}));
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
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

  bool get isOtpComplete => pinController.text.length == 6;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      resizeToAvoidBottomInset: true,
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
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        children: [
                          SizedBox(height: 60.h),
                          Image.asset(
                            ConstImages.otp,
                            width: 426.w,
                            height: 426.h,
                          ),
                          MuvamTexts.titleLarge22(
                            context,
                            text: 'Phone Verification',
                            isTextWidget: true,
                          ),
                          SizedBox(height: 5.h),
                          MuvamTexts.bodyMedium14(
                            context,
                            text: 'Enter the 6 digit code sent to you',
                            center: true,
                            fontSize: 14,
                            isTextWidget: true,
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
                                color: AppColors.kBlackColor,
                              ),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppColors.kBlackColor,
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
                                color: AppColors.kBlackColor,
                              ),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppColors.kMainColor,
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
                                color: AppColors.kBlackColor,
                              ),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: AppColors.kMainColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            hapticFeedbackType: HapticFeedbackType.lightImpact,
                            cursor: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  margin: EdgeInsets.only(bottom: 9.h),
                                  width: 22.w,
                                  height: 1,
                                  color: AppColors.kMainColor,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 30.h),
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              return GestureDetector(
                                onTap:
                                    _countdown == 0 && !authProvider.isLoading
                                    ? () async {
                                        final success = await authProvider
                                            .resendOtp(widget.phoneNumber);
                                        if (success) {
                                          setState(() => _countdown = 20);
                                          _startTimer();
                                        }
                                      }
                                    : null,
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "Didn't receive code? ",
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          color: AppColors.kBlackColor,
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                      if (_countdown > 0)
                                        TextSpan(
                                          text:
                                              '0:${_countdown.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            color: AppColors.kMainColor,
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        )
                                      else
                                        TextSpan(
                                          text: 'Resend',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            color: AppColors.kMainColor,
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 20.h),
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Text(
                              'Edit my number',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: AppColors.kBlackColor,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          SizedBox(height: 40.h),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      final isEnabled =
                          isOtpComplete && !authProvider.isLoading;
                      return GestureDetector(
                        onTap: isEnabled
                            ? () async {
                                final success = await authProvider.verifyOtp(
                                  pinController.text,
                                  widget.phoneNumber,
                                );
                                if (!mounted) return;

                                if (success) {
                                  final response =
                                      authProvider.verifyOtpResponse!;
                                  AppLogger.log('User data: ${response.user}');
                                  AppLogger.log('IsNew: ${response.isNew}');

                                  final userRole =
                                      response.user?['Role'] as String?;
                                  if (userRole != null &&
                                      userRole.toLowerCase() != 'passenger') {
                                    CustomFlushbar.showOtpResent(
                                      context: context,
                                      message:
                                          'This phone number is registered on the driver app.',
                                    );
                                    return;
                                  }
                                  if (response.isNew) {
                                    context.pushNamed(
                                      AppRoutes.createAccount.name,
                                    );
                                  } else {
                                    context.goNamed(AppRoutes.home.name);
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
                          width: double.infinity,
                          height: 47.h,
                          decoration: BoxDecoration(
                            color: isEnabled
                                ? AppColors.kMainColor
                                : AppColors.kFieldColor,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Center(
                            child: authProvider.isLoading
                                ? SizedBox(
                                    width: 20.w,
                                    height: 20.h,
                                    child: const CircularProgressIndicator(
                                      color: AppColors.kWhiteColor,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : MuvamTexts.button16(
                                    context,
                                    text: 'Continue',
                                    isTextWidget: true,
                                    color: AppColors.kWhiteColor,
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                DeviceBottomPadding(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
