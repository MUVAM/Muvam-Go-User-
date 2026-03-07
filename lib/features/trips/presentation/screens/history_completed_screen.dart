import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/app_spacings.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/activities/data/providers/activities_tabs_provider.dart';
import 'package:muvam/features/trips/presentation/widgets/receipt_generator.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class HistoryCompletedScreen extends StatefulWidget {
  final int rideId;

  const HistoryCompletedScreen({super.key, required this.rideId});

  @override
  State<HistoryCompletedScreen> createState() => _HistoryCompletedScreenState();
}

class _HistoryCompletedScreenState extends State<HistoryCompletedScreen> {
  File? _generatedReceipt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ActivitiesTabsProvider>();
      if (provider.selectedRide?.id != widget.rideId) {
        provider.fetchRideDetails(widget.rideId);
      }
      _preGenerateReceipt();
    });
  }

  Future<void> _preGenerateReceipt() async {
    try {
      final provider = context.read<ActivitiesTabsProvider>();
      final ride =
          provider.selectedRide ??
          provider.historyRides.firstWhere(
            (r) => r.id == widget.rideId,
            orElse: () => provider.historyRides.isNotEmpty
                ? provider.historyRides.first
                : null as dynamic,
          );

      final file = await ReceiptGenerator.generateReceipt(
        tripId: ride.id,
        driverName: ride.driver!.fullName,
        passengerName: ride.passenger!.fullName,
        paymentMethod: ride.paymentMethod,
        amount: ride.price,
        completionTime: ride.createdAt,
      );

      if (mounted) setState(() => _generatedReceipt = file);
    } catch (_) {
      // Silent fail — user can retry via button
    }
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

  Future<void> _downloadReceipt() async {
    try {
      if (_generatedReceipt != null) {
        await Share.shareXFiles([
          XFile(_generatedReceipt!.path),
        ], text: 'Receipt for Trip #${widget.rideId}');
        if (mounted) {
          CustomFlushbar.showInfo(
            context: context,
            message: 'Receipt generated successfully!',
          );
        }
        return;
      }

      final provider = context.read<ActivitiesTabsProvider>();
      final ride =
          provider.selectedRide ??
          provider.historyRides.firstWhere(
            (r) => r.id == widget.rideId,
            orElse: () => provider.historyRides.isNotEmpty
                ? provider.historyRides.first
                : null as dynamic,
          );

      if (await Permission.storage.isDenied) {
        await Permission.storage.request();
      }

      final file = await ReceiptGenerator.generateReceipt(
        tripId: ride.id,
        driverName: ride.driver!.fullName,
        passengerName: ride.passenger!.fullName,
        paymentMethod: ride.paymentMethod,
        amount: ride.price,
        completionTime: ride.createdAt,
      );

      if (mounted) {
        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Receipt for Trip #${ride.id}');
        CustomFlushbar.showInfo(
          context: context,
          message: 'Receipt generated successfully!',
        );
      }
    } catch (_) {
      if (mounted) {
        CustomFlushbar.showError(
          context: context,
          message: 'Failed to download receipt. Please try again.',
        );
      }
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
              padding: EdgeInsets.all(AppSpacings.k20),
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
                    text: 'Booking Id: ${ride.id}',
                    isTextWidget: true,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(height: 12.h),
                  MuvamTexts.titleMedium18(
                    context,
                    text: _formatTime(ride.createdAt),
                    isTextWidget: true,
                    fontWeight: FontWeight.w500,
                  ),
                  MuvamTexts.titleMedium18(
                    context,
                    text: _formatDate(ride.createdAt),
                    isTextWidget: true,
                  ),
                  SizedBox(height: 30.h),
                  Row(
                    children: [
                      Container(
                        width: 6.w,
                        height: 6.h,
                        decoration: const BoxDecoration(
                          color: AppColors.kMainColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      MuvamTexts.bodySmall12(
                        context,
                        text: 'Pick Up',
                        isTextWidget: true,
                        color: const Color(0xFF9E9E9E),
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 16.w),
                      child: MuvamTexts.bodyMedium14(
                        context,
                        text: ride.pickupAddress,
                        isTextWidget: true,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                        width: 6.w,
                        height: 6.h,
                        decoration: const BoxDecoration(
                          color: AppColors.kError,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      MuvamTexts.bodySmall12(
                        context,
                        text: 'Destination',
                        isTextWidget: true,
                        color: const Color(0xFF9E9E9E),
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 16.w),
                      child: MuvamTexts.bodyMedium14(
                        context,
                        text: ride.destAddress,
                        isTextWidget: true,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Divider(thickness: 1, color: Colors.grey.shade300),
                  SizedBox(height: 20.h),
                  MuvamTexts.bodyMedium14(
                    context,
                    text: 'Payment method',
                    isTextWidget: true,
                    color: const Color(0xFFB1B1B1),
                    fontWeight: FontWeight.w500,
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.kFieldColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5.r),
                    ),
                    padding: EdgeInsets.all(16.sp),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(14.sp),
                          decoration: BoxDecoration(
                            color: AppColors.kWhiteColor,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              MuvamTexts.bodySmall12(
                                context,
                                text: 'Amount',
                                isTextWidget: true,
                                fontWeight: FontWeight.w500,
                              ),
                              MuvamTexts.bodyMedium14(
                                context,
                                text: provider.formatPrice(ride.price),
                                isTextWidget: true,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 15.h),
                        Row(
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
                                SizedBox(width: 10.w),
                                MuvamTexts.bodyMedium14(
                                  context,
                                  text: ride.paymentMethod,
                                  isTextWidget: true,
                                ),
                              ],
                            ),
                            MuvamTexts.bodyMedium14(
                              context,
                              text: provider.formatPrice(ride.price),
                              isTextWidget: true,
                              color: AppColors.kMainColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  MuvamTexts.titleMedium18(
                    context,
                    text: 'Service type',
                    isTextWidget: true,
                    color: const Color(0xFFB1B1B1),
                    fontWeight: FontWeight.w500,
                  ),
                  MuvamTexts.headlineSmall24(
                    context,
                    text: ride.vehicleType,
                    isTextWidget: true,
                    fontWeight: FontWeight.w500,
                  ),
                  SizedBox(height: 30.h),
                  Center(
                    child: GestureDetector(
                      onTap: _downloadReceipt,
                      child: MuvamTexts.bodyLarge16(
                        context,
                        text: 'Download receipt',
                        isTextWidget: true,
                        color: const Color(0xFF2A8359),
                        fontWeight: FontWeight.w600,
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
