import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/app_spacings.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';

class CustomTipScreen extends StatefulWidget {
  const CustomTipScreen({super.key});

  @override
  State<CustomTipScreen> createState() => _CustomTipScreenState();
}

class _CustomTipScreenState extends State<CustomTipScreen> {
  final TextEditingController customTipController = TextEditingController();

  @override
  void dispose() {
    customTipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacings.k20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              Container(
                width: 45.w,
                height: 45.h,
                decoration: BoxDecoration(
                  color: AppColors.kWhiteColor,
                  borderRadius: BorderRadius.circular(100.r),
                ),
                padding: EdgeInsets.all(10.w),
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Image.asset(ConstImages.back, fit: BoxFit.contain),
                ),
              ),
              SizedBox(height: 30.h),
              MuvamTexts.titleLarge22(
                context,
                text: 'Choose a custom tip',
                isTextWidget: true,
                fontWeight: FontWeight.w700,
              ),
              SizedBox(height: 40.h),
              Container(
                width: 353.w,
                height: 50.h,
                decoration: BoxDecoration(
                  color: AppColors.kFieldColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: TextField(
                  controller: customTipController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter amount',
                    prefixText: '₦ ',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 15.h,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(height: 40.h),
              GestureDetector(
                onTap: () {
                  if (customTipController.text.isNotEmpty) {
                    final amount = int.tryParse(customTipController.text);
                    if (amount != null) {
                      context.pop(amount);
                    }
                  }
                },
                child: Container(
                  width: 353.w,
                  height: 47.h,
                  decoration: BoxDecoration(
                    color: customTipController.text.isNotEmpty
                        ? AppColors.kMainColor
                        : AppColors.kFieldColor,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Center(
                    child: MuvamTexts.button16(
                      context,
                      text: 'Save tip',
                      isTextWidget: true,
                      color: AppColors.kWhiteColor,
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
