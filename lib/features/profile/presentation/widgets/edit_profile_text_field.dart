import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/muvam_text.dart';

class EditProfileTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool readOnly;

  const EditProfileTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.readOnly = false,
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
          color: Colors.grey.shade500,
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(0),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  readOnly: readOnly,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.kBlackColor,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hintText ?? 'Enter $label',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                  ),
                ),
              ),
              MuvamTexts.bodyMedium14(
                context,
                text: 'Edit',
                isTextWidget: true,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
