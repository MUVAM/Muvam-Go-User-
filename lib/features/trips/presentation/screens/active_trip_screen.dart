import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/activities/data/providers/activities_tabs_provider.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ActiveTripScreen extends StatefulWidget {
  final int rideId;

  const ActiveTripScreen({super.key, required this.rideId});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
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

  Future<void> _openGoogleMaps() async {
    try {
      final provider = context.read<ActivitiesTabsProvider>();
      final ride = provider.selectedRide;

      if (ride == null) {
        CustomFlushbar.showError(
          context: context,
          message: 'Ride details not available',
        );
        return;
      }

      String? destinationAddress;

      if (ride.status == 'started') {
        destinationAddress = ride.destAddress;
      } else {
        destinationAddress = ride.pickupAddress;
      }

      if (destinationAddress.isEmpty) {
        CustomFlushbar.showError(
          context: context,
          message: 'Location address not available',
        );
        return;
      }

      final encodedAddress = Uri.encodeComponent(destinationAddress);
      final url =
          'https://www.google.com/maps/search/?api=1&query=$encodedAddress';

      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        CustomFlushbar.showError(
          context: context,
          message: 'Could not open Google Maps',
        );
      }
    } catch (e) {
      AppLogger.log('Error opening Google Maps: $e');
      CustomFlushbar.showError(
        context: context,
        message: 'Failed to open Google Maps',
      );
    }
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
                provider.activeRides.firstWhere(
                  (r) => r.id == widget.rideId,
                  orElse: () => provider.activeRides.isNotEmpty
                      ? provider.activeRides.first
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
                    text: 'En route',
                    color: AppColors.kMainColor,
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
                          color: AppColors.kError,
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
                  SizedBox(height: 20.h),
                  MuvamTexts.bodySmall12(
                    context,
                    text: 'When',
                    color: const Color(0xFF9E9E9E),
                    isTextWidget: true,
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      MuvamTexts.titleMedium18(
                        context,
                        text: _formatDate(ride.createdAt),
                        isTextWidget: true,
                      ),
                      MuvamTexts.bodyLarge16(
                        context,
                        text: _formatTime(ride.createdAt),
                        isTextWidget: true,
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
                              color: const Color(0xFF9E9E9E),
                              isTextWidget: true,
                            ),
                            SizedBox(height: 8.h),
                            MuvamTexts.bodyLarge16(
                              context,
                              text: ride.paymentMethod,
                              fontWeight: FontWeight.w600,
                              isTextWidget: true,
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
                              color: const Color(0xFF9E9E9E),
                              isTextWidget: true,
                            ),
                            SizedBox(height: 8.h),
                            MuvamTexts.bodyLarge16(
                              context,
                              text: ride.vehicleType,
                              fontWeight: FontWeight.w600,
                              isTextWidget: true,
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
                    color: const Color(0xFF9E9E9E),
                    isTextWidget: true,
                  ),
                  SizedBox(height: 8.h),
                  MuvamTexts.titleMedium18(
                    context,
                    text: provider.formatPrice(ride.price),
                    fontWeight: FontWeight.w700,
                    isTextWidget: true,
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _openGoogleMaps,
                    child: Container(
                      width: double.infinity,
                      height: 47.h,
                      decoration: BoxDecoration(
                        color: AppColors.kMainColor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: MuvamTexts.button16(
                          context,
                          text: 'View in map',
                          color: AppColors.kWhiteColor,
                          isTextWidget: true,
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
