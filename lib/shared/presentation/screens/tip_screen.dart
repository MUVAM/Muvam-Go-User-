import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/text_styles.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/trips/presentation/screens/custom_tip_screen.dart';
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
      // Handle general tip setting (preference)
      if (mounted) {
        CustomFlushbar.showInfo(
          context: context,
          message: 'Default tip setting updated!',
        );
        Navigator.pop(context);
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      // Using the IP address as seen in other parts of the app
      final url = 'http://44.222.121.219/api/v1/rides/${widget.rideId}/tip';

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

      if (response.statusCode == 200) {
        if (mounted) {
          CustomFlushbar.showSuccess(
            context: context,
            message: 'Tip sent successfully!',
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception('Failed to send tip');
      }
    } catch (e) {
      AppLogger.log('Failed to send tip: $e', tag: 'TIP');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to send tip')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 45.w,
                        height: 45.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(100.r),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        padding: EdgeInsets.all(10.w),
                        child: Image.asset(
                          ConstImages.back,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30.h),
                Text(
                  widget.rideId != null
                      ? 'Tip your driver'
                      : 'Automatically add a tip to all trips',
                  style: ConstTextStyles.tipTitle,
                ),
                SizedBox(height: 20.h),
                Text('Choose an amount', style: ConstTextStyles.tipSubtitle),
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
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CustomTipScreen(),
                            ),
                          );
                          // If logic was added to CustomTipScreen to return value:
                          if (result != null && result is int) {
                            setState(() {
                              selectedTip = result;
                            });
                          }
                        } else {
                          setState(() {
                            selectedTip = amount;
                          });
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Color(ConstColors.mainColor)
                              : Color(ConstColors.fieldColor).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8.r),
                          border: isSelected
                              ? null
                              : Border.all(color: Colors.grey.shade300),
                        ),
                        child: Center(
                          child: Text(
                            isCustom
                                ? 'Custom'
                                : (amount == 0 ? 'No Tip' : '₦$amount'),
                            style: isCustom || amount == 0
                                ? TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  )
                                : ConstTextStyles.tipPrice.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
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
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: selectedTip != null && selectedTip is int
                          ? Color(ConstColors.mainColor)
                          : Color(ConstColors.fieldColor),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: _isLoading
                          ? SizedBox(
                              height: 20.h,
                              width: 20.w,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              widget.rideId != null ? 'Give tip' : 'Save',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
