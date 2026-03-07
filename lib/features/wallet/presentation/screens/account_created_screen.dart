import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/app_routes.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';
import 'package:muvam/layouts/presentation/shared/bottom_padding.dart';

class AccountCreatedScreen extends StatelessWidget {
  const AccountCreatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            SvgPicture.asset(ConstImages.timeStreamline),
            SizedBox(height: 20.h),
            MuvamTexts.titleLarge22(
              context,
              text: 'Processing',
              isTextWidget: true,
              center: true,
            ),
            SizedBox(height: 8.h),
            MuvamTexts.bodySmall12(
              context,
              text: "We're getting your wallet ready\nfor smooth rides",
              center: true,
              isTextWidget: true,
              color: Colors.grey,
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => context.goNamed(AppRoutes.wallet.name),
              child: Container(
                width: double.infinity,
                height: 47.h,
                decoration: BoxDecoration(
                  color: AppColors.kMainColor,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Center(
                  child: MuvamTexts.button16(
                    context,
                    text: 'Go to wallet',
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
    );
  }
}
