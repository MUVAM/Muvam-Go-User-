import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/muvam_text.dart';

class FavoriteLocationItem extends StatelessWidget {
  final String name;
  final String address;
  final int id;
  final bool isFromFieldFocused;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const FavoriteLocationItem({
    super.key,
    required this.name,
    required this.address,
    required this.id,
    required this.isFromFieldFocused,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: _getIcon(),
          title: MuvamTexts.titleMedium18(
            context,
            text: name,
            isTextWidget: true,
            fontWeight: FontWeight.w600,
          ),
          subtitle: MuvamTexts.bodyMedium14(
            context,
            text: address,
            isTextWidget: true,
            color: Colors.grey,
          ),
          trailing: Icon(Icons.star, color: Colors.amber, size: 24.sp),
          onTap: onTap,
          onLongPress: onLongPress,
        ),
        Divider(thickness: 1, color: Colors.grey.shade300),
      ],
    );
  }

  Widget _getIcon() {
    final nameLower = name.toLowerCase();
    if (nameLower.contains('home')) {
      return Icon(Icons.home, size: 24.sp, color: Color(ConstColors.mainColor));
    } else if (nameLower.contains('work')) {
      return Icon(Icons.work, size: 24.sp, color: Color(ConstColors.mainColor));
    } else {
      return Icon(Icons.star, size: 24.sp, color: Colors.amber);
    }
  }
}
