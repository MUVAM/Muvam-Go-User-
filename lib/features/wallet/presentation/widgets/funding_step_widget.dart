import 'package:flutter/material.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/muvam_text.dart';

class FundingStepWidget extends StatelessWidget {
  final String number;
  final String text;

  const FundingStepWidget({
    super.key,
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MuvamTexts.bodySmall12(
          context,
          text: number,
          color: AppColors.kBlackColor,
        ),
        Expanded(
          child: MuvamTexts.bodySmall12(
            context,
            text: text,
            color: AppColors.kBlackColor,
          ),
        ),
      ],
    );
  }
}
