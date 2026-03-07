import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';

class CodeCard extends StatelessWidget {
  final String? code;
  final VoidCallback onCopy;

  const CodeCard({super.key, required this.code, required this.onCopy});

  void _copyToClipboard(BuildContext context, String text) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    CustomFlushbar.showSuccess(
      context: context,
      message: 'Referral code copied to clipboard',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350.w,
      height: 157.h,
      decoration: BoxDecoration(
        color: AppColors.kBlackColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MuvamTexts.bodyMedium14(
            context,
            text: 'Invitation code',
            isTextWidget: true,
            color: AppColors.kWhiteColor,
            fontWeight: FontWeight.w500,
            center: true,
          ),
          SizedBox(height: 15.h),
          Container(width: 320.w, height: 1.h, color: AppColors.kWhiteColor),
          SizedBox(height: 15.h),
          GestureDetector(
            onLongPress: () => _copyToClipboard(context, code ?? ''),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  code ?? 'N/A',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 40.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kWhiteColor,
                    height: 1.0,
                  ),
                ),
                SizedBox(width: 10.w),
                GestureDetector(
                  onTap: () => _copyToClipboard(context, code ?? ''),
                  child: Icon(
                    Icons.copy,
                    color: AppColors.kWhiteColor,
                    size: 24.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 15.h),
          MuvamTexts.bodyMedium14(
            context,
            text: 'You are one step ahead of your friends 😎',
            isTextWidget: true,
            color: AppColors.kWhiteColor,
            fontWeight: FontWeight.w500,
            center: true,
          ),
        ],
      ),
    );
  }
}
