import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/muvam_text.dart';

class PickupMarkerWidget extends StatelessWidget {
  final String driverArrivalTime;
  final bool hasNearbyDriver;
  final bool isDriverAssigned;
  final String? pickupAddress;
  final String fromText;
  final String currentLocationAddress;

  const PickupMarkerWidget({
    super.key,
    required this.driverArrivalTime,
    required this.hasNearbyDriver,
    required this.isDriverAssigned,
    this.pickupAddress,
    required this.fromText,
    required this.currentLocationAddress,
  });

  @override
  Widget build(BuildContext context) {
    String roundedArrivalTime = driverArrivalTime;
    if (isDriverAssigned || hasNearbyDriver) {
      try {
        double time = double.parse(driverArrivalTime);
        roundedArrivalTime = time.round().toString();
      } catch (e) {
        roundedArrivalTime = driverArrivalTime;
      }
    }

    return Container(
      width: 247.w,
      height: 50.h,
      padding: EdgeInsets.only(right: 12.w, top: 4.h, bottom: 4.h),
      decoration: BoxDecoration(
        color: AppColors.kWhiteColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50.w,
            height: 50.h,
            decoration: BoxDecoration(
              color: (isDriverAssigned || hasNearbyDriver)
                  ? Color(ConstColors.mainColor)
                  : AppColors.kWhiteColor,
              shape: BoxShape.circle,
              border: (isDriverAssigned || hasNearbyDriver)
                  ? null
                  : Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Center(
              child: (isDriverAssigned || hasNearbyDriver)
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        MuvamTexts.bodyMedium14(
                          context,
                          text: roundedArrivalTime,
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
                      color: Color(ConstColors.mainColor),
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
                  text: 'Pick up',
                  isTextWidget: true,
                  fontWeight: FontWeight.w400,
                  color: AppColors.kBlackColor,
                ),
                MuvamTexts.bodyMedium14(
                  context,
                  text:
                      pickupAddress ??
                      (fromText.isNotEmpty ? fromText : currentLocationAddress),
                  isTextWidget: true,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
