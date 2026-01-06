import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/colors.dart';

class SocialButtonWidget extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const SocialButtonWidget({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50.w,
        height: 50.h,
        decoration: BoxDecoration(
          color: Color(ConstColors.mainColor),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(ConstColors.mainColor).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24.sp),
      ),
    );
  }
}
