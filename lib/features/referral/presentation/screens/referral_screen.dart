import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/app_routes.dart';
import 'package:muvam/core/constants/app_spacings.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/features/referral/data/providers/referral_provider.dart';
import 'package:muvam/features/referral/presentation/widgets/code_card.dart';
import 'package:muvam/features/referral/presentation/widgets/error_card.dart';
import 'package:muvam/features/referral/presentation/widgets/total_invites_card.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';
import 'package:muvam/layouts/presentation/shared/bottom_padding.dart';
import 'package:provider/provider.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() async {
    final referralProvider = context.read<ReferralProvider>();
    final hasData = referralProvider.referralData != null;

    if (hasData && !_hasLoadedOnce) {
      setState(() => _hasLoadedOnce = true);
      referralProvider.fetchReferralCode();
    } else if (!hasData) {
      await referralProvider.fetchReferralCode();
      if (mounted) setState(() => _hasLoadedOnce = true);
    } else {
      referralProvider.fetchReferralCode();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kMainColor,
      body: SafeArea(
        child: Consumer<ReferralProvider>(
          builder: (context, referralProvider, child) {
            final shouldShowLoader =
                !_hasLoadedOnce &&
                referralProvider.referralData == null &&
                referralProvider.isLoading;

            return shouldShowLoader
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.kWhiteColor,
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacings.k20),
                    child: Column(
                      children: [
                        SizedBox(height: 16.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 35.w,
                              height: 35.h,
                              decoration: BoxDecoration(
                                color: AppColors.kWhiteColor,
                                borderRadius: BorderRadius.circular(100.r),
                              ),
                              padding: EdgeInsets.all(5.w),
                              child: GestureDetector(
                                onTap: () => context.pop(),
                                child: SvgPicture.asset(
                                  ConstImages.arrowLeftAlt,
                                  fit: BoxFit.contain,
                                  color: AppColors.kBlackColor,
                                ),
                              ),
                            ),
                            MuvamTexts.titleLarge22(
                              context,
                              text: 'Referral',
                              isTextWidget: true,
                              fontWeight: FontWeight.w600,
                              color: AppColors.kWhiteColor,
                            ),
                            GestureDetector(
                              onTap: () {
                                context.pushNamed(AppRoutes.referralRules.name);
                              },
                              child: MuvamTexts.bodyLarge16(
                                context,
                                text: 'Rules',
                                isTextWidget: true,
                                fontWeight: FontWeight.w500,
                                color: AppColors.kWhiteColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 40.h),
                        MuvamTexts.headlineMedium28(
                          context,
                          text: 'Invite new users and \nget a free ride',
                          isTextWidget: true,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          color: AppColors.kWhiteColor,
                          center: true,
                        ),
                        SizedBox(height: 20.h),
                        MuvamTexts.bodyLarge16(
                          context,
                          text:
                              'Refer up to 10 friends and as soon as they \nplace a ride order, you get free ride for a week',
                          isTextWidget: true,
                          color: AppColors.kWhiteColor,
                          center: true,
                        ),
                        SizedBox(height: 24.h),
                        if (referralProvider.errorMessage != null &&
                            referralProvider.referralData == null)
                          ErrorCard(onRetry: referralProvider.fetchReferralCode)
                        else
                          CodeCard(
                            code: referralProvider.referralData?.code,
                            onCopy: () {},
                          ),
                        SizedBox(height: 20.h),
                        TotalInvitesCard(
                          totalInvites:
                              referralProvider.referralData?.totalUses ?? 0,
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            if (referralProvider.referralData != null) {
                              referralProvider.shareReferralCode();
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            height: 47.h,
                            decoration: BoxDecoration(
                              color: AppColors.kWhiteColor,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Center(
                              child: MuvamTexts.button16(
                                context,
                                text: 'Share link',
                                isTextWidget: true,
                                color: AppColors.kMainColor,
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
