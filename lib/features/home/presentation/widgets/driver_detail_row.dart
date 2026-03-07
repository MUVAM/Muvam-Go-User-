import 'package:flutter/material.dart';
import 'package:muvam/core/constants/muvam_text.dart';

class DriverDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const DriverDetailRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MuvamTexts.bodyLarge16(
          context,
          text: label,
          isTextWidget: true,
          fontWeight: FontWeight.w500,
        ),
        MuvamTexts.bodyLarge16(
          context,
          text: value,
          isTextWidget: true,
          fontWeight: FontWeight.w500,
        ),
      ],
    );
  }
}
