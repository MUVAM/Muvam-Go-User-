import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'history_item.dart';

class HistoryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HistoryItem(
          time: '8:00pm',
          date: 'Nov 28, 2025',
          destination: 'Ikeja, Lagos',
          isCompleted: true,
          price: '₦12,000',
        ),
        SizedBox(height: 15.h),
        HistoryItem(
          time: '6:30pm',
          date: 'Nov 27, 2025',
          destination: 'Abuja, FCT',
          isCompleted: false,
        ),
        SizedBox(height: 15.h),
        HistoryItem(
          time: '2:15pm',
          date: 'Nov 26, 2025',
          destination: 'Port Harcourt, Rivers',
          isCompleted: true,
          price: '₦8,500',
        ),
      ],
    );
  }
}
