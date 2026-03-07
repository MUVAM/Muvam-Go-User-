import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/app_routes.dart';
import 'package:muvam/core/constants/muvam_text.dart';

class PaymentMethodSheet extends StatelessWidget {
  final List<String> paymentMethods;
  final String selectedPaymentMethod;
  final Function(String) onMethodSelected;
  final String Function(String) getPaymentMethodIcon;

  const PaymentMethodSheet({
    super.key,
    required this.paymentMethods,
    required this.selectedPaymentMethod,
    required this.onMethodSelected,
    required this.getPaymentMethodIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            context.pop();
            context.pushNamed(AppRoutes.promoCode.name);
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.kMainColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MuvamTexts.bodySmall12(
                    context,
                    text: 'Apply 20% off promo code>>',
                    isTextWidget: true,
                    color: AppColors.kWhiteColor,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
          child: DecoratedBox(
            decoration: const BoxDecoration(color: AppColors.kWhiteColor),
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 69.w,
                    height: 5.h,
                    margin: EdgeInsets.only(bottom: 20.h),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.5.r),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MuvamTexts.titleMedium18(
                        context,
                        text: 'Choose payment method',
                        isTextWidget: true,
                        fontWeight: FontWeight.w600,
                      ),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Icon(Icons.close, size: 24.sp),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  ...paymentMethods
                      .map(
                        (method) => Column(
                          children: [
                            _buildPaymentOption(context, method),
                            Divider(thickness: 1, color: Colors.grey.shade300),
                          ],
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(BuildContext context, String method) {
    final isSelected = selectedPaymentMethod == method;
    return GestureDetector(
      onTap: () {
        onMethodSelected(method);
        context.pop();
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 15.h),
        child: Row(
          children: [
            Image.asset(
              getPaymentMethodIcon(method),
              width: 55.w,
              height: 30.h,
              fit: BoxFit.cover,
            ),
            SizedBox(width: 15.w),
            Expanded(
              child: MuvamTexts.bodyLarge16(
                context,
                text: method,
                isTextWidget: true,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Colors.green, size: 20.sp),
          ],
        ),
      ),
    );
  }
}
