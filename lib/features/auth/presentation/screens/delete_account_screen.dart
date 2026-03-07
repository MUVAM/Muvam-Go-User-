import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/app_routes.dart';
import 'package:muvam/core/constants/app_spacings.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/auth/data/providers/%20delete_account_provider.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';
import 'package:muvam/layouts/presentation/shared/bottom_padding.dart';
import 'package:provider/provider.dart';
import '../widgets/delete_confirmation_sheet.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  DeleteAccountScreenState createState() => DeleteAccountScreenState();
}

class DeleteAccountScreenState extends State<DeleteAccountScreen> {
  int? selectedReason;

  final List<String> reasons = [
    'I am no longer using my account',
    'It is not available in my state',
    'I want to change my phone number',
    'It is too expensive',
    'I just bought a car',
    'No reason',
    'Others',
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: SafeArea(
        child: Consumer<DeleteAccountProvider>(
          builder: (context, deleteProvider, child) {
            return Padding(
              padding: EdgeInsets.all(AppSpacings.k20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 40.w,
                            height: 40.h,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF5F5F5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_back,
                              color: AppColors.kBlackColor,
                              size: 20.sp,
                            ),
                          ),
                        ),
                      ),
                      MuvamTexts.titleLarge22(
                        context,
                        text: 'Delete Account',
                        isTextWidget: true,
                        fontWeight: FontWeight.w700,
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.sp,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                      children: const [
                        TextSpan(text: "We're really sorry to see you go "),
                        TextSpan(text: '🥹'),
                        TextSpan(
                          text:
                              ' Are you sure you want to delete your account? Once you confirm, your data will be gone.',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Expanded(
                    child: ListView.separated(
                      itemCount: reasons.length,
                      separatorBuilder: (_, __) => Divider(
                        thickness: 1,
                        color: Colors.grey.shade200,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final isSelected = selectedReason == index;
                        return GestureDetector(
                          onTap: () => setState(() => selectedReason = index),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            child: Row(
                              children: [
                                Container(
                                  width: 20.w,
                                  height: 20.h,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.kMainColor
                                          : Colors.grey.shade400,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(4.r),
                                    color: isSelected
                                        ? AppColors.kMainColor.withOpacity(0.05)
                                        : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? Icon(
                                          Icons.check,
                                          size: 13.sp,
                                          color: AppColors.kMainColor,
                                        )
                                      : null,
                                ),
                                SizedBox(width: 14.w),
                                Expanded(
                                  child: MuvamTexts.bodyLarge16(
                                    context,
                                    text: reasons[index],
                                    isTextWidget: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    height: 47.h,
                    child: ElevatedButton(
                      onPressed: deleteProvider.isDeleting
                          ? null
                          : () {
                              if (selectedReason == null) {
                                CustomFlushbar.showInfo(
                                  context: context,
                                  message: 'Please select a reason',
                                );
                                return;
                              }
                              _showDeleteConfirmationSheet();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: deleteProvider.isDeleting
                            ? Colors.grey
                            : const Color(0xFFEF5350),
                        disabledBackgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        elevation: 0,
                      ),
                      child: deleteProvider.isDeleting
                          ? SizedBox(
                              width: 20.w,
                              height: 20.h,
                              child: const CircularProgressIndicator(
                                color: AppColors.kWhiteColor,
                                strokeWidth: 2,
                              ),
                            )
                          : MuvamTexts.button16(
                              context,
                              text: 'Delete account',
                              isTextWidget: true,
                              color: AppColors.kWhiteColor,
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

  void _showDeleteConfirmationSheet() {
    DeleteConfirmationSheet.show(context, () async {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) _deleteAccount();
    });
  }

  Future<void> _deleteAccount() async {
    final deleteProvider = context.read<DeleteAccountProvider>();
    final reason = reasons[selectedReason!];
    final success = await deleteProvider.deleteAccount(reason);

    if (!mounted) return;

    if (success) {
      CustomFlushbar.showSuccess(
        context: context,
        message:
            deleteProvider.successMessage ?? 'Account deleted successfully',
      );
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      context.goNamed(AppRoutes.onboarding.name);
    } else {
      CustomFlushbar.showError(
        context: context,
        message: deleteProvider.errorMessage ?? 'Failed to delete account',
      );
    }
  }
}
