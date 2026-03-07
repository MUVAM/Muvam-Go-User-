import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/features/activities/data/providers/activities_tabs_provider.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';
import 'package:provider/provider.dart';

class HistoryCancelledScreen extends StatefulWidget {
  final int rideId;

  const HistoryCancelledScreen({super.key, required this.rideId});

  @override
  State<HistoryCancelledScreen> createState() => _HistoryCancelledScreenState();
}

class _HistoryCancelledScreenState extends State<HistoryCancelledScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ActivitiesTabsProvider>();
      if (provider.selectedRide?.id != widget.rideId) {
        provider.fetchRideDetails(widget.rideId);
      }
    });
  }

  String _formatTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr).toLocal();
      return DateFormat('h:mm a').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  String _formatDate(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr).toLocal();
      return DateFormat('MMMM d, yyyy').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: SafeArea(
        child: Consumer<ActivitiesTabsProvider>(
          builder: (context, provider, child) {
            final ride =
                provider.selectedRide ??
                provider.historyRides.firstWhere(
                  (r) => r.id == widget.rideId,
                  orElse: () => provider.historyRides.isNotEmpty
                      ? provider.historyRides.first
                      : null as dynamic,
                );

            return Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          provider.clearSelectedRide();
                          context.pop();
                        },
                        child: Image.asset(
                          ConstImages.back,
                          width: 33.w,
                          height: 33.h,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  MuvamTexts.titleLarge22(
                    context,
                    text: 'Booking id: ${ride.id}',
                    isTextWidget: true,
                  ),
                  SizedBox(height: 12.h),
                  MuvamTexts.titleMedium18(
                    context,
                    text: _formatTime(ride.createdAt),
                    isTextWidget: true,
                  ),
                  MuvamTexts.titleMedium18(
                    context,
                    text: _formatDate(ride.createdAt),
                    fontWeight: FontWeight.w400,
                    isTextWidget: true,
                  ),
                  SizedBox(height: 30.h),
                  Row(
                    children: [
                      Container(
                        width: 8.w,
                        height: 8.h,
                        decoration: const BoxDecoration(
                          color: AppColors.kMainColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      MuvamTexts.bodySmall12(
                        context,
                        text: 'Pick up',
                        color: const Color(0xFF9E9E9E),
                        isTextWidget: true,
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  MuvamTexts.bodyLarge16(
                    context,
                    text: ride.pickupAddress,
                    fontWeight: FontWeight.w600,
                    isTextWidget: true,
                  ),
                  SizedBox(height: 15.h),
                  Padding(
                    padding: EdgeInsets.only(left: 16.w),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          ConstImages.lineArrow,
                          width: 24.w,
                          height: 24.h,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Divider(
                            thickness: 1,
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 15.h),
                  Row(
                    children: [
                      Container(
                        width: 8.w,
                        height: 8.h,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      MuvamTexts.bodySmall12(
                        context,
                        text: 'Destination',
                        color: const Color(0xFF9E9E9E),
                        isTextWidget: true,
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  MuvamTexts.bodyLarge16(
                    context,
                    text: ride.destAddress,
                    fontWeight: FontWeight.w600,
                    isTextWidget: true,
                  ),
                  SizedBox(height: 16.h),
                  Divider(thickness: 1, color: Colors.grey.shade300),
                  SizedBox(height: 16.h),
                  MuvamTexts.titleMedium18(
                    context,
                    text: 'Payment method',
                    color: const Color(0xFF9E9E9E),
                    fontWeight: FontWeight.w500,
                    isTextWidget: true,
                  ),
                  SizedBox(height: 15.h),
                  Container(
                    width: double.infinity,
                    height: 70.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 15.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(4.sp),
                              width: 50.w,
                              decoration: BoxDecoration(
                                color: AppColors.kWhiteColor,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: SvgPicture.asset(
                                ConstImages.cashCard,
                                width: 24.w,
                                height: 24.h,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            MuvamTexts.bodyLarge16(
                              context,
                              text: ride.paymentMethod,
                              isTextWidget: true,
                            ),
                          ],
                        ),
                        MuvamTexts.titleMedium18(
                          context,
                          text: 'Cancelled',
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          isTextWidget: true,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  MuvamTexts.titleMedium18(
                    context,
                    text: 'Service type',
                    color: const Color(0xFF9E9E9E),
                    fontWeight: FontWeight.w500,
                    isTextWidget: true,
                  ),
                  MuvamTexts.titleLarge22(
                    context,
                    text: ride.serviceType,
                    isTextWidget: true,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
