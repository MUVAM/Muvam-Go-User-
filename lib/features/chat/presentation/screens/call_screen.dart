import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/services/call_service.dart';
import 'package:muvam/core/services/globalCallService.dart';
import 'package:muvam/core/utils/app_logger.dart';
// import 'package:muvam/features/services/globalincomingcall.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../widgets/call_button.dart';

class CallScreen extends StatefulWidget {
  final String driverName;
  final int rideId;
  final int? sessionId; // Session ID for answering incoming calls

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
    AppLogger.log('🚀 CallScreen initialized', tag: 'CALL_SCREEN');

    // Ensure screen stays on during call
    WakelockPlus.enable();

    // Safety: Stop any global ringtone that might still be playing
    GlobalCallService.instance.hideIncomingCall(); // This also stops ringtone

    WidgetsBinding.instance.addObserver(this);
    _requestPermissionsAndInitialize();
  }

  @override
  void dispose() {
    AppLogger.log(
      '🗑️🗑️🗑️ DISPOSE CALLED ON CALL SCREEN 🗑️🗑️🗑️',
      tag: 'CALL_SCREEN',
    );
    WidgetsBinding.instance.removeObserver(this);
    _callTimer?.cancel();
    AppLogger.log(
      '📤 Calling _endCallProperly() from dispose',
      tag: 'CALL_SCREEN',
    );
    // Note: _endCallProperly is async, but dispose is sync.
    // We can't await it here. The service dispose() cleans up engine.
    _callService?.dispose();
    WakelockPlus.disable();
    super.dispose();
    AppLogger.log('✅ Call screen disposed', tag: 'CALL_SCREEN');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    AppLogger.log('📱 App lifecycle state changed: $state', tag: 'CALL_SCREEN');

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      AppLogger.log(
        '⚠️⚠️⚠️ APP GOING TO BACKGROUND/CLOSING ⚠️⚠️⚠️',
        tag: 'CALL_SCREEN',
      );
      // We might not want to end call on background for Agora (audio continues).
      // But keeping logic consistent with previous behavior:

      // _endCallProperly();
      // User might want to keep call alive in background?
      // Usually audio calls should persist.
      // Previous logic ended it. I will keep it commented out or respect previous logic if critical.
      // Previous logic: _endCallProperly();
      // I will leave it as is if it was ending call.
      _endCallProperly();
    }
  }

  Future<void> _endCallProperly() async {
    AppLogger.log(
      '🔴🔴🔴 _endCallProperly() CALLED 🔴🔴🔴',
      tag: 'CALL_SCREEN',
    );

    if (_sessionId != null && _sessionId! > 0) {
      AppLogger.log(
        '✅ Valid session ID exists, proceeding to end call',
        tag: 'CALL_SCREEN',
      );

      await _callService?.endCall(_sessionId, _callDuration);

      AppLogger.log('✅ CallService.endCall() completed', tag: 'CALL_SCREEN');
    }
    AppLogger.log(
      '🔴🔴🔴 _endCallProperly() FINISHED 🔴🔴🔴',
      tag: 'CALL_SCREEN',
    );
  }

  Future<void> _requestPermissionsAndInitialize() async {
    try {
      AppLogger.log('🔐 Requesting permissions...', tag: 'CALL');

      final micStatus = await Permission.microphone.request();

      if (micStatus.isGranted) {
        AppLogger.log('✅ Microphone permission granted', tag: 'CALL');
        await _initializeCall();
      } else if (micStatus.isDenied) {
        AppLogger.log('❌ Microphone permission denied', tag: 'CALL');
        setState(() {
          _callStatus = 'Microphone permission required';
        });
        _showPermissionDialog();
      } else if (micStatus.isPermanentlyDenied) {
        AppLogger.log(
          '❌ Microphone permission permanently denied',
          tag: 'CALL',
        );
        setState(() {
          _callStatus = 'Permission denied';
        });
        _showSettingsDialog();
      }
    } catch (e) {
      AppLogger.error('❌ Permission request failed', error: e, tag: 'CALL');
      setState(() {
        _callStatus = 'Permission error';
      });
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Microphone Permission Required'),
        content: Text('This app needs microphone access to make voice calls.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _requestPermissionsAndInitialize();
            },
            child: Text('Allow'),
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
        title: Text('Permission Required'),
        content: Text(
          'Please enable microphone permission in app settings to make calls.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await openAppSettings();
              Navigator.pop(context);
            },
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeCall() async {
    try {
      AppLogger.log('🚀 Starting call initialization...', tag: 'CALL');
      AppLogger.log('👤 Driver: ${widget.driverName}', tag: 'CALL');
      AppLogger.log('🚗 Ride ID: ${widget.rideId}', tag: 'CALL');
      AppLogger.log('📞 Session ID: ${widget.sessionId}', tag: 'CALL');

      _callService = CallService();
      AppLogger.log('📞 CallService instance created', tag: 'CALL');

      final success = await _callService?.initialize();
      if (success != true) {
        AppLogger.error('❌ CallService initialization failed', tag: 'CALL');
        setState(() {
          _callStatus = 'Initialization failed';
        });
        return;
      }
      AppLogger.log('✅ CallService initialized', tag: 'CALL');

      // Set up state change callback BEFORE any call operations
      _callService?.onCallStateChanged = (state) {
        AppLogger.log('📱 Call state changed to: $state', tag: 'CALL');

        if (!mounted) return;

        setState(() {
          _callStatus = state;

          if (state == 'Connected' || state == 'Connecting...') {
            if (state == 'Connected' && !_isCallActive) {
              AppLogger.log('⏱️ Starting call timer', tag: 'CALL');
              _isCallActive = true;
              _startCallTimer();
              _callService?.stopRingtone();
            }
          } else if (state == 'Call ended' || state == 'Call rejected') {
            _isCallActive = false;
            Future.delayed(Duration(seconds: 2), () {
              if (mounted) {
                Navigator.pop(context);
              }
            });
          }
        });
      };

      // If sessionId is provided, this is an incoming call - answer it
      if (widget.sessionId != null) {
        AppLogger.log('📞 Answering incoming call...', tag: 'CALL');
        _sessionId = widget.sessionId;
        _callService?.setIncomingCallContext(_sessionId!, widget.rideId, null);
        AppLogger.log('✅ Using session ID: $_sessionId', tag: 'CALL');

        // Agora Migration: Ignore buffered WebRTC messages.
        GlobalCallService.instance.clearPendingMessages();

        await _callService?.answerCall(_sessionId!, widget.rideId);
      } else {
        // Otherwise, initiate a new call
        AppLogger.log('📤 Initiating call to driver...', tag: 'CALL');
        final session = await _callService?.initiateCall(widget.rideId);

        if (session != null && session['session_id'] != null) {
          _sessionId = session['session_id'] is int
              ? session['session_id']
              : int.tryParse(session['session_id'].toString());
          AppLogger.log(
            '✅ Call initiated - Session ID: $_sessionId',
            tag: 'CALL',
          );
        } else {
          AppLogger.log('❌ No session ID received from server', tag: 'CALL');
          setState(() {
            _callStatus = 'Call initiation failed';
          });
          return;
        }
      }

      setState(() {
        _callStatus = 'Ringing...';
      });
      AppLogger.log('🔔 Call status updated to: Ringing...', tag: 'CALL');
    } catch (e) {
      AppLogger.error('❌ Failed to initialize call', error: e, tag: 'CALL');
      setState(() {
        _callStatus = 'Call failed';
      });
    }
  }

  void _startCallTimer() {
    _callTimer?.cancel(); // Cancel any existing timer
    _callTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDuration++;
        });
      }
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
    _callService?.toggleMute(_isMuted);
  }

  Future<void> _toggleSpeaker() async {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    await _callService?.toggleSpeaker(_isSpeakerOn);
  }

  void _endCall() async {
    AppLogger.log(
      '═══════════════════════════════════════',
      tag: 'CALL_SCREEN',
    );
    AppLogger.log('🔴 END CALL BUTTON PRESSED', tag: 'CALL_SCREEN');

    AppLogger.log('⏸️ Cancelling call timer...', tag: 'CALL_SCREEN');
    _callTimer?.cancel();

    AppLogger.log('📤 Calling _endCallProperly()...', tag: 'CALL_SCREEN');
    await _endCallProperly();

    AppLogger.log('🚪 Navigating back...', tag: 'CALL_SCREEN');
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _endCallProperly();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
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
                              Navigator.pop(context);
                            },
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
                                color: _isCallActive
                                    ? Colors.green
                                    : Colors.grey,
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
                    child: SizedBox(
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
                    margin: EdgeInsets.only(
                      bottom: 49.h,
                      left: 20.w,
                      right: 20.w,
                    ),
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
                          onTap: () async {
                            await _endCallProperly();
                            Navigator.pop(context);
                          },
                        ),
                        CallButton(
                          icon: _isSpeakerOn
                              ? Icons.volume_up
                              : Icons.volume_down,
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
            ],
          ),
        ),
      ),
    );
  }
}
