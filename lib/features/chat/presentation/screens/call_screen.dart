import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/images.dart';
import '../widgets/call_button.dart';

class CallScreen extends StatefulWidget {
  final String driverName;

  const CallScreen({super.key, required this.driverName});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 50.h),
            Stack(
              children: [
                Positioned(
                  left: 20.w,
                  child: Container(
                    width: 45.w,
                    height: 45.h,
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.arrow_back,
                        size: 20.sp,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    children: [
                      Text(
                        widget.driverName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w500,
                          height: 21 / 18,
                          letterSpacing: -0.32,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 5.h),
                      Text(
                        'Calling...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          height: 21 / 14,
                          letterSpacing: -0.32,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 50.h),
            Center(
              child: Container(
                width: 200.w,
                height: 200.h,
                child: CircleAvatar(
                  radius: 100.r,
                  backgroundImage: AssetImage(ConstImages.avatar),
                ),
              ),
            ),
            Spacer(),
            Container(
              width: 353.w,
              height: 72.h,
              margin: EdgeInsets.only(bottom: 49.h, left: 20.w, right: 20.w),
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              decoration: BoxDecoration(
                color: Color(0xFFF7F9F8),
                borderRadius: BorderRadius.circular(25.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CallButton(
                    icon: Icons.chat,
                    iconColor: Colors.black,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  CallButton(
                    icon: Icons.volume_up,
                    iconColor: Colors.black,
                    onTap: () {},
                  ),
                  CallButton(
                    icon: Icons.mic_off,
                    iconColor: Colors.black,
                    onTap: () {},
                  ),
                  CallButton(
                    icon: Icons.call_end,
                    iconColor: Colors.white,
                    onTap: () {
                      Navigator.pop(context);
                    },
                    isEndCall: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
