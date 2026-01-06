import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/activities/data/providers/activities_tabs_provider.dart';
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
      context.read<ActivitiesTabsProvider>().fetchRideDetails(widget.rideId);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<ActivitiesTabsProvider>(
          builder: (context, provider, child) {
            if (provider.isLoadingDetails) {
              return Center(
                child: CircularProgressIndicator(
                  color: Color(ConstColors.mainColor),
                ),
              );
            }

            if (provider.selectedRide == null) {
              return Center(child: Text('Ride not found'));
            }

            final ride = provider.selectedRide!;

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
                          Navigator.pop(context);
                        },
                        child: Icon(
                          Icons.arrow_back,
                          size: 24.sp,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'En route',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w600,
                      color: Color(ConstColors.mainColor),
                    ),
                  ),
                  SizedBox(height: 30.h),
                  Container(
                    padding: EdgeInsets.all(15.w),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6.w,
                              height: 6.h,
                              decoration: BoxDecoration(
                                color: Color(ConstColors.mainColor),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              'Pick Up',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                height: 1.0,
                                letterSpacing: -0.32,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 5.h),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: 16.w),
                            child: Text(
                              ride.pickupAddress,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                                letterSpacing: -0.32,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 15.h),
                        Divider(thickness: 1, color: Colors.grey.shade300),
                        SizedBox(height: 15.h),
                        Row(
                          children: [
                            Container(
                              width: 6.w,
                              height: 6.h,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              'Destination',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                height: 1.0,
                                letterSpacing: -0.32,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 5.h),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: 16.w),
                            child: Text(
                              ride.destAddress,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                                letterSpacing: -0.32,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Divider(thickness: 1, color: Colors.grey.shade300),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Text(
                        'Date',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          height: 1.0,
                          letterSpacing: -0.32,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      provider.formatDateTime(
                        ride.scheduledAt ?? ride.createdAt,
                      ),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                        letterSpacing: -0.32,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Divider(thickness: 1, color: Colors.grey.shade300),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Method',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                height: 1.0,
                                letterSpacing: -0.32,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 5.h),
                            Text(
                              ride.paymentMethod,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                                letterSpacing: -0.32,
                                color: Colors.black,
                              ),
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
                            Text(
                              'Vehicle',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                height: 1.0,
                                letterSpacing: -0.32,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 5.h),
                            Text(
                              ride.vehicleType,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                                letterSpacing: -0.32,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Divider(thickness: 1, color: Colors.grey.shade300),
                  SizedBox(height: 20.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Price',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          provider.formatPrice(ride.price),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Spacer(),
                  Container(
                    width: 353.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: Color(ConstColors.mainColor),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: GestureDetector(
                      onTap: _openGoogleMaps,
                      child: Center(
                        child: Text(
                          'View in map',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
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
