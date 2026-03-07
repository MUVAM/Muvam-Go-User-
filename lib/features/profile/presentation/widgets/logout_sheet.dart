import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/muvam_text.dart';

class LogoutSheet extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback onGoBack;

  const LogoutSheet({
    super.key,
    required this.onLogout,
    required this.onGoBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.kWhiteColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 69.w,
            height: 5.h,
            margin: EdgeInsets.only(bottom: 20.h),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2.5.r),
            ),
          ),
          MuvamTexts.titleMedium18(
            context,
            text: 'Log Out',
            isTextWidget: true,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: 16.h),
          MuvamTexts.bodyMedium14(
            context,
            text: 'Are you sure you want to log out of your account?',
            isTextWidget: true,
            center: true,
          ),
          SizedBox(height: 25.h),
          Row(
            children: [
              GestureDetector(
                onTap: onLogout,
                child: Container(
                  width: 170.w,
                  height: 47.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB1B1B1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Center(
                    child: MuvamTexts.button16(
                      context,
                      text: 'Log out',
                      isTextWidget: true,
                      color: AppColors.kWhiteColor,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              GestureDetector(
                onTap: onGoBack,
                child: Container(
                  width: 170.w,
                  height: 47.h,
                  decoration: BoxDecoration(
                    color: AppColors.kMainColor,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Center(
                    child: MuvamTexts.button16(
                      context,
                      text: 'Go Back',
                      isTextWidget: true,
                      color: AppColors.kWhiteColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
