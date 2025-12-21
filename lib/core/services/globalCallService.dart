// lib/core/services/global_call_service.dart

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class GlobalCallService {
  static final GlobalCallService _instance = GlobalCallService._internal();
  factory GlobalCallService() => _instance;
  GlobalCallService._internal();

  static GlobalCallService get instance => _instance;

  OverlayEntry? _overlayEntry;
  final AudioPlayer _ringtonePlayer = AudioPlayer();
  bool _isRinging = false;
  Map<String, dynamic>? _currentCallData;

  // Initialize with navigation key
  GlobalKey<NavigatorState>? _navigatorKey;

  void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    AppLogger.log('🔔 GlobalCallService initialized', tag: 'GLOBAL_CALL');
  }

  // Show incoming call overlay globally
  Future<void> showIncomingCall({
    required Map<String, dynamic> callData,
    required Function(int sessionId) onAccept,
    required Function(int sessionId) onReject,
  }) async {
    if (_navigatorKey == null || _navigatorKey!.currentState == null) {
      AppLogger.log('❌ Navigator key not initialized', tag: 'GLOBAL_CALL');
      return;
    }

    // Remove any existing overlay
    hideIncomingCall();

    _currentCallData = callData;
    final context = _navigatorKey!.currentContext;
    if (context == null) return;

    AppLogger.log(
      '📞 Showing global incoming call overlay',
      tag: 'GLOBAL_CALL',
    );

    // Start playing ringtone
    await _playRingtone();

    // Create and insert overlay
    _overlayEntry = OverlayEntry(
      builder: (context) => _IncomingCallOverlay(
        callData: callData,
        onAccept: () async {
          final sessionId = callData['data']?['session_id'] ?? 0;
          await _stopRingtone();
          hideIncomingCall();
          onAccept(sessionId);
        },
        onReject: () async {
          final sessionId = callData['data']?['session_id'] ?? 0;
          await _stopRingtone();
          hideIncomingCall();
          onReject(sessionId);
        },
      ),
    );
  WakelockPlus.enable();

    Overlay.of(context).insert(_overlayEntry!);
  }

  // Play system ringtone or custom ringtone
  Future<void> _playRingtone() async {
  if (_isRinging) return;
  
  try {
    _isRinging = true;
    // Play system ringtone
    await FlutterRingtonePlayer().play(
      android: AndroidSounds.ringtone,
      ios: IosSounds.glass,
      looping: true,
      volume: 1.0,
    );
  } catch (e) {
    AppLogger.log('❌ Failed to play system ringtone: $e');
  }
}

Future<void> _stopRingtone() async {
  if (!_isRinging) return;
  _isRinging = false;
  await FlutterRingtonePlayer().stop();
}

  // Hide incoming call overlay
  void hideIncomingCall() {
    _stopRingtone();
    _overlayEntry?.remove();
    _overlayEntry = null;
    _currentCallData = null;

      WakelockPlus.disable();

    AppLogger.log('📵 Incoming call overlay hidden', tag: 'GLOBAL_CALL');
  }

  void dispose() {
    hideIncomingCall();
    _ringtonePlayer.dispose();
  }
}

// Incoming call overlay widget
class _IncomingCallOverlay extends StatelessWidget {
  final Map<String, dynamic> callData;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _IncomingCallOverlay({
    required this.callData,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final data = callData['data'] ?? {};
    final callerName = data['caller_name'] ?? 'Unknown Caller';
    final callerImage = data['caller_image'];

    return Material(
      color: Colors.black87,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Caller info
            Column(
              children: [
                // Caller image
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: callerImage != null && callerImage.isNotEmpty
                        ? Image.network(
                            callerImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white,
                            ),
                          )
                        : Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                ),
                SizedBox(height: 30),

                // Caller name
                Text(
                  callerName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),

                // Incoming call text
                Text(
                  'Incoming call...',
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
              ],
            ),

            SizedBox(height: 80),

            // Call action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Reject button
                GestureDetector(
                  onTap: onReject,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.5),
                          blurRadius: 20,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(Icons.call_end, color: Colors.white, size: 35),
                  ),
                ),

                // Accept button
                GestureDetector(
                  onTap: onAccept,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.5),
                          blurRadius: 20,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(Icons.call, color: Colors.white, size: 35),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
