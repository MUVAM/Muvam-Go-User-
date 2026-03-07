import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';

class CancelRideDialog extends StatelessWidget {
  final Function(String) onConfirm;

  const CancelRideDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();

    return AlertDialog(
      backgroundColor: AppColors.kWhiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: MuvamTexts.headlineSmall24(
        context,
        text: 'Cancel Ride',
        isTextWidget: true,
        fontWeight: FontWeight.w600,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MuvamTexts.bodyMedium14(
            context,
            text:
                'Please note that charges may apply if you cancel the ride now.',
            isTextWidget: true,
            color: Colors.red[700]!,
          ),
          SizedBox(height: 20.h),
          MuvamTexts.bodyMedium14(
            context,
            text: 'Please tell us why you want to cancel:',
            isTextWidget: true,
            fontWeight: FontWeight.w500,
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: reasonController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Enter your reason here...',
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.kMainColor, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.kMainColor, width: 2),
              ),
              filled: true,
              fillColor: AppColors.kWhiteColor,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            reasonController.dispose();
          },
          child: MuvamTexts.bodyLarge16(
            context,
            text: 'Back',
            isTextWidget: true,
            color: Colors.grey[600]!,
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            final reason = reasonController.text.trim();
            if (reason.isEmpty) {
              CustomFlushbar.showError(
                context: context,
                message: 'Please provide a reason for cancellation',
              );
              return;
            }
            Navigator.of(context).pop();
            onConfirm(reason);
            reasonController.dispose();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.kMainColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child: MuvamTexts.button16(
            context,
            text: 'Submit',
            isTextWidget: true,
            color: AppColors.kWhiteColor,
          ),
        ),
      ],
    );
  }
}
