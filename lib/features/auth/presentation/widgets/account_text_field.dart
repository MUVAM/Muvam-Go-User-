import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/text_styles.dart';

class AccountTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int backgroundColor;
  final bool isDateField;
  final bool hasDropdown;
  final VoidCallback? onDateSelected;

  const AccountTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.backgroundColor,
    this.isDateField = false,
    this.hasDropdown = false,
    this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ConstTextStyles.fieldLabel),
        SizedBox(height: 8.h),
        Container(
          width: 353.w,
          height: 50.h,
          decoration: BoxDecoration(
            color: Color(backgroundColor),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  readOnly: isDateField,
                  style: ConstTextStyles.inputText,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 15.h,
                    ),
                  ),
                  onTap: isDateField ? onDateSelected : null,
                ),
              ),
              if (hasDropdown)
                Padding(
                  padding: EdgeInsets.only(right: 12.w),
                  child: Icon(Icons.arrow_drop_down, size: 20.sp),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
