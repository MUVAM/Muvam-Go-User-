import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/colors.dart';
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
            color: const Color(ConstColors.mainColor),
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
                    Text(
                      'Your balance',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                        letterSpacing: -0.32,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: onFundWallet,
                      child: Container(
                        width: 100.w,
                        height: 28.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add,
                              size: 14.sp,
                              color: const Color(ConstColors.mainColor),
                            ),
                            SizedBox(width: 3.w),
                            Text(
                              'Fund wallet',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w500,
                                color: const Color(ConstColors.mainColor),
                              ),
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
                  child: Text(
                    walletProvider.formatAmount(walletSummary.balance),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                      letterSpacing: -0.32,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                if (virtualAccount != null) ...[
                  Text(
                    virtualAccount.bankName,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                      letterSpacing: -0.32,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  GestureDetector(
                    onTap: onCopyAccountNumber,
                    child: Row(
                      children: [
                        Text(
                          virtualAccount.accountNumber,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Icon(Icons.copy, size: 14.sp, color: Colors.white),
                      ],
                    ),
                  ),
                ] else ...[
                  Text(
                    'No virtual account',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70,
                    ),
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
              color: Colors.white.withOpacity(0.12),
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
              color: Colors.white.withOpacity(0.12),
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
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
