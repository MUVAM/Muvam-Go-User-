import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/app_colors.dart';

class ProfileImagePicker extends StatelessWidget {
  final File? profileImage;
  final VoidCallback onTap;

  const ProfileImagePicker({
    super.key,
    required this.profileImage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
            ),
            child: profileImage != null
                ? ClipOval(child: Image.file(profileImage!, fit: BoxFit.cover))
                : Icon(Icons.camera_alt, size: 30.sp),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 24.w,
              height: 24.h,
              decoration: BoxDecoration(
                color: AppColors.kMainColor.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.edit,
                color: AppColors.kWhiteColor,
                size: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
