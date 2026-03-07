import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 20.h,
              left: 20.w,
              child: Container(
                width: 35.w,
                height: 35.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(100.r),
                ),
                padding: EdgeInsets.all(5.w),
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: SvgPicture.asset(
                    ConstImages.arrowLeftAlt,
                    fit: BoxFit.contain,
                    color: AppColors.kBlackColor,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 217.h,
              left: 70.w,
              child: Image.asset(
                ConstImages.comingSoon,
                width: 250.w,
                height: 250.h,
              ),
            ),
            Positioned(
              bottom: 40.h,
              left: 20.w,
              right: 20.w,
              child: GestureDetector(
                onTap: () => context.pop(),
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
                      text: 'Go Back',
                      isTextWidget: true,
                      color: AppColors.kWhiteColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
