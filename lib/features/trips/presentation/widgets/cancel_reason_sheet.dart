import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/muvam_text.dart';

class CancelReasonSheet extends StatelessWidget {
  final int? selectedCancelReason;
  final Function(int) onReasonSelected;
  final VoidCallback onSubmit;

  const CancelReasonSheet({
    super.key,
    required this.selectedCancelReason,
    required this.onReasonSelected,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setCancelState) => Container(
        height: 450.h,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.kWhiteColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
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
            Align(
              alignment: Alignment.centerLeft,
              child: MuvamTexts.titleMedium18(
                context,
                text: 'Trip Canceled',
                isTextWidget: true,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10.h),
            Align(
              alignment: Alignment.centerLeft,
              child: MuvamTexts.bodyMedium14(
                context,
                text: 'Help us improve by sharing why you are canceling',
                isTextWidget: true,
              ),
            ),
            SizedBox(height: 30.h),
            _buildReason(
              0,
              'I am taking alternative transport',
              setCancelState,
              context,
            ),
            SizedBox(height: 10.h),
            _buildReason(
              1,
              'It is taking too long to get a driver',
              setCancelState,
              context,
            ),
            SizedBox(height: 10.h),
            _buildReason(
              2,
              'I have to attend to something',
              setCancelState,
              context,
            ),
            SizedBox(height: 10.h),
            _buildReason(3, 'Others', setCancelState, context),
            const Spacer(),
            GestureDetector(
              onTap: selectedCancelReason != null ? onSubmit : null,
              child: Container(
                width: double.infinity,
                height: 47.h,
                decoration: BoxDecoration(
                  color: selectedCancelReason != null
                      ? AppColors.kMainColor
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Center(
                  child: MuvamTexts.button16(
                    context,
                    text: 'Submit',
                    isTextWidget: true,
                    color: AppColors.kWhiteColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReason(
    int index,
    String reason,
    StateSetter setCancelState,
    BuildContext context,
  ) {
    final isSelected = selectedCancelReason == index;
    return GestureDetector(
      onTap: () {
        setCancelState(() => onReasonSelected(index));
      },
      child: Container(
        width: double.infinity,
        height: 40.h,
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.kMainColor : AppColors.kWhiteColor,
          border: Border.all(color: AppColors.kMainColor),
          borderRadius: BorderRadius.circular(15.r),
        ),
        child: Center(
          child: MuvamTexts.bodyMedium14(
            context,
            text: reason,
            isTextWidget: true,
            color: isSelected ? AppColors.kWhiteColor : AppColors.kBlackColor,
          ),
        ),
      ),
    );
  }
}
