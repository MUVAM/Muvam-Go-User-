import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/colors.dart';

class BuyGiftCardScreen extends StatelessWidget {
  const BuyGiftCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Buy Gift Card',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SizedBox(height: 24.h),
              // Brand Selected Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: const Color(ConstColors.formFieldColor),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48.w,
                      height: 48.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFF98E69B), // Light green color matching design
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.card_giftcard, // Or a custom svg if available, but icon is safe
                          color: Colors.white,
                          size: 24.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Brand Selected',
                          style: TextStyle(
                            color: Color(ConstColors.subtitleColor),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Amazon Gift Card',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Centered Message
              Padding(
                padding: EdgeInsets.only(bottom: 100.h), // Push it up a bit visually
                child: Text(
                  'No values available for this gift card',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Bottom Button
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: null, // Disabled state as per design (seems inactive) or maybe just light grey? 
                  // The design shows it very light, often implying disabled or just a secondary style. 
                  // I'll assume disabled for "No values available".
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5F5F5),
                    disabledBackgroundColor: const Color(0xFFF5F5F5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                  ),
                  child: Text(
                    'Next',
                    style: TextStyle(
                      color: const Color(0xFFBDBDBD),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
