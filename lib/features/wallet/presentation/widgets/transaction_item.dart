import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/muvam_text.dart';

class TransactionItem extends StatelessWidget {
  final String amount;
  final String dateTime;
  final String status;
  final Color statusColor;

  const TransactionItem({
    super.key,
    required this.amount,
    required this.dateTime,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MuvamTexts.titleMedium18(
              context,
              text: amount,
              fontWeight: FontWeight.w600,
              color: AppColors.kBlackColor,
            ),
            SizedBox(height: 2.h),
            MuvamTexts.bodySmall12(
              context,
              text: dateTime,
              color: AppColors.kGreyColor,
            ),
          ],
        ),
        MuvamTexts.titleSmall14(
          context,
          text: status,
          fontWeight: FontWeight.w500,
          color: statusColor,
        ),
      ],
    );
  }
}
