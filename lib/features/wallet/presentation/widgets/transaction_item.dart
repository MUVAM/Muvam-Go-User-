import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TransactionItem extends StatelessWidget {
  final String amount;
  final String dateTime;
  final String status;
  final Color statusColor;

  const TransactionItem({
    super.key,
    required this.amount,
    required this.dateTime,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              amount,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                height: 1.0,
                letterSpacing: -0.32,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              dateTime,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                height: 1.0,
                letterSpacing: -0.32,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        Text(
          status,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: statusColor,
          ),
        ),
      ],
    );
  }
}
