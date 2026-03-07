import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/core/services/call_service.dart';
import 'package:muvam/core/services/global_call_service.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../widgets/call_button.dart';

class CallScreen extends StatefulWidget {
  final String driverName;
  final int rideId;
  final int? sessionId;

  const CallScreen({
    super.key,
    required this.driverName,
    required this.rideId,
    this.sessionId,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with WidgetsBindingObserver {
  CallService? _callService;
  String _callStatus = 'Connecting...';
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  Timer? _callTimer;
  int _callDuration = 0;
  int? _sessionId;
  bool _isCallActive = false;

  @override
  void initState() {
    super.initState();
    AppLogger.log('CallScreen initialized', tag: 'CALL_SCREEN');
    WakelockPlus.enable();
    GlobalCallService.instance.hideIncomingCall();
    WidgetsBinding.instance.addObserver(this);
    _requestPermissionsAndInitialize();
  }

  @override
  void dispose() {
    AppLogger.log('CallScreen disposed', tag: 'CALL_SCREEN');
    WidgetsBinding.instance.removeObserver(this);
    _callTimer?.cancel();
    _callService?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    AppLogger.log('App lifecycle state changed: $state', tag: 'CALL_SCREEN');
    if (state == AppLifecycleState.resumed) {
      AppLogger.log(
        'App resumed - call should still be active',
        tag: 'CALL_SCREEN',
      );
    }
  }

  Future<void> _endCallProperly() async {
    AppLogger.log('Ending call', tag: 'CALL_SCREEN');
    if (_sessionId != null && _sessionId! > 0) {
      await _callService?.endCall(_sessionId, _callDuration);
      AppLogger.log('CallService.endCall completed', tag: 'CALL_SCREEN');
    }
  }

  Future<void> _requestPermissionsAndInitialize() async {
    try {
      AppLogger.log('Requesting permissions', tag: 'CALL');
      final micStatus = await Permission.microphone.request();

      if (micStatus.isGranted) {
        AppLogger.log('Microphone permission granted', tag: 'CALL');
        await _initializeCall();
      } else if (micStatus.isDenied) {
        AppLogger.log('Microphone permission denied', tag: 'CALL');
        setState(() => _callStatus = 'Microphone permission required');
        _showPermissionDialog();
      } else if (micStatus.isPermanentlyDenied) {
        AppLogger.log('Microphone permission permanently denied', tag: 'CALL');
        setState(() => _callStatus = 'Permission denied');
        _showSettingsDialog();
      }
    } catch (e) {
      AppLogger.error('Permission request failed', error: e, tag: 'CALL');
      setState(() => _callStatus = 'Permission error');
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Microphone Permission Required'),
        content: const Text(
          'This app needs microphone access to make voice calls.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.pop();
              context.pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              context.pop();
              await _requestPermissionsAndInitialize();
            },
            child: const Text('Allow'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Please enable microphone permission in app settings to make calls.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.pop();
              context.pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await openAppSettings();
              if (mounted) context.pop();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeCall() async {
    try {
      AppLogger.log('Starting call initialization', tag: 'CALL');
      AppLogger.log('Driver: ${widget.driverName}', tag: 'CALL');
      AppLogger.log('Ride ID: ${widget.rideId}', tag: 'CALL');
      AppLogger.log('Session ID: ${widget.sessionId}', tag: 'CALL');

      _callService = CallService();
      final success = await _callService?.initialize();
      if (success != true) {
        AppLogger.error('CallService initialization failed', tag: 'CALL');
        setState(() => _callStatus = 'Initialization failed');
        return;
      }

      _callService?.onCallStateChanged = (state) {
        AppLogger.log('Call state changed to: $state', tag: 'CALL');
        if (!mounted) return;
        setState(() {
          _callStatus = state;
          if (state == 'Connected' && !_isCallActive) {
            _isCallActive = true;
            _startCallTimer();
            _callService?.stopRingtone();
          } else if (state == 'Call ended' || state == 'Call rejected') {
            _isCallActive = false;
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) context.pop();
            });
          }
        });
      };

      if (widget.sessionId != null) {
        AppLogger.log('Answering incoming call', tag: 'CALL');
        _sessionId = widget.sessionId;
        _callService?.setIncomingCallContext(_sessionId!, widget.rideId, null);
        GlobalCallService.instance.clearPendingMessages();
        await _callService?.answerCall(_sessionId!, widget.rideId);
      } else {
        AppLogger.log('Initiating call to driver', tag: 'CALL');
        final session = await _callService?.initiateCall(widget.rideId);
        if (session != null && session['session_id'] != null) {
          _sessionId = session['session_id'] is int
              ? session['session_id']
              : int.tryParse(session['session_id'].toString());
          AppLogger.log(
            'Call initiated - Session ID: $_sessionId',
            tag: 'CALL',
          );
        } else {
          AppLogger.log('No session ID received from server', tag: 'CALL');
          setState(() => _callStatus = 'Call initiation failed');
          return;
        }
      }

      setState(() => _callStatus = 'Ringing...');
    } catch (e) {
      AppLogger.error('Failed to initialize call', error: e, tag: 'CALL');
      setState(
        () => _callStatus =
            'Call Failed: There is an active call already for this ride',
      );
    }
  }

  void _startCallTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _callDuration++);
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _callService?.toggleMute(_isMuted);
  }

  Future<void> _toggleSpeaker() async {
    setState(() => _isSpeakerOn = !_isSpeakerOn);
    await _callService?.toggleSpeaker(_isSpeakerOn);
  }

  void _endCall() async {
    AppLogger.log('End call button pressed', tag: 'CALL_SCREEN');
    _callTimer?.cancel();
    await _endCallProperly();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _endCallProperly();
        return true;
      },
      child: AppScaffold(
        backgroundColor: AppColors.kWhiteColor,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
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
                            onTap: () async {
                              await _endCallProperly();
                              if (mounted) context.pop();
                            },
                            child: Icon(
                              Icons.arrow_back,
                              size: 20.sp,
                              color: AppColors.kBlackColor,
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          children: [
                            MuvamTexts.titleMedium18(
                              context,
                              text: widget.driverName,
                              isTextWidget: true,
                              center: true,
                            ),
                            SizedBox(height: 5.h),
                            Text(
                              _callStatus,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w400,
                                color: _isCallActive
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ),
                            if (_callDuration > 0) ...[
                              SizedBox(height: 5.h),
                              MuvamTexts.bodyLarge16(
                                context,
                                text: _formatDuration(_callDuration),
                                isTextWidget: true,
                                center: true,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 50.h),
                  Center(
                    child: SizedBox(
                      width: 200.w,
                      height: 200.h,
                      child: CircleAvatar(
                        radius: 100.r,
                        backgroundImage: AssetImage(ConstImages.avatar),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 353.w,
                    height: 72.h,
                    margin: EdgeInsets.only(
                      bottom: 49.h,
                      left: 20.w,
                      right: 20.w,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    decoration: BoxDecoration(
                      color: AppColors.kFormFieldColor,
                      borderRadius: BorderRadius.circular(25.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CallButton(
                          icon: Icons.chat,
                          iconColor: AppColors.kBlackColor,
                          onTap: () async {
                            await _endCallProperly();
                            if (mounted) context.pop();
                          },
                        ),
                        CallButton(
                          icon: _isSpeakerOn
                              ? Icons.volume_up
                              : Icons.volume_down,
                          iconColor: _isSpeakerOn
                              ? Colors.blue
                              : AppColors.kBlackColor,
                          onTap: _toggleSpeaker,
                        ),
                        CallButton(
                          icon: _isMuted ? Icons.mic_off : Icons.mic,
                          iconColor: _isMuted
                              ? Colors.red
                              : AppColors.kBlackColor,
                          onTap: _toggleMute,
                        ),
                        CallButton(
                          icon: Icons.call_end,
                          iconColor: AppColors.kWhiteColor,
                          onTap: _endCall,
                          isEndCall: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
