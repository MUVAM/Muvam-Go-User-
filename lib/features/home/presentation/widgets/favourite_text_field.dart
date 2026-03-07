import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/muvam_text.dart';

class FavouriteTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const FavouriteTextField({
    super.key,
    required this.label,
    required this.controller,
    this.onChanged,
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
          fontWeight: FontWeight.w500,
          color: AppColors.kBlackColor,
        ),
        SizedBox(height: 8.h),
        Container(
          width: 353.w,
          height: 50.h,
          decoration: BoxDecoration(
            color: AppColors.kFormFieldColor,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: TextField(
            controller: controller,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w400,
              color: AppColors.kBlackColor,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 15.h,
              ),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
