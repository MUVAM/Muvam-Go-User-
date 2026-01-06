import 'dart:async';
import 'dart:convert';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:muvam/core/services/unified_notification_service.dart';
import 'package:muvam/core/services/websocket_service.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CallService {
  static final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
  static final String agoraAppId = dotenv.env['AGORA_APP_ID'] ?? '';

  WebSocketService? _webSocketService;
  RtcEngine? _engine;

  Function(String)? onCallStateChanged;
  Function(Map<String, dynamic>)? onIncomingCall;

  int? _currentSessionId;
  int? _rideId;
  int? _recipientId;
  int _callStartTime = 0;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRinging = false;
  bool _isJoined = false;
  bool _isEngineInitialized = false;
  bool _wasConnected = false; // Track if call was ever connected

  Future<bool> initialize() async {
    AppLogger.log('Initializing CallService (Agora)...', tag: 'CALL');

    if (_isEngineInitialized) {
      AppLogger.log('Engine already initialized, skipping.', tag: 'CALL');
      return true;
    }

    try {
      // 1. WebSocket Setup
      _webSocketService = WebSocketService.instance;
      if (!_webSocketService!.isConnected) {
        AppLogger.log('Connecting WebSocket...', tag: 'CALL');
        await _webSocketService!.connect();
      }
      _webSocketService!.addIncomingCallListener(_handleWebSocketMessage);

      // 2. Initialize Agora Engine
      AppLogger.log('Creating Agora Engine...', tag: 'CALL');
      _engine = createAgoraRtcEngine();

      // Release any lingering native instance (Hot Restart issue)
      try {
        await _engine!.release();
        AppLogger.log('Released previous engine instance', tag: 'CALL');
      } catch (e) {
        // Ignore, expected if not initialized
      }

      AppLogger.log('Initializing Agora Engine with App ID...', tag: 'CALL');
      AppLogger.log('   - App ID Length: ${agoraAppId.length}', tag: 'CALL');

      await _engine!.initialize(
        RtcEngineContext(
          appId: agoraAppId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            AppLogger.log(
              "Agora: Joined channel ${connection.channelId}",
              tag: 'CALL',
            );
            _isJoined = true;
            // Don't change state here - keep it as "Ringing..." until other user joins
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            AppLogger.log("Agora: User joined $remoteUid", tag: 'CALL');
            stopRingtone();
            _wasConnected = true; // Mark that we had a connection
            onCallStateChanged?.call("Connected");
          },
          onUserOffline:
              (
                RtcConnection connection,
                int remoteUid,
                UserOfflineReasonType reason,
              ) {
                AppLogger.log(
                  "Agora: User offline $remoteUid (Reason: $reason)",
                  tag: 'CALL',
                );
                // Only trigger "Call ended" if we were actually connected
                // This prevents false "Call ended" during the ringing phase
                if (_wasConnected) {
                  AppLogger.log(
                    "Call ending - user was connected before",
                    tag: 'CALL',
                  );
                  onCallStateChanged?.call("Call ended");
                } else {
                  AppLogger.log(
                    "Ignoring user offline - never connected",
                    tag: 'CALL',
                  );
                }
              },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            AppLogger.log("Agora: Left channel", tag: 'CALL');
            _isJoined = false;
          },
          onError: (ErrorCodeType err, String msg) {
            // Token errors are expected if using Agora without authentication
            if (err == ErrorCodeType.errInvalidToken) {
              AppLogger.log(
                'Agora: Token not configured (using test mode)',
                tag: 'CALL',
              );
            } else {
              AppLogger.error('Agora Error callback: $err - $msg', tag: 'CALL');
            }
          },
        ),
      );

      AppLogger.log('Setting Client Role & Audio Profile...', tag: 'CALL');
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine!.enableAudio();
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileSpeechStandard,
        scenario: AudioScenarioType.audioScenarioGameStreaming,
      );

      // Note: setEnableSpeakerphone will be called after joining channel

      _isEngineInitialized = true;
      AppLogger.log('CallService initialized successfully', tag: 'CALL');
      return true;
    } catch (e, stack) {
      AppLogger.error(
        'Failed to initialize CallService',
        error: e,
        tag: 'CALL',
      );
      AppLogger.log('Stack trace: $stack', tag: 'CALL');
      return false;
    }
  }

  void _handleWebSocketMessage(Map<String, dynamic> data) async {
    final type = data['type'];
    if (type?.toString().startsWith('call') != true) {
      return;
    }

    AppLogger.log('CallService received: $type', tag: 'CALL');

    if (type == 'call_initiate') {
      AppLogger.log('Incoming call received', tag: 'CALL');
      playRingtone();
      onIncomingCall?.call(data);

      if (data['data'] != null) {
        _currentSessionId = data['data']['session_id'];
        _rideId = data['data']['ride_id'];
        _recipientId = data['data']['caller_id'];
        AppLogger.log(
          'Session ID: $_currentSessionId, Ride ID: $_rideId, Caller ID: $_recipientId',
          tag: 'CALL',
        );
      }
    } else if (type == 'call_answer') {
      AppLogger.log('Call answered by other party (Signal)', tag: 'CALL');
      // The media connection handles the "Connected" state via onUserJoined
      // But we can stop ringtone here too as a backup
      stopRingtone();
      _callStartTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Join channel if initiator
      if (_rideId != null) {
        _joinAgoraChannel(_rideId!);
      }
    } else if (type == 'call_reject' || type == 'call_end') {
      AppLogger.log('Call ended/rejected', tag: 'CALL');
      stopRingtone();
      onCallStateChanged?.call('Call ended');
      await _leaveAgoraChannel();
    }
    // Ignore flutter_webrtc messages (call_offer, call_ice_candidate, etc.)
  }

  // Allow compatibility with existing CallScreen pending message replay logic (which we should remove/ignore)
  void handleMessage(Map<String, dynamic> data) {
    // Legacy: Ignore or minimal log
    // _handleWebSocketMessage(data);
  }

  Future<void> _joinAgoraChannel(int rideId) async {
    if (!_isEngineInitialized || _engine == null) {
      AppLogger.error('Agora Engine not initialized', tag: 'CALL');
      return;
    }

    String channelName = "CallID${rideId}Call";
    AppLogger.log('Joining Agora Channel: $channelName', tag: 'CALL');

    try {
      await _engine!.joinChannel(
        token: "", // Empty string for no token (if supported by app settings)
        channelId: channelName,
        uid: 0, // 0 = let Agora assign logic
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
        ),
      );

      // Give audio session time to initialize before setting routing
      await Future.delayed(const Duration(milliseconds: 500));

      // Set audio routing to earpiece after joining channel
      try {
        await _engine!.setEnableSpeakerphone(false);
        AppLogger.log('Audio routed to earpiece', tag: 'CALL');
      } catch (e) {
        AppLogger.log('Could not set earpiece (will retry): $e', tag: 'CALL');
      }
    } catch (e) {
      AppLogger.error('Failed to join Agora channel', error: e, tag: 'CALL');
    }
  }

  Future<void> _leaveAgoraChannel() async {
    if (_engine != null && _isJoined) {
      await _engine!.leaveChannel();
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<void> playRingtone() async {
    if (_isRinging) return;
    _isRinging = true;
    AppLogger.log('Playing ringtone...', tag: 'CALL');
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('sounds/calling.mp3'));
    } catch (e) {
      AppLogger.error('Failed to play ringtone', error: e, tag: 'CALL');
    }
  }

  Future<void> stopRingtone() async {
    if (!_isRinging) return;
    _isRinging = false;
    AppLogger.log('Stopping ringtone...', tag: 'CALL');
    await _audioPlayer.stop();
  }

  Future<Map<String, dynamic>> initiateCall(int rideId) async {
    try {
      AppLogger.log('Initiating API call for ride ID: $rideId', tag: 'CALL');
      _rideId = rideId;
      _wasConnected = false; // Reset connection state for new call

      await cleanupPreviousSession();

      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/rides/$rideId/call'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _currentSessionId = data['session_id'];
        _recipientId = data['recipient_id'];
        await storeSessionId(_currentSessionId!);

        AppLogger.log(
          'Call initiated. Session: $_currentSessionId',
          tag: 'CALL',
        );

        playRingtone();

        // Send push notification to passenger about incoming call
        try {
          final recipientIdStr =
              _recipientId?.toString() ?? data['recipient_id']?.toString();
          if (recipientIdStr != null) {
            await UnifiedNotificationService.sendCallNotification(
              receiverId: recipientIdStr,
              callerName: "Driver",
              rideId: rideId,
              sessionId: _currentSessionId!,
              callerImage: null,
            );
            AppLogger.log(
              'Call notification sent to passenger $recipientIdStr',
              tag: 'CALL',
            );
          }
        } catch (e) {
          AppLogger.log('Failed to send call notification: $e', tag: 'CALL');
        }

        // Join Agora Immediately after success API?
        // Usually, initiator waits for ANSWER to join? Or joins immediately?
        // Standard flow: Both join.
        // Let's join immediately so we are ready.
        if (_isEngineInitialized) {
          await _joinAgoraChannel(rideId);
        } else {
          AppLogger.log(
            'Agora Engine NOT initialized, skipping joinChannel',
            tag: 'CALL',
          );
        }

        return data; // Return session data for UI
      } else {
        throw Exception('Failed to initiate call: ${response.body}');
      }
    } catch (e) {
      AppLogger.error('Call initiation failed', error: e, tag: 'CALL');
      rethrow;
    }
  }

  Future<void> answerCall(int sessionId, int rideId) async {
    try {
      AppLogger.log('Answering API call...', tag: 'CALL');
      _currentSessionId = sessionId;
      _rideId = rideId; // Set ride ID immediately
      _wasConnected = false; // Reset connection state for new call

      final headers = await getHeaders();
      await http.post(
        Uri.parse('$baseUrl/calls/$sessionId/answer'),
        headers: headers,
      );

      stopRingtone();
      _callStartTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Now join the Agora channel with the ride ID
      if (_isEngineInitialized) {
        await _joinAgoraChannel(rideId);
      } else {
        AppLogger.log(
          'Agora Engine NOT initialized, skipping joinChannel (Answer)',
          tag: 'CALL',
        );
      }
    } catch (e) {
      AppLogger.error('Failed to answer call', error: e, tag: 'CALL');
    }
  }

  Future<void> rejectCall(int sessionId) async {
    try {
      AppLogger.log('Rejecting Call...', tag: 'CALL');
      final headers = await getHeaders();
      await http.post(
        Uri.parse('$baseUrl/calls/$sessionId/reject'),
        headers: headers,
      );
      stopRingtone();
      AppLogger.log('Call rejected API success', tag: 'CALL');
    } catch (e) {
      AppLogger.error('Failed to reject call', error: e, tag: 'CALL');
    }
  }

  void setIncomingCallContext(int sessionId, int rideId, int? recipientId) {
    _currentSessionId = sessionId;
    _rideId = rideId;
    _recipientId = recipientId;
    AppLogger.log(
      'CONTEXT SET: Session $_currentSessionId, Ride $_rideId',
      tag: 'CALL',
    );
  }

  Future<void> endCall(int? sessionId, int duration) async {
    if (sessionId == null) return;
    try {
      AppLogger.log('Ending Call...', tag: 'CALL');
      stopRingtone();
      await _leaveAgoraChannel();

      final headers = await getHeaders();
      await http.post(
        Uri.parse('$baseUrl/calls/$sessionId/end'),
        headers: headers,
        body: json.encode({'duration': duration}),
      );

      await clearStoredSessionId();
      AppLogger.log('Call ended API success', tag: 'CALL');
    } catch (e) {
      AppLogger.error('Failed to end call', error: e, tag: 'CALL');
    } finally {
      onCallStateChanged?.call('Call ended');
    }
  }

  void toggleMute(bool isMuted) {
    _engine?.muteLocalAudioStream(isMuted);
    AppLogger.log('Mute: $isMuted', tag: 'CALL');
  }

  Future<void> toggleSpeaker(bool isSpeakerOn) async {
    await _engine?.setEnableSpeakerphone(isSpeakerOn);
    AppLogger.log('Speaker: $isSpeakerOn', tag: 'CALL');
  }

  // Helper methods for session storage
  Future<void> storeSessionId(int sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('active_call_session_id', sessionId);
    await prefs.setInt(
      'active_call_start_time',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> clearStoredSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_call_session_id');
    await prefs.remove('active_call_start_time');
  }

  Future<void> cleanupPreviousSession() async {
    // Logic from before
    final prefs = await SharedPreferences.getInstance();
    final sid = prefs.getInt('active_call_session_id');
    if (sid != null) await endCall(sid, 0);
  }

  void dispose() {
    AppLogger.log('Disposing CallService', tag: 'CALL');
    stopRingtone();
    _engine?.release(); // Destroy Agora engine
    _webSocketService?.removeIncomingCallListener(_handleWebSocketMessage);
  }
}
