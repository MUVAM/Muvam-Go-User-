import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/colors.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String time;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 10.h,
          left: isMe ? 50.w : 0,
          right: isMe ? 0 : 50.w,
        ),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isMe
              ? Color(ConstColors.mainColor)
              : Color(0xFFB1B1B1).withOpacity(0.5),
          borderRadius: BorderRadius.only(
            topLeft: isMe ? Radius.circular(5.r) : Radius.circular(0),
            topRight: isMe ? Radius.circular(0) : Radius.circular(5.r),
            bottomRight: Radius.circular(5.r),
            bottomLeft: Radius.circular(5.r),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: isMe ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 5.h),
            Text(
              time,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 8.sp,
                fontWeight: FontWeight.w500,
                height: 1.0,
                letterSpacing: -0.32,
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
