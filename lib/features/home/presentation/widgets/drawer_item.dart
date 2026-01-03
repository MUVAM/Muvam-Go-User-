import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/text_styles.dart';

class DrawerItem extends StatelessWidget {
  final String title;
  final String iconPath;
  final VoidCallback? onTap;

  const DrawerItem({
    super.key,
    required this.title,
    required this.iconPath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Row(
          children: [
            Image.asset(iconPath, width: 24.w, height: 24.h),
            SizedBox(width: 20.w),
            Text(title, style: ConstTextStyles.drawerItem1),
          ],
        ),
      ),
    );
  }
}
