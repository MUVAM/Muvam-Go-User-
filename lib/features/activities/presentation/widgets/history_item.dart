import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/features/trips/presentation/screens/history_cancelled_screen.dart';
import 'package:muvam/features/trips/presentation/screens/history_completed_screen.dart';

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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HistoryCompletedScreen(rideId: rideId),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HistoryCancelledScreen(rideId: rideId),
            ),
          );
        }
      },
      child: Container(
        width: 353.w,
        height: 120.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5.r),
          border: Border.all(
            color: Color(0xFFB1B1B1).withOpacity(0.5),
            width: 0.5,
          ),
        ),
        padding: EdgeInsets.only(
          top: 12.h,
          right: 15.w,
          bottom: 12.h,
          left: 15.w,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 12.sp,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      date,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 16.sp,
                        height: 1.0,
                        letterSpacing: -0.41,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                isCompleted
                    ? Text(
                        price ?? '',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                          color: Colors.black,
                        ),
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
                              fontFamily: 'Inter',
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
                Text(
                  'Destination',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 12.sp,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  destination,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                    color: Colors.black,
                  ),
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
