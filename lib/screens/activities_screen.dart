import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/colors.dart';
import 'trip_details_screen.dart';
import 'active_trip_screen.dart';
import 'history_cancelled_screen.dart';
import 'history_completed_screen.dart';

class ActivitiesScreen extends StatefulWidget {
  @override
  _ActivitiesScreenState createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Back button
          Positioned(
            top: 70.h,
            left: 20.w,
            child: Container(
              width: 45.w,
              height: 45.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100.r),
              ),
              padding: EdgeInsets.all(10.w),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 20.sp,
                ),
              ),
            ),
          ),
          
          // Tab bar container
          Positioned(
            top: 140.h,
            left: 20.w,
            child: Container(
              width: 353.w,
              height: 32.h,
              decoration: BoxDecoration(
                color: Color(0x767680).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8.r),
              ),
              padding: EdgeInsets.all(2.w),
              child: Row(
                children: [
                  _buildTabItem('Prebooking', 0),
                  Container(width: 0.5.w, height: 28.h, color: Colors.grey.shade300),
                  _buildTabItem('Active', 1),
                  Container(width: 0.5.w, height: 28.h, color: Colors.grey.shade300),
                  _buildTabItem('History', 2),
                ],
              ),
            ),
          ),
          
          // Tab bar view content
          Positioned(
            top: 197.h,
            left: 20.w,
            right: 20.w,
            bottom: 20.h,
            child: SingleChildScrollView(
              child: _getCurrentTabContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrebookingTab() {
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
                decoration: BoxDecoration(
                  color: Color(ConstColors.mainColor),
                ),
                child: CustomPaint(
                  painter: ArrowPainter(),
                ),
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

  Widget _buildActiveTab() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ActiveTripScreen()),
        );
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
                Container(
                  width: 8.w,
                  height: 8.h,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            SizedBox(height: 15.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      children: [
        _buildHistoryItem(
          time: '8:00pm',
          date: 'Nov 28, 2025',
          destination: 'Ikeja, Lagos',
          isCompleted: true,
          price: '₦12,000',
        ),
        SizedBox(height: 15.h),
        _buildHistoryItem(
          time: '6:30pm',
          date: 'Nov 27, 2025',
          destination: 'Abuja, FCT',
          isCompleted: false,
        ),
        SizedBox(height: 15.h),
        _buildHistoryItem(
          time: '2:15pm',
          date: 'Nov 26, 2025',
          destination: 'Port Harcourt, Rivers',
          isCompleted: true,
          price: '₦8,500',
        ),
      ],
    );
  }

  Widget _buildHistoryItem({
    required String time,
    required String date,
    required String destination,
    required bool isCompleted,
    String? price,
  }) {
    return GestureDetector(
      onTap: () {
        if (isCompleted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HistoryCompletedScreen(price: price ?? ''),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HistoryCancelledScreen()),
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
                          border: Border.all(
                            color: Colors.red,
                            width: 0.7,
                          ),
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String text, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          width: 116.33.w,
          height: 28.h,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(7.r),
            border: isSelected ? Border.all(color: Colors.grey.shade300, width: 0.5) : null,
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _getCurrentTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildPrebookingTab();
      case 1:
        return _buildActiveTab();
      case 2:
        return _buildHistoryTab();
      default:
        return _buildPrebookingTab();
    }
  }
}

class ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(ConstColors.mainColor)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.3);
    path.lineTo(size.width * 0.5, size.height * 0.7);
    path.lineTo(size.width * 0.8, size.height * 0.3);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}