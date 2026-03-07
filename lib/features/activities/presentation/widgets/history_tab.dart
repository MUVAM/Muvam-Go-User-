import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/features/activities/data/providers/activities_tabs_provider.dart';
import 'package:muvam/features/activities/presentation/widgets/history_item.dart';
import 'package:provider/provider.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    String formatTime(String dateTimeStr) {
      try {
        return DateFormat(
          'h:mm a',
        ).format(DateTime.parse(dateTimeStr).toLocal());
      } catch (e) {
        return '';
      }
    }

    String formatDate(String dateTimeStr) {
      try {
        return DateFormat(
          'MMMM d, yyyy',
        ).format(DateTime.parse(dateTimeStr).toLocal());
      } catch (e) {
        return '';
      }
    }

    return Consumer<ActivitiesTabsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && !provider.hasData) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.kMainColor),
          );
        }

        if (provider.errorMessage != null && !provider.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
                SizedBox(height: 16.h),
                MuvamTexts.bodyMedium14(
                  context,
                  text: provider.errorMessage ?? 'Failed to load rides',
                  isTextWidget: true,
                  fontWeight: FontWeight.w500,
                  center: true,
                ),
                SizedBox(height: 8.h),
                TextButton(
                  onPressed: () => provider.fetchRides(),
                  child: const Text('Retry'),
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
                MuvamTexts.bodyMedium14(
                  context,
                  text: 'Nothing here for now. Ready to take \nyour fast ride',
                  isTextWidget: true,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                  center: true,
                ),
                if (provider.isRefreshing) ...[
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.kMainColor,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          physics: const PageScrollPhysics(),
          shrinkWrap: true,
          itemCount: historyRides.length,
          itemBuilder: (context, index) {
            final ride = historyRides[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 15.h),
              child: HistoryItem(
                rideId: ride.id,
                time: formatTime(ride.createdAt),
                date: formatDate(ride.createdAt),
                destination: ride.destAddress,
                isCompleted: ride.isCompleted,
                price: ride.isCompleted
                    ? provider.formatPrice(ride.price)
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}
