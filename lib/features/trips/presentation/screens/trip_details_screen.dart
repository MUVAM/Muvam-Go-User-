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
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';
import 'package:provider/provider.dart';

class TripDetailsScreen extends StatefulWidget {
  final int rideId;

  const TripDetailsScreen({super.key, required this.rideId});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
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
      return DateFormat('h:mm a').format(DateTime.parse(dateTimeStr).toLocal());
    } catch (_) {
      return '';
    }
  }

  String _formatDate(String dateTimeStr) {
    try {
      return DateFormat(
        'MMMM d, yyyy',
      ).format(DateTime.parse(dateTimeStr).toLocal());
    } catch (_) {
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
                provider.prebookedRides.firstWhere(
                  (r) => r.id == widget.rideId,
                  orElse: () => provider.prebookedRides.isNotEmpty
                      ? provider.prebookedRides.first
                      : null as dynamic,
                );

            return Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  SizedBox(height: 20.h),
                  MuvamTexts.headlineSmall24(
                    context,
                    text: 'Trip scheduled',
                    isTextWidget: true,
                    fontWeight: FontWeight.w600,
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
                        isTextWidget: true,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  MuvamTexts.bodyLarge16(
                    context,
                    text: ride.pickupAddress,
                    isTextWidget: true,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(height: 15.h),
                  Row(
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
                        isTextWidget: true,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  MuvamTexts.bodyLarge16(
                    context,
                    text: ride.destAddress,
                    isTextWidget: true,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(height: 20.h),
                  MuvamTexts.bodySmall12(
                    context,
                    text: 'When',
                    isTextWidget: true,
                    color: const Color(0xFF9E9E9E),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      MuvamTexts.titleMedium18(
                        context,
                        text: _formatDate(ride.createdAt),
                        isTextWidget: true,
                        fontWeight: FontWeight.w500,
                      ),
                      SizedBox(width: 8.w),
                      MuvamTexts.bodyLarge16(
                        context,
                        text: _formatTime(ride.createdAt),
                        isTextWidget: true,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Divider(thickness: 1, color: Colors.grey.shade300),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MuvamTexts.bodySmall12(
                              context,
                              text: 'Payment method',
                              isTextWidget: true,
                              color: const Color(0xFF9E9E9E),
                            ),
                            SizedBox(height: 8.h),
                            MuvamTexts.bodyLarge16(
                              context,
                              text: ride.paymentMethod,
                              isTextWidget: true,
                              fontWeight: FontWeight.w600,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1.w,
                        height: 40.h,
                        color: Colors.grey.shade300,
                      ),
                      SizedBox(width: 20.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MuvamTexts.bodySmall12(
                              context,
                              text: 'Vehicle',
                              isTextWidget: true,
                              color: const Color(0xFF9E9E9E),
                            ),
                            SizedBox(height: 8.h),
                            MuvamTexts.bodyLarge16(
                              context,
                              text: ride.vehicleType,
                              isTextWidget: true,
                              fontWeight: FontWeight.w600,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Divider(thickness: 1, color: Colors.grey.shade300),
                  SizedBox(height: 10.h),
                  MuvamTexts.bodyLarge16(
                    context,
                    text: 'Price',
                    isTextWidget: true,
                    color: const Color(0xFF9E9E9E),
                    fontWeight: FontWeight.w500,
                  ),
                  SizedBox(height: 8.h),
                  MuvamTexts.headlineMedium28(
                    context,
                    text: provider.formatPrice(ride.price),
                    isTextWidget: true,
                    fontWeight: FontWeight.w700,
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      context.pushNamed(
                        AppRoutes.editPrebooking.name,
                        extra: {
                          'ride': ride,
                          'initialScheduledAt': ride.createdAt,
                        },
                      );
                    },
                    child: Container(
                      width: 353.w,
                      height: 47.h,
                      decoration: BoxDecoration(
                        color: AppColors.kMainColor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: MuvamTexts.button16(
                          context,
                          text: 'Edit prebooking',
                          isTextWidget: true,
                          color: AppColors.kWhiteColor,
                        ),
                      ),
                    ),
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
