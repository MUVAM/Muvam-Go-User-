import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/app_spacings.dart';
import 'package:muvam/core/constants/muvam_text.dart';

class DeleteConfirmationSheet {
  static void show(BuildContext context, VoidCallback onDelete) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      isDismissible: true,
      enableDrag: true,
      builder: (context) => _DeleteConfirmationContent(
        onCancel: () => GoRouter.of(context).pop(),
        onDelete: () {
          context.pop();
          onDelete();
        },
      ),
    );
  }
}

class _DeleteConfirmationContent extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const _DeleteConfirmationContent({
    required this.onCancel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacings.k20),
      decoration: BoxDecoration(
        color: AppColors.kWhiteColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 69.w,
            height: 5.h,
            margin: EdgeInsets.only(bottom: 20.h),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2.5.r),
            ),
          ),
          MuvamTexts.titleMedium18(
            context,
            text: 'Delete Account',
            isTextWidget: true,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: 20.h),
          MuvamTexts.bodyMedium14(
            context,
            text:
                'Are you sure you want to delete your account? This action cannot be undone.',
            isTextWidget: true,
            center: true,
          ),
          SizedBox(height: 30.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 47.h,
                  decoration: BoxDecoration(
                    color: AppColors.kGreyColor,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8.r),
                      onTap: onCancel,
                      child: Center(
                        child: MuvamTexts.button16(
                          context,
                          text: 'Cancel',
                          isTextWidget: true,
                          color: AppColors.kWhiteColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Container(
                  height: 47.h,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8.r),
                      onTap: onDelete,
                      child: Center(
                        child: MuvamTexts.button16(
                          context,
                          text: 'Delete account',
                          isTextWidget: true,
                          color: AppColors.kWhiteColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
