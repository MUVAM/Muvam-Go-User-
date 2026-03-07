import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/core/services/places_service.dart';

class LocationSuggestionsList extends StatelessWidget {
  final List<PlacePrediction> suggestions;
  final Function(PlacePrediction) onSelect;

  const LocationSuggestionsList({
    super.key,
    required this.suggestions,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: suggestions.length,
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: Colors.grey.shade200),
      itemBuilder: (context, index) {
        final prediction = suggestions[index];
        return ListTile(
          dense: true,
          leading: SvgPicture.asset(
            ConstImages.location,
            width: 20.w,
            height: 20.h,
            color: Colors.grey,
            fit: BoxFit.scaleDown,
          ),
          title: MuvamTexts.bodyMedium14(
            context,
            text: prediction.mainText,
            isTextWidget: true,
            fontWeight: FontWeight.w600,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: prediction.secondaryText.isNotEmpty
              ? MuvamTexts.bodySmall12(
                  context,
                  text: prediction.secondaryText,
                  isTextWidget: true,
                  color: Colors.grey[600],
                )
              : null,
          trailing: prediction.distance != null
              ? MuvamTexts.bodySmall12(
                  context,
                  text: prediction.distance!,
                  isTextWidget: true,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                )
              : null,
          onTap: () => onSelect(prediction),
        );
      },
    );
  }
}
