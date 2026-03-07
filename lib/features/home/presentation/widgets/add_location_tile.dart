import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/muvam_text.dart';

class AddLocationTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const AddLocationTile({super.key, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Image.asset(ConstImages.add, width: 24.w, height: 24.h),
          title: MuvamTexts.titleMedium18(
            context,
            text: title,
            isTextWidget: true,
            fontWeight: FontWeight.w700,
          ),
          onTap: onTap,
        ),
        Divider(thickness: 1, color: Colors.grey.shade300),
      ],
    );
  }
}
