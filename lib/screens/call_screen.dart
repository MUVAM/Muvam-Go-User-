import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/images.dart';

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
            // Header with back button and centered driver info
            Stack(
              children: [
                // Back button on the left
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
                // Centered driver name and status
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

            // Centered Driver Image
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

            // Control Buttons
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
                  _buildCallButton(Icons.chat, Colors.black, () {
                    Navigator.pop(context);
                  }),
                  _buildCallButton(Icons.volume_up, Colors.black, () {}),
                  _buildCallButton(Icons.mic_off, Colors.black, () {}),
                  _buildCallButton(Icons.call_end, Colors.white, () {
                    Navigator.pop(context);
                  }, isEndCall: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton(
    IconData icon,
    Color iconColor,
    VoidCallback onTap, {
    bool isEndCall = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38.w,
        height: 38.h,
        decoration: BoxDecoration(
          color: isEndCall ? Colors.red : Colors.transparent,
          borderRadius: isEndCall ? BorderRadius.circular(200.r) : null,
        ),
        child: Icon(
          icon,
          size: 38.sp,
          color: isEndCall ? Colors.white : iconColor,
        ),
      ),
    );
  }
}
