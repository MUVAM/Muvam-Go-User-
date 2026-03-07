import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/features/wallet/data/providers/wallet_provider.dart';

class WalletCard extends StatelessWidget {
  final dynamic walletSummary;
  final WalletProvider walletProvider;
  final VoidCallback onCopyAccountNumber;
  final VoidCallback onFundWallet;

  const WalletCard({
    super.key,
    required this.walletSummary,
    required this.walletProvider,
    required this.onCopyAccountNumber,
    required this.onFundWallet,
  });

  @override
  Widget build(BuildContext context) {
    final virtualAccount = walletSummary.virtualAccount;

    return Stack(
      children: [
        Container(
          width: 353.w,
          height: 147.h,
          decoration: BoxDecoration(
            color: AppColors.kMainColor,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(15.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MuvamTexts.titleSmall14(
                      context,
                      text: 'Your balance',
                      fontWeight: FontWeight.w500,
                      color: AppColors.kWhiteColor,
                    ),
                    GestureDetector(
                      onTap: onCopyAccountNumber,
                      child: Container(
                        width: 100.w,
                        height: 28.h,
                        decoration: BoxDecoration(
                          color: AppColors.kWhiteColor,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add,
                              size: 14.sp,
                              color: AppColors.kMainColor,
                            ),
                            SizedBox(width: 3.w),
                            MuvamTexts.bodySmall12(
                              context,
                              text: 'Fund wallet',
                              fontWeight: FontWeight.w500,
                              color: AppColors.kMainColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: MuvamTexts.headlineSmall24(
                    context,
                    text: walletProvider.formatAmount(walletSummary.balance),
                    fontWeight: FontWeight.w600,
                    color: AppColors.kWhiteColor,
                  ),
                ),
                SizedBox(height: 8.h),
                if (virtualAccount != null) ...[
                  MuvamTexts.bodySmall12(
                    context,
                    text: virtualAccount.bankName,
                    fontWeight: FontWeight.w500,
                    color: AppColors.kWhiteColor,
                  ),
                  SizedBox(height: 4.h),
                  GestureDetector(
                    onTap: onCopyAccountNumber,
                    child: Row(
                      children: [
                        MuvamTexts.titleMedium18(
                          context,
                          text: virtualAccount.accountNumber,
                          fontWeight: FontWeight.w500,
                          color: AppColors.kWhiteColor,
                        ),
                        SizedBox(width: 8.w),
                        Icon(
                          Icons.copy,
                          size: 14.sp,
                          color: AppColors.kWhiteColor,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  MuvamTexts.bodySmall12(
                    context,
                    text: 'No virtual account',
                    color: AppColors.kWhiteColor.withOpacity(0.7),
                  ),
                ],
              ],
            ),
          ),
        ),
        Positioned(
          top: -54.h,
          left: -43.w,
          child: Container(
            width: 103.w,
            height: 103.h,
            decoration: BoxDecoration(
              color: AppColors.kWhiteColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: 99.h,
          left: 237.w,
          child: Container(
            width: 79.w,
            height: 79.h,
            decoration: BoxDecoration(
              color: AppColors.kWhiteColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: 89.h,
          left: 297.w,
          child: Container(
            width: 79.w,
            height: 79.h,
            decoration: BoxDecoration(
              color: AppColors.kWhiteColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
