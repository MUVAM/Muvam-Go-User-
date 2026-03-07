import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/muvam_text.dart';

class EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool readOnly;

  const EditField({
    super.key,
    required this.label,
    required this.controller,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final isReadOnly = readOnly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MuvamTexts.bodyMedium14(
          context,
          text: label,
          isTextWidget: true,
          fontWeight: FontWeight.w500,
          color: isReadOnly ? Colors.grey.shade600 : null,
        ),
        SizedBox(height: 5.h),
        TextField(
          controller: controller,
          enabled: !isReadOnly,
          style: TextStyle(
            fontSize: 14.sp,
            color: isReadOnly ? Colors.grey.shade600 : AppColors.kBlackColor,
          ),
          decoration: InputDecoration(
            filled: isReadOnly,
            fillColor: isReadOnly ? Colors.grey.shade100 : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: AppColors.kMainColor),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 10.h,
            ),
          ),
        ),
      ],
    );
  }
}
