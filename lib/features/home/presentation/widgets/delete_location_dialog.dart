import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/muvam_text.dart';

class DeleteLocationDialog extends StatelessWidget {
  final String locationType;
  final int locationId;
  final VoidCallback onDelete;

  const DeleteLocationDialog({
    super.key,
    required this.locationType,
    required this.locationId,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: AppColors.kWhiteColor,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MuvamTexts.titleMedium18(
              context,
              text: 'Remove from $locationType?',
              isTextWidget: true,
              fontWeight: FontWeight.w600,
              color: AppColors.kBlackColor,
              center: true,
            ),
            SizedBox(height: 8.h),
            MuvamTexts.bodyMedium14(
              context,
              text:
                  'This location will be removed from your $locationType. You can add it again anytime.',
              isTextWidget: true,
              fontWeight: FontWeight.w400,
              color: AppColors.kBlackColor,
              center: true,
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      height: 47.h,
                      decoration: BoxDecoration(
                        color: Color(0xffB1B1B1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
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
                SizedBox(width: 12.w),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      context.pop();
                      onDelete();
                    },
                    child: Container(
                      height: 47.h,
                      decoration: BoxDecoration(
                        color: Color(ConstColors.mainColor),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: MuvamTexts.button16(
                          context,
                          text: 'Remove',
                          isTextWidget: true,
                          color: AppColors.kWhiteColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
