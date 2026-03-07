import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/app_routes.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/features/wallet/data/providers/wallet_provider.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletEmptyScreen extends StatefulWidget {
  const WalletEmptyScreen({super.key});

  @override
  State<WalletEmptyScreen> createState() => _WalletEmptyScreenState();
}

class _WalletEmptyScreenState extends State<WalletEmptyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final provider = context.read<WalletProvider>();
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        debugPrint('Auth token: ${token != null ? 'exists' : 'null'}');
        await provider.fetchWalletSummary();
      } catch (e, stack) {
        debugPrint('Error in WalletEmptyScreen initState: $e\n$stack');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
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
                    onTap: () {
                      if (context.canPop()) context.pop();
                    },
                    child: Image.asset(
                      ConstImages.back,
                      width: 33.w,
                      height: 33.h,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.pushNamed(AppRoutes.howToFund.name),
                    child: MuvamTexts.bodyLarge16(
                      context,
                      text: 'How to fund?',
                      isTextWidget: true,
                      color: AppColors.kMainColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              MuvamTexts.headlineSmall24(
                context,
                text: 'Wallet',
                isTextWidget: true,
              ),
              SizedBox(height: 20.h),
              Stack(
                children: [
                  Container(
                    width: 353.w,
                    height: 120.h,
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
                              MuvamTexts.bodyMedium14(
                                context,
                                text: 'Your balance',
                                isTextWidget: true,
                                color: AppColors.kWhiteColor,
                                fontWeight: FontWeight.w500,
                              ),
                              GestureDetector(
                                onTap: () => context.pushNamed(
                                  AppRoutes.getAccount.name,
                                ),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 8.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.kWhiteColor,
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: MuvamTexts.bodySmall12(
                                    context,
                                    text: 'Get Account',
                                    isTextWidget: true,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: MuvamTexts.headlineLarge32(
                              context,
                              text: '₦0',
                              isTextWidget: true,
                              color: AppColors.kWhiteColor,
                            ),
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
                        color: AppColors.kWhiteColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 50.h,
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
                ],
              ),
              SizedBox(height: 15.h),
              MuvamTexts.bodySmall12(
                context,
                text:
                    'Transfer to this account to instantly fund your Muvam wallet',
                center: true,
                isTextWidget: true,
                fontWeight: FontWeight.w500,
              ),
              SizedBox(height: 30.h),
              MuvamTexts.titleMedium18(
                context,
                text: 'Transaction history',
                isTextWidget: true,
                fontWeight: FontWeight.w600,
              ),
              SizedBox(height: 40.h),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      ConstImages.walletIcon,
                      width: 120.w,
                      height: 120.h,
                    ),
                    SizedBox(height: 20.h),
                    MuvamTexts.bodyMedium14(
                      context,
                      text:
                          "You don't have any transaction yet.\nOnce you start funding, they'll\nappear here",
                      center: true,
                      isTextWidget: true,
                      color: Colors.grey.shade500,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
