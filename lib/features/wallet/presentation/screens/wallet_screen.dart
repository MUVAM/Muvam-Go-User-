import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/features/wallet/presentation/widgets/fund_wallet_sheet.dart';
import 'package:muvam/features/wallet/presentation/widgets/transaction_item.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = [
      {
        'amount': '₦500',
        'dateTime': 'Dec 15, 2024 • 2:30 PM',
        'status': 'Successful',
        'color': Colors.green,
      },
      {
        'amount': '₦1,200',
        'dateTime': 'Dec 14, 2024 • 10:15 AM',
        'status': 'Failed',
        'color': Colors.red,
      },
      {
        'amount': '₦800',
        'dateTime': 'Dec 13, 2024 • 6:45 PM',
        'status': 'Successful',
        'color': Colors.green,
      },
      {
        'amount': '₦2,000',
        'dateTime': 'Dec 12, 2024 • 1:20 PM',
        'status': 'Successful',
        'color': Colors.green,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset(
                      ConstImages.back,
                      width: 24.w,
                      height: 24.h,
                    ),
                  ),
                  Text(
                    'How to fund',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                      letterSpacing: -0.32,
                      color: Color(ConstColors.mainColor),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Text(
                'Wallet',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                  letterSpacing: -0.32,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 20.h),
              Stack(
                children: [
                  Container(
                    width: 353.w,
                    height: 147.h,
                    decoration: BoxDecoration(
                      color: Color(ConstColors.mainColor),
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
                                onTap: () => FundWalletSheet.show(context),
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
                                        color: Color(ConstColors.mainColor),
                                      ),
                                      SizedBox(width: 3.w),
                                      Text(
                                        'Fund wallet',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w500,
                                          color: Color(ConstColors.mainColor),
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
                              '₦1,000',
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
                          Text(
                            'Paystack - Wema Bank',
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
                          Row(
                            children: [
                              Text(
                                '1234567890',
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
                              Icon(
                                Icons.copy,
                                size: 14.sp,
                                color: Colors.white,
                              ),
                            ],
                          ),
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
              ),
              SizedBox(height: 15.h),
              Center(
                child: Text(
                  'Transfer to this account to instantly fund your Muvam wallet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                    letterSpacing: -0.32,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 30.h),
              Text(
                'Transaction History',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 20.h),
              Expanded(
                child: ListView.separated(
                  itemCount: transactions.length,
                  separatorBuilder: (context, index) =>
                      Divider(thickness: 1, color: Colors.grey.shade300),
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return TransactionItem(
                      amount: transaction['amount'] as String,
                      dateTime: transaction['dateTime'] as String,
                      status: transaction['status'] as String,
                      statusColor: transaction['color'] as Color,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
