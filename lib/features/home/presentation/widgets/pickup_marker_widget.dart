import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    final bool showTimer = isDriverAssigned || hasNearbyDriver;

    return Container(
      width: 247.w,
      height: 50.h,
      padding: EdgeInsets.only(right: 12.w, top: 4.h, bottom: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Timer/Location icon container
          Container(
            width: 50.w,
            height: 50.h,
            decoration: BoxDecoration(
              color: showTimer ? Color(ConstColors.mainColor) : Colors.white,
              shape: BoxShape.circle,
              border: showTimer
                  ? null
                  : Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Center(
              child: showTimer
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        MuvamTexts.bodyLarge16(
                          context,
                          text: driverArrivalTime,
                          isTextWidget: true,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        MuvamTexts.bodySmall12(
                          context,
                          text: "MIN",
                          isTextWidget: true,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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

          // Address text
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
                  color: Colors.black,
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
          Icon(
            Icons.chevron_right,
            color: Color(ConstColors.blackColor),
            size: 24.sp,
          ),
        ],
      ),
    );
  }
}
