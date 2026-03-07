import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/muvam_text.dart';

class TotalInvitesCard extends StatelessWidget {
  final int totalInvites;

  const TotalInvitesCard({super.key, required this.totalInvites});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 353.w,
      height: 154.h,
      decoration: BoxDecoration(
        color: AppColors.kBlackColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MuvamTexts.bodyLarge16(
            context,
            text: 'Total Invites',
            isTextWidget: true,
            color: AppColors.kWhiteColor,
            fontWeight: FontWeight.w500,
            center: true,
          ),
          SizedBox(height: 10.h),
          Text(
            '$totalInvites',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 80.sp,
              fontWeight: FontWeight.w700,
              height: 1.0,
              color: AppColors.kWhiteColor,
            ),
          ),
        ],
      ),
    );
  }
}
