import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/services/call_service.dart';
import 'package:muvam/core/utils/app_logger.dart';
import '../widgets/call_button.dart';
import 'dart:async';

class CallScreen extends StatefulWidget {
  final String driverName;
  final int rideId;

  const CallScreen({super.key, required this.driverName, required this.rideId});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late CallService _callService;
  String _callStatus = 'Connecting...';
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  Timer? _callTimer;
  int _callDuration = 0;
  int? _sessionId;
  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _callService.endCall(_sessionId, _callDuration);
    _callService.dispose();
    super.dispose();
  }

  void _initializeCall() async {
    try {
      _callService = CallService();
      await _callService.initialize();
      
      final session = await _callService.initiateCall(widget.rideId);
      _sessionId = session['session_id'];
      
      setState(() {
        _callStatus = 'Calling ${widget.driverName}...';
      });

      _callService.onCallStateChanged = (state) {
        setState(() {
          _callStatus = state;
          if (state == 'Connected') {
            _startCallTimer();
          }
        });
      };

    } catch (e) {
      AppLogger.error('Failed to initialize call', error: e, tag: 'CALL');
      setState(() {
        _callStatus = 'Call failed';
      });
    }
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration++;
      });
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _callService.toggleMute(_isMuted);
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    _callService.toggleSpeaker(_isSpeakerOn);
  }

  void _endCall() {
    _callTimer?.cancel();
    _callService.endCall(_sessionId, _callDuration);
    Navigator.pop(context);
  }

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
                        _callStatus,
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
                      if (_callDuration > 0) ...{
                        SizedBox(height: 5.h),
                        Text(
                          _formatDuration(_callDuration),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      },
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
                    icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                    iconColor: _isSpeakerOn ? Colors.blue : Colors.black,
                    onTap: _toggleSpeaker,
                  ),
                  CallButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    iconColor: _isMuted ? Colors.red : Colors.black,
                    onTap: _toggleMute,
                  ),
                  CallButton(
                    icon: Icons.call_end,
                    iconColor: Colors.white,
                    onTap: _endCall,
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
