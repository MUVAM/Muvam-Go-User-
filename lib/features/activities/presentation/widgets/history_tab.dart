import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/features/activities/data/providers/rides_provider.dart';
import 'package:muvam/features/activities/presentation/widgets/history_item.dart';
import 'package:provider/provider.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RidesProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: Color(ConstColors.mainColor),
            ),
          );
        }

        if (provider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
                SizedBox(height: 16.h),
                Text(
                  'Failed to load rides',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8.h),
                TextButton(
                  onPressed: () => provider.fetchRides(),
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        final historyRides = provider.historyRides;

        if (historyRides.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 100.h),
                SvgPicture.asset(
                  ConstImages.clockCircleIcon,
                  width: 120.w,
                  height: 120.h,
                ),
                SizedBox(height: 16.h),
                Text(
                  'Nothing here for now. Ready to take \nyour fast ride',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          children: historyRides.map((ride) {
            return Padding(
              padding: EdgeInsets.only(bottom: 15.h),
              child: HistoryItem(
                rideId: ride.id,
                time: _extractTime(ride.scheduledAt ?? ride.createdAt),
                date: _extractDate(ride.scheduledAt ?? ride.createdAt),
                destination: ride.destAddress,
                isCompleted: ride.isCompleted,
                price: ride.isCompleted
                    ? provider.formatPrice(ride.price)
                    : null,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _extractTime(String dateTime) {
    try {
      final dt = DateTime.parse(dateTime);
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'pm' : 'am';
      return '$hour:$minute$period';
    } catch (e) {
      return '8:00pm';
    }
  }

  String _extractDate(String dateTime) {
    try {
      final dt = DateTime.parse(dateTime);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (e) {
      return 'Nov 28, 2025';
    }
  }
}
