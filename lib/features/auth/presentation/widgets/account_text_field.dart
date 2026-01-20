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
  final String? hintText;

  const AccountTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.backgroundColor,
    this.isDateField = false,
    this.hasDropdown = false,
    this.onDateSelected,
    this.hintText,
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
                  textCapitalization: TextCapitalization.words,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hintText,
                    hintStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade400,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 15.h,
                    ),
                    isDense: true,
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
