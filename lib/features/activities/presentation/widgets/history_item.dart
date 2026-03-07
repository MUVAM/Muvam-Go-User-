import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/app_routes.dart';
import 'package:muvam/core/constants/muvam_text.dart';

class HistoryItem extends StatelessWidget {
  final int rideId;
  final String time;
  final String date;
  final String destination;
  final bool isCompleted;
  final String? price;

  const HistoryItem({
    super.key,
    required this.rideId,
    required this.time,
    required this.date,
    required this.destination,
    required this.isCompleted,
    this.price,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isCompleted) {
          context.pushNamed(
            AppRoutes.historyCompleted.name,
            extra: {'rideId': rideId},
          );
        } else {
          context.pushNamed(
            AppRoutes.historyCancelled.name,
            extra: {'rideId': rideId},
          );
        }
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.kWhiteColor,
          borderRadius: BorderRadius.circular(5.r),
          border: Border.all(
            color: const Color(0xFFB1B1B1).withOpacity(0.5),
            width: 0.5,
          ),
        ),
        padding: EdgeInsets.all(15.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MuvamTexts.bodySmall12(
                      context,
                      text: time,
                      isTextWidget: true,
                      fontWeight: FontWeight.w500,
                    ),
                    MuvamTexts.bodyLarge16(
                      context,
                      text: date,
                      isTextWidget: true,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
                isCompleted
                    ? MuvamTexts.bodySmall12(
                        context,
                        text: price ?? '',
                        isTextWidget: true,
                        fontWeight: FontWeight.w600,
                      )
                    : Container(
                        width: 58.w,
                        height: 16.h,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red, width: 0.7),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                        padding: EdgeInsets.only(
                          top: 2.h,
                          right: 7.w,
                          bottom: 2.h,
                          left: 7.w,
                        ),
                        child: Center(
                          child: Text(
                            'Cancelled',
                            style: TextStyle(
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
              ],
            ),
            SizedBox(height: 15.h),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MuvamTexts.bodySmall12(
                  context,
                  text: 'Destination',
                  isTextWidget: true,
                  fontWeight: FontWeight.w500,
                ),
                SizedBox(height: 5.h),
                MuvamTexts.bodyMedium14(
                  context,
                  text: destination,
                  isTextWidget: true,
                  fontWeight: FontWeight.w600,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
