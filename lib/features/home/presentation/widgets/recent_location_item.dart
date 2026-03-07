import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/features/trips/models/location_models.dart';

class RecentLocationItem extends StatelessWidget {
  final RecentLocation recent;
  final bool isFromFieldFocused;
  final VoidCallback onTap;

  const RecentLocationItem({
    super.key,
    required this.recent,
    required this.isFromFieldFocused,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Image.asset(
            ConstImages.locationPin,
            width: 24.w,
            height: 24.h,
          ),
          title: MuvamTexts.bodyMedium14(
            context,
            text: recent.name,
            isTextWidget: true,
            fontWeight: FontWeight.w500,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: MuvamTexts.bodySmall12(
            context,
            text: recent.address,
            isTextWidget: true,
            color: Colors.grey,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: onTap,
        ),
        Divider(thickness: 1, color: Colors.grey.shade300),
      ],
    );
  }
}
