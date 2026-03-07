import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/muvam_text.dart';

class ErrorCard extends StatelessWidget {
  final VoidCallback onRetry;

  const ErrorCard({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350.w,
      height: 157.h,
      decoration: BoxDecoration(
        color: AppColors.kBlackColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MuvamTexts.bodyMedium14(
              context,
              text: 'Failed to load referral code',
              isTextWidget: true,
              color: AppColors.kWhiteColor,
              fontWeight: FontWeight.w500,
              center: true,
            ),
            SizedBox(height: 10.h),
            GestureDetector(
              onTap: onRetry,
              child: MuvamTexts.bodyMedium14(
                context,
                text: 'Tap to retry',
                isTextWidget: true,
                color: AppColors.kWhiteColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
