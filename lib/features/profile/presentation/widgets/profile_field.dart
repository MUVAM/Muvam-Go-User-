import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/muvam_text.dart';

class ProfileField extends StatelessWidget {
  final String label;
  final String value;
  final bool hasEdit;
  final VoidCallback? onEditTap;

  const ProfileField({
    super.key,
    required this.label,
    required this.value,
    this.hasEdit = false,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MuvamTexts.bodyMedium14(
          context,
          text: label,
          isTextWidget: true,
          color: const Color(0xFFB1B1B1),
        ),
        SizedBox(height: 8.h),
        Container(
          width: 353.w,
          height: 47.h,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9F8),
            borderRadius: BorderRadius.circular(3.r),
          ),
          padding: EdgeInsets.only(
            top: 15.h,
            right: 14.w,
            bottom: 15.h,
            left: 14.w,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MuvamTexts.bodyLarge16(
                context,
                text: value,
                isTextWidget: true,
                fontWeight: FontWeight.w500,
              ),
              if (hasEdit)
                GestureDetector(
                  onTap: onEditTap,
                  child: MuvamTexts.bodyMedium14(
                    context,
                    text: 'Edit',
                    isTextWidget: true,
                    color: AppColors.kMainColor,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
