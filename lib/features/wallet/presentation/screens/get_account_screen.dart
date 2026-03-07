import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/app_routes.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/wallet/data/providers/wallet_provider.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';
import 'package:muvam/layouts/presentation/shared/bottom_padding.dart';
import 'package:provider/provider.dart';

class GetAccountScreen extends StatefulWidget {
  const GetAccountScreen({super.key});

  @override
  State<GetAccountScreen> createState() => _GetAccountScreenState();
}

class _GetAccountScreenState extends State<GetAccountScreen> {
  final TextEditingController bvnController = TextEditingController();

  @override
  void dispose() {
    bvnController.dispose();
    super.dispose();
  }

  bool _isFormValid() => bvnController.text.length == 11;

  void _handleVerify() async {
    if (!_isFormValid()) return;

    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    walletProvider.clearError();

    final success = await walletProvider.createVirtualAccount(
      bvn: bvnController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      context.pushReplacementNamed(AppRoutes.accountCreated.name);
    } else {
      CustomFlushbar.showError(
        context: context,
        message:
            walletProvider.errorMessage ?? 'Failed to create virtual account',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        return AppScaffold(
          backgroundColor: AppColors.kWhiteColor,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: SvgPicture.asset(
                            ConstImages.arrowLeftAlt,
                            fit: BoxFit.contain,
                            color: AppColors.kBlackColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MuvamTexts.headlineSmall24(
                            context,
                            text: 'Get an account',
                            isTextWidget: true,
                            center: true,
                          ),
                          MuvamTexts.bodySmall12(
                            context,
                            text:
                                'Enter your BVN to create your\npersonal wallet',
                            center: true,
                            isTextWidget: true,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                      const Spacer(),
                    ],
                  ),
                  SizedBox(height: 40.h),
                  MuvamTexts.titleSmall14(
                    context,
                    text: 'Bank Verification Number (BVN)',
                    isTextWidget: true,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: bvnController,
                    keyboardType: TextInputType.number,
                    maxLength: 11,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Enter your BVN',
                      hintStyle: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[400],
                      ),
                      filled: true,
                      fillColor: AppColors.kFormFieldColor,
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: const BorderSide(
                          color: AppColors.kMainColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.kMainColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MuvamTexts.bodySmall12(
                          context,
                          text:
                              'Note: We only collect your BVN to generate a wallet account for you and it is totally optional.',
                          isTextWidget: true,
                          color: AppColors.kMainColor,
                        ),
                        SizedBox(height: 8.h),
                        MuvamTexts.bodySmall12(
                          context,
                          text:
                              'Your BVN is totally safe and will never be disclosed.',
                          isTextWidget: true,
                          color: AppColors.kMainColor,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _isFormValid() && !walletProvider.isLoading
                        ? _handleVerify
                        : null,
                    child: Container(
                      width: double.infinity,
                      height: 47.h,
                      decoration: BoxDecoration(
                        color: _isFormValid() && !walletProvider.isLoading
                            ? AppColors.kMainColor
                            : AppColors.kFieldColor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: MuvamTexts.button16(
                          context,
                          text: 'Verify',
                          isTextWidget: true,
                          color: AppColors.kWhiteColor,
                        ),
                      ),
                    ),
                  ),
                  DeviceBottomPadding(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
