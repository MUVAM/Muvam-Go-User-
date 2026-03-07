import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/app_routes.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';
import 'package:muvam/layouts/presentation/shared/bottom_padding.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TipScreen extends StatefulWidget {
  final int? rideId;
  const TipScreen({super.key, this.rideId});

  @override
  State<TipScreen> createState() => _TipScreenState();
}

class _TipScreenState extends State<TipScreen> {
  final List<dynamic> tipAmounts = [0, 500, 1000, 1500, 2000, 'Custom'];
  dynamic selectedTip;
  bool _isLoading = false;

  Future<void> _submitTip() async {
    if (selectedTip == null || selectedTip == 'Custom') return;

    if (widget.rideId == null) {
      if (mounted) {
        CustomFlushbar.showInfo(
          context: context,
          message: 'Default tip setting updated!',
        );
        context.pop();
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final url = 'https://api.muvam.app/api/v1/rides/${widget.rideId}/tip';

      AppLogger.log(
        'Sending tip: $selectedTip to ride ${widget.rideId}',
        tag: 'TIP',
      );

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'amount': selectedTip}),
      );

      AppLogger.log('Tip response: ${response.body}', tag: 'TIP');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) context.pop(true);
      } else {
        throw Exception('Failed to send tip');
      }
    } catch (e) {
      AppLogger.log('Failed to send tip: $e', tag: 'TIP');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 45.w,
                    height: 45.h,
                    decoration: BoxDecoration(
                      color: AppColors.kWhiteColor,
                      borderRadius: BorderRadius.circular(100.r),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: EdgeInsets.all(10.w),
                    child: Image.asset(ConstImages.back, fit: BoxFit.contain),
                  ),
                ),
                SizedBox(height: 30.h),
                MuvamTexts.titleLarge22(
                  context,
                  text: widget.rideId != null
                      ? 'Tip your driver'
                      : 'Automatically add a tip to all trips',
                  isTextWidget: true,
                  fontWeight: FontWeight.w700,
                ),
                SizedBox(height: 20.h),
                MuvamTexts.bodyMedium14(
                  context,
                  text: 'Choose an amount',
                  isTextWidget: true,
                  color: AppColors.kSubtitleColor,
                ),
                SizedBox(height: 30.h),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 15.w,
                    mainAxisSpacing: 15.h,
                  ),
                  itemCount: tipAmounts.length,
                  itemBuilder: (context, index) {
                    final amount = tipAmounts[index];
                    final isSelected = selectedTip == amount;
                    final isCustom = amount == 'Custom';
                    return GestureDetector(
                      onTap: () async {
                        if (isCustom) {
                          final result = await context.pushNamed(
                            AppRoutes.customTip.name,
                          );
                          if (result != null && result is int) {
                            setState(() => selectedTip = result);
                          }
                        } else {
                          setState(() => selectedTip = amount);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.kMainColor
                              : AppColors.kFieldColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8.r),
                          border: isSelected
                              ? null
                              : Border.all(color: Colors.grey.shade300),
                        ),
                        child: Center(
                          child: isCustom || amount == 0
                              ? MuvamTexts.titleMedium18(
                                  context,
                                  text: isCustom ? 'Custom' : 'No Tip',
                                  isTextWidget: true,
                                  color: isSelected
                                      ? AppColors.kWhiteColor
                                      : AppColors.kBlackColor,
                                  fontWeight: FontWeight.w600,
                                )
                              : MuvamTexts.titleLarge22(
                                  context,
                                  text: '₦$amount',
                                  isTextWidget: true,
                                  color: isSelected
                                      ? AppColors.kWhiteColor
                                      : AppColors.kBlackColor,
                                  fontWeight: FontWeight.w700,
                                ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 40.h),
                GestureDetector(
                  onTap: _isLoading ? null : _submitTip,
                  child: Container(
                    width: 353.w,
                    height: 47.h,
                    decoration: BoxDecoration(
                      color: selectedTip != null && selectedTip is int
                          ? AppColors.kMainColor
                          : AppColors.kFieldColor,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: _isLoading
                          ? SizedBox(
                              height: 20.h,
                              width: 20.w,
                              child: CircularProgressIndicator(
                                color: AppColors.kWhiteColor,
                                strokeWidth: 2,
                              ),
                            )
                          : MuvamTexts.button16(
                              context,
                              text: widget.rideId != null ? 'Give tip' : 'Save',
                              isTextWidget: true,
                              color: AppColors.kWhiteColor,
                            ),
                    ),
                  ),
                ),
                DeviceBottomPadding(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
