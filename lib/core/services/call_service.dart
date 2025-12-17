
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:muvam/core/services/websocket_service.dart'; // CHANGED
import 'package:muvam/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

//FOR PASSENGER - Uses WebSocketService
class CallService {
  static const String baseUrl = 'http://44.222.121.219/api/v1';
  WebSocketService? _webSocketService; // CHANGED
  Function(String)? onCallStateChanged;
  Function(Map<String, dynamic>)? onIncomingCall;
  int? _currentSessionId;
  int _callStartTime = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRinging = false;

  // WebRTC Properties
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  MediaStream? get remoteStream => _remoteStream;
  MediaStream? get localStream => _localStream;

  List<RTCIceCandidate> _iceCandidates = [];
  bool _isInitiator = false;
  int? _recipientId;
  int? _rideId;

  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun.cloudflare.com:3478'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  final Map<String, dynamic> _constraints = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  Future<void> initialize() async {
    AppLogger.log('🔧 Initializing CallService (Passenger)...', tag: 'CALL');
    
    // Use singleton WebSocketService
    _webSocketService = WebSocketService.instance;
    
    // Ensure it's connected
    if (!_webSocketService!.isConnected) {
      AppLogger.log('🔌 WebSocket not connected, connecting...', tag: 'CALL');
      await _webSocketService!.connect();
    }
    
    // Register call message handler
    _webSocketService!.onIncomingCall = _handleWebSocketMessage;
    
    AppLogger.log('✅ CallService initialized successfully', tag: 'CALL');
  }

  void _handleWebSocketMessage(Map<String, dynamic> data) async {
    // Only process call-related messages
    final type = data['type'];
    if (type?.toString().startsWith('call') != true) {
      return;
    }

    AppLogger.log('📨 CallService received: $type', tag: 'CALL');

    if (type == 'call_initiate') {
      AppLogger.log('📞 Incoming call received', tag: 'CALL');
      _playRingtone();
      onIncomingCall?.call(data);

      if (data['data'] != null) {
        _currentSessionId = data['data']['session_id'];
        _rideId = data['data']['ride_id'];
        _recipientId = data['data']['caller_id'];
        _isInitiator = false;
      }
    } else if (type == 'call_answer') {
      AppLogger.log('✅ Call answered by driver', tag: 'CALL');
      _stopRingtone();
      onCallStateChanged?.call('Connected');
      _callStartTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    } else if (type == 'call_reject') {
      AppLogger.log('❌ Call rejected by driver', tag: 'CALL');
      _stopRingtone();
      onCallStateChanged?.call('Call rejected');
      await _cleanupWebRTC();
    } else if (type == 'call_end') {
      AppLogger.log('📞 Call ended', tag: 'CALL');
      _stopRingtone();
      onCallStateChanged?.call('Call ended');
      await _cleanupWebRTC();
    } else if (type == 'call_offer') {
      AppLogger.log('📥 Received WebRTC offer', tag: 'CALL');
      await _handleOffer(data['data']);
    } else if (type == 'call_answer_sdp') {
      AppLogger.log('📥 Received WebRTC answer', tag: 'CALL');
      await _handleAnswer(data['data']);
    } else if (type == 'call_ice_candidate') {
      AppLogger.log('📥 Received ICE candidate', tag: 'CALL');
      await _handleIceCandidate(data['data']);
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<void> _playRingtone() async {
    if (_isRinging) return;
    _isRinging = true;
    AppLogger.log('🔔 Playing ringtone...', tag: 'CALL');
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('sounds/calling.mp3'));
      AppLogger.log('✅ Ringtone started', tag: 'CALL');
    } catch (e) {
      AppLogger.error('❌ Failed to play ringtone', error: e, tag: 'CALL');
    }
  }

  Future<void> _stopRingtone() async {
    if (!_isRinging) return;
    _isRinging = false;
    AppLogger.log('🔕 Stopping ringtone...', tag: 'CALL');
    await _audioPlayer.stop();
  }

  Future<void> _setupLocalMedia() async {
    try {
      AppLogger.log('🎤 Setting up local media...', tag: 'CALL');

      final Map<String, dynamic> mediaConstraints = {
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      };

      _localStream = await navigator.mediaDevices.getUserMedia(
        mediaConstraints,
      );
      AppLogger.log('✅ Local media stream obtained', tag: 'CALL');
      AppLogger.log(
        '🎤 Audio tracks: ${_localStream!.getAudioTracks().length}',
        tag: 'CALL',
      );
    } catch (e) {
      AppLogger.error('❌ Failed to get local media', error: e, tag: 'CALL');
      rethrow;
    }
  }

  Future<void> _createPeerConnection() async {
    try {
      AppLogger.log('🔗 Creating peer connection...', tag: 'CALL');

      _peerConnection = await createPeerConnection(
        _configuration,
        _constraints,
      );

      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) {
          _peerConnection!.addTrack(track, _localStream!);
          AppLogger.log('➕ Added local track: ${track.kind}', tag: 'CALL');
        });
      }

      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        AppLogger.log(
          '🧊 New ICE candidate: ${candidate.candidate}',
          tag: 'CALL',
        );
        _sendIceCandidate(candidate);
      };

      _peerConnection!.onTrack = (RTCTrackEvent event) {
        AppLogger.log('🎵 Remote track received: ${event.track.kind}', tag: 'CALL');
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams[0];
          AppLogger.log(
            '✅ Remote stream set with ${_remoteStream!.getAudioTracks().length} audio tracks',
            tag: 'CALL',
          );
          onCallStateChanged?.call('Connected');
        }
      };

      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        AppLogger.log('🔄 Connection state: $state', tag: 'CALL');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          AppLogger.log('✅ Peer connection CONNECTED', tag: 'CALL');
          onCallStateChanged?.call('Connected');
        } else if (state ==
            RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          AppLogger.log('❌ Peer connection FAILED', tag: 'CALL');
          onCallStateChanged?.call('Connection failed');
        }
      };

      _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
        AppLogger.log('🧊 ICE connection state: $state', tag: 'CALL');

        if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
            state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
          AppLogger.log('✅ ICE connection established', tag: 'CALL');
        } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
          AppLogger.log('❌ ICE connection failed', tag: 'CALL');
        }
      };

      AppLogger.log('✅ Peer connection created', tag: 'CALL');
    } catch (e) {
      AppLogger.error(
        '❌ Failed to create peer connection',
        error: e,
        tag: 'CALL',
      );
      rethrow;
    }
  }

  Future<void> _createAndSendOffer() async {
    try {
      AppLogger.log('📤 Creating offer...', tag: 'CALL');

      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      AppLogger.log('📤 Sending offer via WebSocket', tag: 'CALL');

      _webSocketService?.sendMessage({
        'type': 'call_offer',
        'data': {
          'session_id': _currentSessionId,
          'ride_id': _rideId,
          'recipient_id': _recipientId,
          'sdp': offer.sdp,
        },
      });

      AppLogger.log('✅ Offer sent', tag: 'CALL');
    } catch (e) {
      AppLogger.error('❌ Failed to create/send offer', error: e, tag: 'CALL');
      rethrow;
    }
  }

  Future<void> _handleOffer(Map<String, dynamic> data) async {
    try {
      AppLogger.log('📥 Handling offer...', tag: 'CALL');

      await _setupLocalMedia();
      await _createPeerConnection();

      RTCSessionDescription remoteDescription = RTCSessionDescription(
        data['sdp'],
        'offer',
      );
      await _peerConnection!.setRemoteDescription(remoteDescription);

      AppLogger.log('✅ Remote description set', tag: 'CALL');

      await _createAndSendAnswer();
    } catch (e) {
      AppLogger.error('❌ Failed to handle offer', error: e, tag: 'CALL');
    }
  }

  Future<void> _createAndSendAnswer() async {
    try {
      AppLogger.log('📤 Creating answer...', tag: 'CALL');

      RTCSessionDescription answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      AppLogger.log('📤 Sending answer via WebSocket', tag: 'CALL');

      _webSocketService?.sendMessage({
        'type': 'call_answer_sdp',
        'data': {
          'session_id': _currentSessionId,
          'ride_id': _rideId,
          'recipient_id': _recipientId,
          'sdp': answer.sdp,
        },
      });

      AppLogger.log('✅ Answer sent', tag: 'CALL');
    } catch (e) {
      AppLogger.error('❌ Failed to create/send answer', error: e, tag: 'CALL');
      rethrow;
    }
  }

  Future<void> _handleAnswer(Map<String, dynamic> data) async {
    try {
      AppLogger.log('📥 Handling answer...', tag: 'CALL');

      RTCSessionDescription remoteDescription = RTCSessionDescription(
        data['sdp'],
        'answer',
      );
      await _peerConnection!.setRemoteDescription(remoteDescription);

      AppLogger.log('✅ Remote answer set', tag: 'CALL');
    } catch (e) {
      AppLogger.error('❌ Failed to handle answer', error: e, tag: 'CALL');
    }
  }

  void _sendIceCandidate(RTCIceCandidate candidate) {
    try {
      _webSocketService?.sendMessage({
        'type': 'call_ice_candidate',
        'data': {
          'session_id': _currentSessionId,
          'ride_id': _rideId,
          'recipient_id': _recipientId,
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMLineIndex': candidate.sdpMLineIndex,
            'sdpMid': candidate.sdpMid,
          },
        },
      });
    } catch (e) {
      AppLogger.error('❌ Failed to send ICE candidate', error: e, tag: 'CALL');
    }
  }

  Future<void> _handleIceCandidate(Map<String, dynamic> data) async {
    try {
      AppLogger.log('🧊 Adding ICE candidate...', tag: 'CALL');

      final candidateData = data['candidate'];
      RTCIceCandidate candidate = RTCIceCandidate(
        candidateData['candidate'],
        candidateData['sdpMid'],
        candidateData['sdpMLineIndex'],
      );

      if (_peerConnection != null) {
        await _peerConnection!.addCandidate(candidate);
        AppLogger.log('✅ ICE candidate added', tag: 'CALL');
      } else {
        _iceCandidates.add(candidate);
        AppLogger.log('💾 ICE candidate stored for later', tag: 'CALL');
      }
    } catch (e) {
      AppLogger.error('❌ Failed to add ICE candidate', error: e, tag: 'CALL');
    }
  }

  Future<void> _cleanupWebRTC() async {
    AppLogger.log('🧹 Cleaning up WebRTC...', tag: 'CALL');

    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) {
        track.stop();
      });
      await _localStream!.dispose();
      _localStream = null;
    }

    if (_remoteStream != null) {
      await _remoteStream!.dispose();
      _remoteStream = null;
    }

    if (_peerConnection != null) {
      await _peerConnection!.close();
      await _peerConnection!.dispose();
      _peerConnection = null;
    }

    _iceCandidates.clear();

    AppLogger.log('✅ WebRTC cleanup complete', tag: 'CALL');
  }

  Future<Map<String, dynamic>> initiateCall(int rideId) async {
    // Check if there's already an active call
    if (hasActiveCall) {
      AppLogger.log('⚠️ Active call detected, ending previous call first', tag: 'CALL');
      await endCall(_currentSessionId, 0);
    }
    
    try {
      AppLogger.log('📞 Initiating call for ride ID: $rideId', tag: 'CALL');
      _isInitiator = true;
      _rideId = rideId;

      final headers = await _getHeaders();
      AppLogger.log(
        '📤 Sending POST request to: $baseUrl/rides/$rideId/call',
        tag: 'CALL',
      );

      final response = await http.post(
        Uri.parse('$baseUrl/rides/$rideId/call'),
        headers: headers,
      );

      AppLogger.log('📥 Response status: ${response.statusCode}', tag: 'CALL');
      AppLogger.log('📥 Response body: ${response.body}', tag: 'CALL');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _currentSessionId = data['session_id'];
        _recipientId = data['recipient_id'];

        AppLogger.log('✅ Call initiated successfully', tag: 'CALL');
        AppLogger.log('🆔 Session ID: $_currentSessionId', tag: 'CALL');
        AppLogger.log('👤 Recipient ID: $_recipientId', tag: 'CALL');

        _playRingtone();

        // Setup WebRTC
        await _setupLocalMedia();
        await _createPeerConnection();
        await _createAndSendOffer();

        return data;
      } else {
        AppLogger.log(
          '❌ Failed to initiate call: ${response.body}',
          tag: 'CALL',
        );
        throw Exception('Failed to initiate call: ${response.body}');
      }
    } catch (e) {
      AppLogger.error('❌ Call initiation failed', error: e, tag: 'CALL');
      rethrow;
    }
  }

  Future<void> answerCall(int sessionId) async {
    try {
      AppLogger.log('✅ Answering call...', tag: 'CALL');

      final headers = await _getHeaders();
      await http.post(
        Uri.parse('$baseUrl/calls/$sessionId/answer'),
        headers: headers,
      );

      _stopRingtone();
      _callStartTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      AppLogger.log('✅ Call answered', tag: 'CALL');
    } catch (e) {
      AppLogger.error('❌ Failed to answer call', error: e, tag: 'CALL');
    }
  }

  Future<void> rejectCall(int sessionId) async {
    try {
      final headers = await _getHeaders();
      await http.post(
        Uri.parse('$baseUrl/calls/$sessionId/reject'),
        headers: headers,
      );
      _stopRingtone();
      await _cleanupWebRTC();
      AppLogger.log('❌ Call rejected', tag: 'CALL');
    } catch (e) {
      AppLogger.error('❌ Failed to reject call', error: e, tag: 'CALL');
    }
  }

  Future<void> endCall(int? sessionId, int duration) async {
    if (sessionId == null) {
      AppLogger.log('⚠️ No session ID, skipping end call', tag: 'CALL');
      return;
    }

    try {
      AppLogger.log(
        '📞 Ending call - Session ID: $sessionId, Duration: $duration seconds',
        tag: 'CALL',
      );
      _stopRingtone();

      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/calls/$sessionId/end'),
        headers: headers,
        body: json.encode({'duration': duration}),
      );

      AppLogger.log(
        '📥 End call response status: ${response.statusCode}',
        tag: 'CALL',
      );
      AppLogger.log('📥 End call response body: ${response.body}', tag: 'CALL');

      await _cleanupWebRTC();
      
      // Clear session ID to prevent reuse
      _currentSessionId = null;

      if (response.statusCode == 200) {
        AppLogger.log('✅ Call ended successfully', tag: 'CALL');
      } else {
        AppLogger.log('⚠️ End call returned non-200 status', tag: 'CALL');
      }
    } catch (e) {
      AppLogger.error('❌ Failed to end call', error: e, tag: 'CALL');
    }
  }

  void toggleMute(bool isMuted) {
    AppLogger.log('🎤 Mute toggled: $isMuted', tag: 'CALL');
    if (_localStream != null) {
      _localStream!.getAudioTracks().forEach((track) {
        track.enabled = !isMuted;
      });
    }
  }

  void toggleSpeaker(bool isSpeakerOn) {
    AppLogger.log('🔊 Speaker toggled: $isSpeakerOn', tag: 'CALL');
    Helper.setSpeakerphoneOn(isSpeakerOn);
  }

  // Get current session ID for ending calls
  int? get currentSessionId => _currentSessionId;
  
  // Check if there's an active call
  bool get hasActiveCall => _currentSessionId != null;

  void dispose() {
    AppLogger.log('🧹 Disposing CallService...', tag: 'CALL');
    _stopRingtone();
    _audioPlayer.dispose();
    _cleanupWebRTC();

    // Clear callback
    if (_webSocketService != null) {
      _webSocketService!.onIncomingCall = null;
    }

    AppLogger.log('✅ CallService disposed', tag: 'CALL');
  }
}

