import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/promo/data/providers/promo_code_provider.dart';
import 'package:provider/provider.dart';

class PromoCodeScreen extends StatefulWidget {
  const PromoCodeScreen({super.key});

  @override
  State<PromoCodeScreen> createState() => _PromoCodeScreenState();
}

class _PromoCodeScreenState extends State<PromoCodeScreen> {
  final TextEditingController _promoController = TextEditingController();
  final FocusNode _promoFocusNode = FocusNode();

  @override
  void dispose() {
    _promoController.dispose();
    _promoFocusNode.dispose();
    super.dispose();
  }

  Future<void> _validatePromo(PromoCodeProvider provider) async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;

    _promoFocusNode.unfocus();

    final success = await provider.validatePromoCode(code);

    if (mounted) {
      if (success) {
        CustomFlushbar.showInfo(
          context: context,
          message: "Promo code applied successfully!'",
        );
      } else {
        CustomFlushbar.showError(
          context: context,
          message: '${provider.errorMessage}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<PromoCodeProvider>(
          builder: (context, promoProvider, child) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20.h),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset(
                      ConstImages.back,
                      width: 30.w,
                      height: 30.h,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'Promo code',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 30.h),
                  Container(
                    width: 353.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: Color(0xFFF7F9F8),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _promoController,
                            focusNode: _promoFocusNode,
                            textCapitalization: TextCapitalization.characters,
                            onSubmitted: (_) => _validatePromo(promoProvider),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                Icons.local_offer_outlined,
                                color: Color(0xFFB1B1B1),
                                size: 20.sp,
                              ),
                              hintText: 'Enter promo code',
                              hintStyle: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFFB1B1B1),
                              ),
                            ),
                          ),
                        ),
                        if (promoProvider.isValidating)
                          SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(ConstColors.mainColor),
                            ),
                          )
                        else if (_promoController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () => _validatePromo(promoProvider),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: Color(ConstColors.mainColor),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                'Apply',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 15.h),
                  if (promoProvider.promoValidation != null) ...[
                    Container(
                      width: 353.w,
                      padding: EdgeInsets.all(15.w),
                      decoration: BoxDecoration(
                        color: Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: Color(ConstColors.mainColor),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Color(ConstColors.mainColor),
                                    size: 20.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Promo Applied',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Color(ConstColors.mainColor),
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () {
                                  promoProvider.clearPromoCode();
                                  _promoController.clear();
                                },
                                child: Icon(
                                  Icons.close,
                                  size: 20.sp,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 15.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Code:',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                promoProvider.appliedPromoCode ?? '',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Discount:',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                '- ${promoProvider.formatPrice(promoProvider.promoValidation!.discountAmount)}',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Color(ConstColors.mainColor),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Final Amount:',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                promoProvider.formatPrice(
                                  promoProvider.promoValidation!.finalAmount,
                                ),
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Color(ConstColors.mainColor),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 15.h),
                  ],
                  Container(
                    width: 353.w,
                    height: 144.h,
                    decoration: BoxDecoration(
                      color: Color(ConstColors.mainColor),
                      borderRadius: BorderRadius.circular(5.r),
                    ),
                    padding: EdgeInsets.all(15.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '40% off on 5 rides',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.0,
                            letterSpacing: -0.41,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'maximum promo ₦500',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            height: 1.0,
                            letterSpacing: -0.41,
                          ),
                        ),
                        SizedBox(height: 15.h),
                        Container(
                          width: double.infinity,
                          height: 0.8.h,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        SizedBox(height: 15.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                _promoController.text = 'PROMO40';
                              },
                              child: Text(
                                'Tap to use',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  height: 1.0,
                                  letterSpacing: -0.41,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            Text(
                              '3 days left',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                height: 1.0,
                                letterSpacing: -0.41,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
