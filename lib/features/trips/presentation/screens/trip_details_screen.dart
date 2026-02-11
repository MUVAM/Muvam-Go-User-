import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/features/activities/data/providers/activities_tabs_provider.dart';
import 'package:muvam/features/trips/presentation/screens/edit_prebooking_screen.dart';
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
      context.read<ActivitiesTabsProvider>().fetchRideDetails(widget.rideId);
    });
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
                        child: Image.asset(
                          ConstImages.back,
                          width: 33.w,
                          height: 33.h,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'Trip scheduled',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 30.h),
                  Row(
                    children: [
                      Container(
                        width: 8.w,
                        height: 8.h,
                        decoration: BoxDecoration(
                          color: Color(ConstColors.mainColor),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Pick up',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    ride.pickupAddress,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: Colors.black,
                    ),
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
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Destination',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    ride.destAddress,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'When',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    provider.formatDateTime(ride.scheduledAt ?? ride.createdAt),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
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
                            Text(
                              'Payment method',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF9E9E9E),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              ride.paymentMethod,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
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
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF9E9E9E),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              ride.vehicleType,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Divider(thickness: 1, color: Colors.grey.shade300),
                  SizedBox(height: 10.h),
                  Text(
                    'Price',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    provider.formatPrice(ride.price),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditPrebookingScreen(ride: ride),
                        ),
                      );
                    },
                    child: Container(
                      width: 353.w,
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: Color(ConstColors.mainColor),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: Text(
                          'Edit prebooking',
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
