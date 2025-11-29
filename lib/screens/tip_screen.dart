import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/colors.dart';
import '../constants/images.dart';
import '../constants/text_styles.dart';
import 'custom_tip_screen.dart';

class TipScreen extends StatefulWidget {
  const TipScreen({super.key});

  @override
  State<TipScreen> createState() => _TipScreenState();
}

class _TipScreenState extends State<TipScreen> {
  final List<dynamic> tipAmounts = [0, 500,1000, 1500, 2000, 'Custom'];
  int? selectedTip;

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
                Positioned(
                  top: 70.h,
                  left: 20.w,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 45.w,
                      height: 45.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(100.r),
                      ),
                      padding: EdgeInsets.all(10.w),
                      child: Image.asset(
                        ConstImages.back,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30.h),
                Text(
                  'Automatically add a tip to all trips',
                  style: ConstTextStyles.tipTitle,
                ),
                SizedBox(height: 20.h),
                Text(
                  'Choose an amount',
                  style: ConstTextStyles.tipSubtitle,
                ),
                SizedBox(height: 30.h),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1,
                    crossAxisSpacing: 15.w,
                    mainAxisSpacing: 15.h,
                  ),
                  itemCount: tipAmounts.length,
                  itemBuilder: (context, index) {
                    final amount = tipAmounts[index];
                    final isSelected = selectedTip == amount;
                    final isCustom = amount == 'Custom';
                    
                    return GestureDetector(
                      onTap: () {
                        if (isCustom) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CustomTipScreen()),
                          );
                        } else {
                          setState(() {
                            selectedTip = amount;
                          });
                        }
                      },
                      child: Container(
                        width: 170.w,
                        height: 170.h,
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Color(ConstColors.mainColor)
                              : Color(ConstColors.fieldColor).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: Text(
                            isCustom ? 'Custom' : '₦$amount',
                            style: isCustom ? TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.black,
                            ) : ConstTextStyles.tipPrice.copyWith(
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 40.h),
                Container(
                  width: 353.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: selectedTip != null 
                        ? Color(ConstColors.mainColor)
                        : Color(ConstColors.fieldColor),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Center(
                    child: Text(
                      'Save tip',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
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