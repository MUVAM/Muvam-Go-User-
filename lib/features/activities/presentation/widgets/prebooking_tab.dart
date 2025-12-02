import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/features/activities/presentation/screens/activities_screen.dart';
import 'package:muvam/features/trips/presentation/screens/trip_details_screen.dart';

class PrebookingTab extends StatelessWidget {
  const PrebookingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TripDetailsScreen()),
        );
      },
      child: Container(
        width: 353.w,
        height: 200.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5.r),
          border: Border.all(
            color: Color(0xFFB1B1B1).withOpacity(0.5),
            width: 0.5,
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: 15.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 15.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '8:00pm',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 12.sp,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Nov 28, 2025',
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Trip Id',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 12.sp,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '#12345',
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
              ],
            ),
            SizedBox(height: 20.h),
            Text(
              'Pick up',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                fontSize: 12.sp,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 5.h),
            Text(
              'Nsukka, Enugu',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 15.h),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 30.w,
                height: 2.h,
                decoration: BoxDecoration(color: Color(ConstColors.mainColor)),
                child: CustomPaint(painter: ArrowPainter()),
              ),
            ),
            SizedBox(height: 15.h),
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
              'Ikeja, Lagos',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
