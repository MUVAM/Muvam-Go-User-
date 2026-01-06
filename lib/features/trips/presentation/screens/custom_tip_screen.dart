import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/text_styles.dart';

class CustomTipScreen extends StatefulWidget {
  const CustomTipScreen({super.key});

  @override
  State<CustomTipScreen> createState() => _CustomTipScreenState();
}

class _CustomTipScreenState extends State<CustomTipScreen> {
  final TextEditingController customTipController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              Container(
                width: 45.w,
                height: 45.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100.r),
                ),
                padding: EdgeInsets.all(10.w),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Image.asset(ConstImages.back, fit: BoxFit.contain),
                ),
              ),
              SizedBox(height: 30.h),
              Text('Choose a custom tip', style: ConstTextStyles.tipTitle),
              SizedBox(height: 40.h),
              Container(
                width: 353.w,
                height: 50.h,
                decoration: BoxDecoration(
                  color: Color(ConstColors.fieldColor).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: TextField(
                  controller: customTipController,
                  keyboardType: TextInputType.number,
                  style: ConstTextStyles.inputText,
                  decoration: InputDecoration(
                    hintText: 'Enter amount',
                    prefixText: '₦ ',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 15.h,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
              SizedBox(height: 40.h),
              GestureDetector(
                onTap: () {
                  if (customTipController.text.isNotEmpty) {
                    final amount = int.tryParse(customTipController.text);
                    if (amount != null) {
                      Navigator.pop(context, amount);
                    }
                  }
                },
                child: Container(
                  width: 353.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: customTipController.text.isNotEmpty
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
