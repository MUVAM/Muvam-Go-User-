import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/app_spacings.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';
import 'package:muvam/layouts/presentation/shared/bottom_padding.dart';

class BuyGiftCardScreen extends StatelessWidget {
  const BuyGiftCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      appBar: AppBar(
        backgroundColor: AppColors.kWhiteColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.kBlackColor),
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: MuvamTexts.titleMedium18(
          context,
          text: 'Buy Gift Card',
          isTextWidget: true,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacings.k24),
        child: Column(
          children: [
            SizedBox(height: 24.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.kFormFieldColor,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: const BoxDecoration(
                      color: Color(0xFF98E69B),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.card_giftcard,
                        color: AppColors.kWhiteColor,
                        size: 24.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MuvamTexts.bodySmall12(
                        context,
                        text: 'Brand Selected',
                        isTextWidget: true,
                        color: AppColors.kSubtitleColor,
                      ),
                      SizedBox(height: 4.h),
                      MuvamTexts.bodyLarge16(
                        context,
                        text: 'Amazon Gift Card',
                        isTextWidget: true,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.only(bottom: 100.h),
              child: MuvamTexts.bodyLarge16(
                context,
                text: 'No values available for this gift card',
                center: true,
                isTextWidget: true,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: null,
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
                    fontFamily: 'Inter',
                    color: AppColors.kGreyColor,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            DeviceBottomPadding(),
          ],
        ),
      ),
    );
  }
}
