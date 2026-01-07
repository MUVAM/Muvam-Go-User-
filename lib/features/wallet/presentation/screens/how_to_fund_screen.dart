import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/features/wallet/presentation/widgets/funding_step_widget.dart';

class HowToFundScreen extends StatelessWidget {
  const HowToFundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Image.asset(ConstImages.back, width: 30.w, height: 30.h),
          ),
        ),
        title: Text(
          'How to fund',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FundingStepWidget(
                        number: '1. ',
                        text:
                            'Tap the copy icon next to your wallet account number.',
                      ),
                      SizedBox(height: 10.h),
                      FundingStepWidget(
                        number: '2. ',
                        text: 'Open your bank app or use USSD.',
                      ),
                      SizedBox(height: 10.h),
                      FundingStepWidget(
                        number: '3. ',
                        text:
                            'Paste the wallet account number and amount to transfer.',
                      ),
                      SizedBox(height: 10.h),
                      FundingStepWidget(
                        number: '4. ',
                        text: 'Confirm the transfer.',
                      ),
                      SizedBox(height: 10.h),
                      FundingStepWidget(
                        number: '5. ',
                        text: 'Your MUVAM wallet will be updated instantly.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
