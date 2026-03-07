import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/features/wallet/presentation/widgets/funding_step_widget.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';

class HowToFundScreen extends StatelessWidget {
  const HowToFundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      appBar: AppBar(
        backgroundColor: AppColors.kWhiteColor,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => GoRouter.of(context).pop(),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Image.asset(ConstImages.back, width: 30.w, height: 30.h),
          ),
        ),
        title: MuvamTexts.titleMedium18(
          context,
          text: 'How to fund',
          isTextWidget: true,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FundingStepWidget(
                      number: '1. ',
                      text:
                          'Tap the copy icon next to your wallet account number.',
                    ),
                    SizedBox(height: 10.h),
                    const FundingStepWidget(
                      number: '2. ',
                      text: 'Open your bank app or use USSD.',
                    ),
                    SizedBox(height: 10.h),
                    const FundingStepWidget(
                      number: '3. ',
                      text:
                          'Paste the wallet account number and amount to transfer.',
                    ),
                    SizedBox(height: 10.h),
                    const FundingStepWidget(
                      number: '4. ',
                      text: 'Confirm the transfer.',
                    ),
                    SizedBox(height: 10.h),
                    const FundingStepWidget(
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
    );
  }
}
