import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/core/services/places_service.dart';

class PredictionsList extends StatelessWidget {
  final List<PlacePrediction> predictions;
  final Function(PlacePrediction) onPredictionSelected;

  const PredictionsList({
    super.key,
    required this.predictions,
    required this.onPredictionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: 200.h),
      decoration: BoxDecoration(
        color: AppColors.kWhiteColor,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: predictions.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: AppColors.kGreyColor.withOpacity(0.2)),
        itemBuilder: (context, index) {
          final prediction = predictions[index];
          return ListTile(
            dense: true,
            leading: Icon(
              Icons.location_on,
              size: 20.sp,
              color: AppColors.kGreyColor,
            ),
            title: MuvamTexts.bodyMedium14(
              context,
              text: prediction.mainText,
              fontWeight: FontWeight.w600,
              color: AppColors.kBlackColor,
            ),
            subtitle: prediction.secondaryText.isNotEmpty
                ? MuvamTexts.bodySmall12(
                    context,
                    text: prediction.secondaryText,
                    color: AppColors.kSubtitleColor,
                  )
                : null,
            onTap: () => onPredictionSelected(prediction),
          );
        },
      ),
    );
  }
}
