import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PickupMarkerWidget extends StatelessWidget {
  const PickupMarkerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        'Pickup',
        style: TextStyle(color: Colors.white, fontSize: 12.sp),
      ),
    );
  }
}

class DropoffMarkerWidget extends StatelessWidget {
  const DropoffMarkerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        'Dropoff',
        style: TextStyle(color: Colors.white, fontSize: 12.sp),
      ),
    );
  }
}
