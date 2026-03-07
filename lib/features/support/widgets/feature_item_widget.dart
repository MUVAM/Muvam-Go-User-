import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/muvam_text.dart';

class FeatureItemWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const FeatureItemWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 47.h,
            decoration: BoxDecoration(
              color: AppColors.kMainColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: AppColors.kMainColor, size: 24.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MuvamTexts.bodyLarge16(
                  context,
                  text: title,
                  isTextWidget: true,
                  fontWeight: FontWeight.w600,
                ),
                SizedBox(height: 4.h),
                MuvamTexts.bodySmall12(
                  context,
                  text: description,
                  isTextWidget: true,
                  color: Colors.grey[600]!,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
