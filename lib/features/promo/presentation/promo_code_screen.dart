import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/app_routes.dart';
import 'package:muvam/core/constants/app_spacings.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/promo/data/providers/promo_code_provider.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';
import 'package:muvam/layouts/presentation/shared/bottom_padding.dart';
import 'package:provider/provider.dart';

class PromoCodeScreen extends StatefulWidget {
  const PromoCodeScreen({super.key});

  @override
  State<PromoCodeScreen> createState() => _PromoCodeScreenState();
}

class _PromoCodeScreenState extends State<PromoCodeScreen> {
  final TextEditingController _promoController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _applyPromo() async {
    final provider = context.read<PromoCodeProvider>();
    final code = _promoController.text.trim();

    if (code.isEmpty) {
      CustomFlushbar.showError(
        context: context,
        message: 'Please enter a promo code',
      );
      return;
    }

    final success = await provider.validatePromoCode(code);

    if (success) {
      CustomFlushbar.showInfo(
        context: context,
        message:
            provider.promoValidation?.message ??
            'Promo code applied successfully!',
      );
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        context.goNamed(AppRoutes.home.name);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: SafeArea(
        child: Consumer<PromoCodeProvider>(
          builder: (context, promoProvider, child) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacings.k20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16.h),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F5F5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: AppColors.kBlackColor,
                        size: 20.sp,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  MuvamTexts.titleMedium18(
                    context,
                    text: 'Promo code',
                    isTextWidget: true,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(height: 30.h),
                  Container(
                    width: double.infinity,
                    height: 47.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9F8),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: TextField(
                      controller: _promoController,
                      textCapitalization: TextCapitalization.characters,
                      enabled: !promoProvider.isValidating,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.local_offer_outlined,
                          color: const Color(0xFFB1B1B1),
                          size: 20.sp,
                        ),
                        hintText: 'Enter promo code',
                        contentPadding: EdgeInsets.all(AppSpacings.k12),
                        hintStyle: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFFB1B1B1),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.kMainColor,
                      borderRadius: BorderRadius.circular(5.r),
                    ),
                    padding: EdgeInsets.all(15.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MuvamTexts.titleLarge22(
                          context,
                          text: '40% off on 5 rides',
                          isTextWidget: true,
                          fontWeight: FontWeight.w600,
                          color: AppColors.kWhiteColor,
                        ),
                        SizedBox(height: 8.h),
                        MuvamTexts.bodyLarge16(
                          context,
                          text: 'Maximum promo ₦500',
                          isTextWidget: true,
                          color: AppColors.kWhiteColor,
                        ),
                        SizedBox(height: 15.h),
                        Container(
                          width: double.infinity,
                          height: 0.8.h,
                          color: AppColors.kWhiteColor.withOpacity(0.3),
                        ),
                        SizedBox(height: 15.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            MuvamTexts.bodyMedium14(
                              context,
                              text: 'Apply',
                              isTextWidget: true,
                              fontWeight: FontWeight.w600,
                              color: AppColors.kWhiteColor,
                            ),
                            MuvamTexts.bodySmall12(
                              context,
                              text: '3 days left',
                              isTextWidget: true,
                              fontWeight: FontWeight.w500,
                              color: AppColors.kWhiteColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: promoProvider.isValidating ? null : _applyPromo,
                    child: Container(
                      width: double.infinity,
                      height: 47.h,
                      decoration: BoxDecoration(
                        color: AppColors.kMainColor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: promoProvider.isValidating
                            ? SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.kWhiteColor,
                                ),
                              )
                            : MuvamTexts.button16(
                                context,
                                text: promoProvider.hasAppliedPromo
                                    ? 'Applied'
                                    : 'Apply',
                                isTextWidget: true,
                                color: AppColors.kWhiteColor,
                              ),
                      ),
                    ),
                  ),
                  DeviceBottomPadding(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
