import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/muvam_text.dart';

class QuickPickupButton extends StatelessWidget {
  final bool hasNearbyDriver;
  final String driverArrivalTime;
  final String fromText;
  final String currentLocationAddress;
  final VoidCallback onTap;

  const QuickPickupButton({
    super.key,
    required this.hasNearbyDriver,
    required this.driverArrivalTime,
    required this.fromText,
    required this.currentLocationAddress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 247.w,
        height: 50.h,
        padding: EdgeInsets.only(right: 12.w, top: 4.h, bottom: 4.h),
        decoration: BoxDecoration(
          color: AppColors.kWhiteColor,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50.w,
              height: 50.h,
              decoration: BoxDecoration(
                color: hasNearbyDriver
                    ? AppColors.kMainColor
                    : AppColors.kMainColor,
                shape: BoxShape.circle,
                border: hasNearbyDriver
                    ? null
                    : Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: Center(
                child: hasNearbyDriver
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MuvamTexts.bodyMedium14(
                            context,
                            text: driverArrivalTime,
                            isTextWidget: true,
                            fontWeight: FontWeight.w600,
                            color: AppColors.kWhiteColor,
                          ),
                          MuvamTexts.bodySmall12(
                            context,
                            text: "MIN",
                            isTextWidget: true,
                            fontWeight: FontWeight.w600,
                            color: AppColors.kWhiteColor,
                          ),
                        ],
                      )
                    : Icon(
                        Icons.location_on,
                        color: Color(ConstColors.whiteColor),
                        size: 24.sp,
                      ),
              ),
            ),
            SizedBox(width: 6.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MuvamTexts.bodySmall12(
                    context,
                    text: 'Pick Up',
                    isTextWidget: true,
                    fontWeight: FontWeight.w400,
                    color: AppColors.kBlackColor,
                  ),
                  MuvamTexts.bodyMedium14(
                    context,
                    text: fromText.isNotEmpty
                        ? fromText
                        : currentLocationAddress,
                    isTextWidget: true,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kBlackColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Color(ConstColors.blackColor),
              size: 24.sp,
            ),
          ],
        ),
      ),
    );
  }
}
