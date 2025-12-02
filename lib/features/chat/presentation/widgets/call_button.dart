import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CallButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isEndCall;

  const CallButton({
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.isEndCall = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38.w,
        height: 38.h,
        decoration: BoxDecoration(
          color: isEndCall ? Colors.red : Colors.transparent,
          borderRadius: isEndCall ? BorderRadius.circular(200.r) : null,
        ),
        child: Icon(
          icon,
          size: 38.sp,
          color: isEndCall ? Colors.white : iconColor,
        ),
      ),
    );
  }
}
