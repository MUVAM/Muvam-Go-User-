import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/app_routes.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/features/activities/data/providers/activities_tabs_provider.dart';
import 'package:provider/provider.dart';

class ActiveTab extends StatelessWidget {
  const ActiveTab({super.key});

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
                Icon(Icons.error_outline, size: 48.sp, color: AppColors.kError),
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

        final activeRides = provider.activeRides;

        if (activeRides.isEmpty) {
          return Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 100.h),
                SvgPicture.asset(
                  ConstImages.carIcon,
                  width: 120.w,
                  height: 120.h,
                ),
                SizedBox(height: 16.h),
                MuvamTexts.bodyMedium14(
                  context,
                  text:
                      "Just chilling for now. Book a ride \nwhen you're ready",
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
          itemCount: activeRides.length,
          itemBuilder: (context, index) {
            final ride = activeRides[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 15.h),
              child: GestureDetector(
                onTap: () {
                  context.pushNamed(
                    AppRoutes.activeTrip.name,
                    extra: {'rideId': ride.id},
                  );
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
                                text: formatTime(ride.createdAt),
                                isTextWidget: true,
                                fontWeight: FontWeight.w500,
                              ),
                              MuvamTexts.bodyLarge16(
                                context,
                                text: formatDate(ride.createdAt),
                                isTextWidget: true,
                                fontWeight: FontWeight.w600,
                              ),
                            ],
                          ),
                          Container(
                            width: 8.w,
                            height: 8.h,
                            decoration: const BoxDecoration(
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
                          Expanded(
                            child: Column(
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
                                  text: ride.destAddress,
                                  isTextWidget: true,
                                  fontWeight: FontWeight.w600,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              MuvamTexts.bodySmall12(
                                context,
                                text: 'Trip Id',
                                isTextWidget: true,
                                fontWeight: FontWeight.w500,
                              ),
                              MuvamTexts.bodyLarge16(
                                context,
                                text: '#${ride.id}',
                                isTextWidget: true,
                                fontWeight: FontWeight.w600,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
