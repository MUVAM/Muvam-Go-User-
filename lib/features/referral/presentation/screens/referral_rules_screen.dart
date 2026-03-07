import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/features/referral/presentation/widgets/rule_item.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';

class ReferralRulesScreen extends StatelessWidget {
  const ReferralRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Image.asset(
                      ConstImages.back,
                      width: 33.w,
                      height: 33.h,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: MuvamTexts.titleMedium18(
                        context,
                        text: 'Referral',
                        isTextWidget: true,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 24.w),
                ],
              ),
              SizedBox(height: 40.h),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.kWhiteColor,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: EdgeInsets.all(20.w),
                alignment: Alignment.center,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: MuvamTexts.titleMedium18(
                        context,
                        text: 'How to get',
                        isTextWidget: true,
                        fontWeight: FontWeight.w600,
                        color: AppColors.kMainColor,
                        center: true,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    const RuleItem(
                      number: '1',
                      text:
                          'Once your friend download the app, register with your referral code you get qualified for the reward',
                    ),
                    SizedBox(height: 15.h),
                    const RuleItem(
                      number: '2',
                      text:
                          'Once your friend placed a ride order, then you will be eligible for the 3days free ride',
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
