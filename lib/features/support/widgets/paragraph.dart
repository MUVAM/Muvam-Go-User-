import 'package:flutter/material.dart';
import 'package:muvam/core/constants/muvam_text.dart';

class Paragraph extends StatelessWidget {
  final String text;

  const Paragraph({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return MuvamTexts.bodyMedium14(
      context,
      text: text,
      isTextWidget: true,
      color: Colors.grey[700]!,
      center: false,
    );
  }
}
