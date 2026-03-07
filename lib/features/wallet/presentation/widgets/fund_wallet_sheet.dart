import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/core/utils/extension.dart';

class FundWalletSheet {
  static void show(BuildContext context) {
    final TextEditingController amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.kWhiteColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 69.w,
                height: 5.h,
                margin: EdgeInsets.only(bottom: 20.h),
                decoration: BoxDecoration(
                  color: AppColors.kGreyColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2.5.r),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MuvamTexts.titleLarge22(
                    context,
                    text: 'Fund wallet',
                    fontWeight: FontWeight.w600,
                    color: AppColors.kBlackColor,
                  ),
                  SizedBox(height: 20.h),
                  MuvamTexts.bodyMedium14(
                    context,
                    text: 'How much do you want to add?',
                    color: AppColors.kBlackColor,
                  ),
                  SizedBox(height: 15.h),
                  Container(
                    width: 353.w,
                    height: 39.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.kGreyColor.withOpacity(0.3),
                        width: 0.4,
                      ),
                    ),
                    padding: EdgeInsets.all(10.w),
                    child: TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter amount',
                        prefixText: '₦ ',
                        prefixStyle: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(
                              fontWeight: FontWeight.w400,
                              color: AppColors.kBlackColor,
                            ),
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w400,
                        color: AppColors.kBlackColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 30.h),
                  GestureDetector(
                    onTap: () {
                      context.pop();
                    },
                    child: Container(
                      width: 353.w,
                      height: 47.h,
                      decoration: BoxDecoration(
                        color: AppColors.kMainColor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: MuvamTexts.button16(
                          context,
                          text: 'Continue',
                          color: AppColors.kWhiteColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
