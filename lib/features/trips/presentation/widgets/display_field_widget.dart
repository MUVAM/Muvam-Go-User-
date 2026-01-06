import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DisplayFieldWidget extends StatelessWidget {
  final String label;
  final Widget content;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  const DisplayFieldWidget({
    super.key,
    required this.label,
    required this.content,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: 353.w,
          padding:
              padding ?? EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
          decoration: BoxDecoration(
            color: backgroundColor ?? const Color(0xFFB1B1B1).withOpacity(0.12),
            borderRadius: BorderRadius.circular(2.r),
          ),
          child: content,
        ),
      ],
    );
  }
}
