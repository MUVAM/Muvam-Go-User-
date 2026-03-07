import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/core/utils/app_logger.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callerName;
  final String? callerImage;
  final int sessionId;
  final int rideId;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const IncomingCallScreen({
    super.key,
    required this.callerName,
    this.callerImage,
    required this.sessionId,
    required this.rideId,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final AudioPlayer _ringtonePlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _playRingtone();
  }

  Future<void> _playRingtone() async {
    try {
      _isPlaying = true;
      await _ringtonePlayer.setReleaseMode(ReleaseMode.loop);
      await _ringtonePlayer.setVolume(1.0);
      await _ringtonePlayer.play(AssetSource('sounds/calling.mp3'));
      AppLogger.log('Ringtone started playing', tag: 'INCOMING_CALL');
    } catch (e) {
      AppLogger.error(
        'Failed to play ringtone',
        error: e,
        tag: 'INCOMING_CALL',
      );
    }
  }

  Future<void> _stopRingtone() async {
    if (_isPlaying) {
      await _ringtonePlayer.stop();
      _isPlaying = false;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _stopRingtone();
    _ringtonePlayer.dispose();
    super.dispose();
  }

  void _handleAccept() async {
    await _stopRingtone();
    widget.onAccept();
  }

  void _handleReject() async {
    await _stopRingtone();
    widget.onReject();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 80.h),
              MuvamTexts.headlineMedium28(
                context,
                text: widget.callerName,
                isTextWidget: true,
                fontWeight: FontWeight.w600,
                color: AppColors.kWhiteColor,
                center: true,
              ),
              SizedBox(height: 10.h),
              MuvamTexts.bodyLarge16(
                context,
                text: 'Incoming call...',
                isTextWidget: true,
                color: Colors.white70,
              ),
              SizedBox(height: 60.h),
              Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) => Container(
                      width: 220.w * _pulseAnimation.value,
                      height: 220.h * _pulseAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.kWhiteColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) => Container(
                      width: 200.w * (2.0 - _pulseAnimation.value),
                      height: 200.h * (2.0 - _pulseAnimation.value),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.kWhiteColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 160.w,
                    height: 160.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.kWhiteColor,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child:
                          widget.callerImage != null &&
                              widget.callerImage!.isNotEmpty
                          ? Image.network(
                              widget.callerImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset(
                                ConstImages.avatar,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(ConstImages.avatar, fit: BoxFit.cover),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        GestureDetector(
                          onTap: _handleReject,
                          child: Container(
                            width: 70.w,
                            height: 70.h,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.call_end,
                              color: AppColors.kWhiteColor,
                              size: 35.sp,
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        MuvamTexts.bodyMedium14(
                          context,
                          text: 'Decline',
                          isTextWidget: true,
                          fontWeight: FontWeight.w500,
                          color: AppColors.kWhiteColor,
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) => Transform.scale(
                            scale: _pulseAnimation.value,
                            child: GestureDetector(
                              onTap: _handleAccept,
                              child: Container(
                                width: 70.w,
                                height: 70.h,
                                decoration: BoxDecoration(
                                  color: AppColors.kMainColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.kMainColor.withOpacity(
                                        0.6,
                                      ),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.call,
                                  color: AppColors.kWhiteColor,
                                  size: 35.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        MuvamTexts.bodyMedium14(
                          context,
                          text: 'Accept',
                          isTextWidget: true,
                          fontWeight: FontWeight.w500,
                          color: AppColors.kWhiteColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 80.h),
            ],
          ),
        ),
      ),
    );
  }
}
