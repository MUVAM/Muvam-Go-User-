import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/auth/data/providers/%20delete_account_provider.dart';
import 'package:muvam/features/auth/presentation/screens/onboarding_screen.dart';
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
    'Others',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<DeleteAccountProvider>(
          builder: (context, deleteProvider, child) {
            return Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Image.asset(
                          ConstImages.back,
                          width: 30.w,
                          height: 30.h,
                        ),
                      ),
                      SizedBox(width: 15.w),
                      Text(
                        'Delete Account',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30.h),
                  Text(
                    'We\'re really sorry to see you go 😢 Are you sure you want to delete your account? Once you confirm, your data will be gone.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      height: 1.0,
                      letterSpacing: -0.41,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 30.h),
                  Expanded(
                    child: ListView.builder(
                      itemCount: reasons.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedReason = index;
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 15.h),
                            child: Row(
                              children: [
                                Container(
                                  width: 20.w,
                                  height: 20.h,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: selectedReason == index
                                          ? Color(ConstColors.mainColor)
                                          : Colors.grey,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(3.r),
                                  ),
                                  child: selectedReason == index
                                      ? Icon(
                                          Icons.check,
                                          size: 14.sp,
                                          color: Color(ConstColors.mainColor),
                                        )
                                      : null,
                                ),
                                SizedBox(width: 15.w),
                                Expanded(
                                  child: Text(
                                    reasons[index],
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w400,
                                      height: 1.0,
                                      letterSpacing: -0.41,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    width: 353.w,
                    height: 47.h,
                    decoration: BoxDecoration(
                      color: deleteProvider.isDeleting
                          ? Colors.grey
                          : Colors.red,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8.r),
                        onTap: deleteProvider.isDeleting
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
                        child: Center(
                          child: deleteProvider.isDeleting
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.h,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Delete my account',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
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

  void _showDeleteConfirmationSheet() {
    DeleteConfirmationSheet.show(context, () async {
      await Future.delayed(Duration(milliseconds: 100));
      if (mounted) {
        _deleteAccount();
      }
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

      await Future.delayed(Duration(seconds: 2));

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        (route) => false,
      );
    } else {
      CustomFlushbar.showError(
        context: context,
        message: deleteProvider.errorMessage ?? 'Failed to delete account',
      );
    }
  }
}
