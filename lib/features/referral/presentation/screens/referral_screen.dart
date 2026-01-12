import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/referral/data/providers/referral_provider.dart';
import 'package:provider/provider.dart';
import 'referral_rules_screen.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReferralProvider>().fetchReferralCode();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(ConstColors.mainColor),
      body: SafeArea(
        child: Consumer<ReferralProvider>(
          builder: (context, referralProvider, child) {
            return Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(100.r),
                        ),
                        padding: EdgeInsets.all(10.w),
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Image.asset(
                            ConstImages.back,
                            width: 30.w,
                            height: 30.h,
                          ),
                        ),
                      ),
                      Text(
                        'Referral',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReferralRulesScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Rules',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 40.h),
                  Text(
                    'Invite new users and \nget a free ride',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 30.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                      letterSpacing: -0.41,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'Refer up to 10 friends and as soon as they \nplace a ride order, you get free ride for a nweek',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w400,
                      height: 1,
                      letterSpacing: 0,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  if (referralProvider.isLoading)
                    Container(
                      width: 350.w,
                      height: 157.h,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    )
                  else if (referralProvider.errorMessage != null)
                    Container(
                      width: 350.w,
                      height: 157.h,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Failed to load referral code',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            GestureDetector(
                              onTap: () {
                                referralProvider.fetchReferralCode();
                              },
                              child: Text(
                                'Tap to retry',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 350.w,
                      height: 157.h,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Invitation code',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              height: 1.0,
                              letterSpacing: 0,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 15.h),
                          Container(
                            width: 320.w,
                            height: 1.h,
                            color: Colors.white,
                          ),
                          SizedBox(height: 15.h),
                          GestureDetector(
                            onLongPress: () {
                              _copyToClipboard(
                                context,
                                referralProvider.referralData?.code ?? '',
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  referralProvider.referralData?.code ?? 'N/A',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 40.sp,
                                    fontWeight: FontWeight.w600,
                                    height: 1.0,
                                    letterSpacing: 0,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                GestureDetector(
                                  onTap: () {
                                    _copyToClipboard(
                                      context,
                                      referralProvider.referralData?.code ?? '',
                                    );
                                  },
                                  child: Icon(
                                    Icons.copy,
                                    color: Colors.white,
                                    size: 24.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 15.h),
                          Text(
                            'You are one step ahead of your friends 😎',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              height: 1.0,
                              letterSpacing: 0,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 20.h),
                  Container(
                    width: 353.w,
                    height: 154.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Total Invites',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          referralProvider.isLoading
                              ? '-'
                              : '${referralProvider.referralData?.totalUses ?? 0}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 80.sp,
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                            letterSpacing: -0.41,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Spacer(),
                  Container(
                    width: 353.w,
                    height: 47.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        if (!referralProvider.isLoading &&
                            referralProvider.referralData != null) {
                          referralProvider.shareReferralCode();
                        }
                      },
                      child: Center(
                        child: Text(
                          'Share link',
                          style: TextStyle(
                            color: Color(ConstColors.mainColor),
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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

  void _copyToClipboard(BuildContext context, String text) {
    if (text.isEmpty) return;

    Clipboard.setData(ClipboardData(text: text));
    CustomFlushbar.showInfo(
      context: context,
      message: 'Referral code copied to clipboard',
    );
  }
}
