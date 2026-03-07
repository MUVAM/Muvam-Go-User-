import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/muvam_text.dart';

class EditFieldWidget extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool enabled;
  final Function(String)? onChanged;

  const EditFieldWidget({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MuvamTexts.bodySmall12(
          context,
          text: label,
          isTextWidget: true,
          fontWeight: FontWeight.w500,
        ),
        SizedBox(height: 8.h),
        Container(
          width: 353.w,
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          decoration: BoxDecoration(
            color: AppColors.kFieldColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(2.r),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w400,
              color: AppColors.kBlackColor,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 15.h),
            ),
          ),
        ),
      ],
    );
  }
}
