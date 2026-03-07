import 'package:flutter/material.dart';
import 'package:muvam/core/constants/muvam_text.dart';

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return MuvamTexts.titleLarge22(
      context,
      text: title,
      isTextWidget: true,
      fontWeight: FontWeight.w700,
    );
  }
}
