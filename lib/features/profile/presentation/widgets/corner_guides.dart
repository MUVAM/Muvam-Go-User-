import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/app_colors.dart';

class CornerGuides extends StatelessWidget {
  final bool isAuthenticating;
  final bool authenticationSuccessful;

  const CornerGuides({
    super.key,
    required this.isAuthenticating,
    required this.authenticationSuccessful,
  });

  @override
  Widget build(BuildContext context) {
    final guideColor = authenticationSuccessful
        ? Colors.green
        : isAuthenticating
        ? AppColors.kMainColor
        : Colors.grey.shade400;

    return Stack(
      children: [
        Positioned(
          top: 10.h,
          left: 25.w,
          child: Container(
            width: 30.w,
            height: 30.h,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: guideColor, width: 3.w),
                left: BorderSide(color: guideColor, width: 3.w),
              ),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(15.r)),
            ),
          ),
        ),
        Positioned(
          top: 10.h,
          right: 25.w,
          child: Container(
            width: 30.w,
            height: 30.h,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: guideColor, width: 3.w),
                right: BorderSide(color: guideColor, width: 3.w),
              ),
              borderRadius: BorderRadius.only(topRight: Radius.circular(15.r)),
            ),
          ),
        ),
        Positioned(
          bottom: 10.h,
          left: 25.w,
          child: Container(
            width: 30.w,
            height: 30.h,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: guideColor, width: 3.w),
                left: BorderSide(color: guideColor, width: 3.w),
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(15.r),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 10.h,
          right: 25.w,
          child: Container(
            width: 30.w,
            height: 30.h,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: guideColor, width: 3.w),
                right: BorderSide(color: guideColor, width: 3.w),
              ),
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(15.r),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
