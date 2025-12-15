import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/core/services/socket_service.dart';
import 'package:audioplayers/audioplayers.dart';

class CallService {
  static const String baseUrl = 'http://44.222.121.219/api/v1';
  SocketService? _socketService;
  Function(String)? onCallStateChanged;
  int? _currentSessionId;
  int _callStartTime = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRinging = false;

  Future<void> initialize() async {
    AppLogger.log('🔧 Initializing CallService...', tag: 'CALL');
    final token = await _getToken();
    AppLogger.log('🔑 Token retrieved: ${token?.substring(0, 20)}...', tag: 'CALL');
    
    if (token != null) {
      _socketService = SocketService(token);
      AppLogger.log('🔌 Connecting to WebSocket...', tag: 'CALL');
      await _socketService!.connect();
      _setupWebSocketListeners();
      AppLogger.log('✅ CallService initialized successfully', tag: 'CALL');
    } else {
      AppLogger.log('❌ No token found, cannot initialize', tag: 'CALL');
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

  void _setupWebSocketListeners() {
    AppLogger.log('👂 Setting up WebSocket listeners...', tag: 'CALL');
    _socketService?.listenToMessages((data) {
      AppLogger.log('📨 WebSocket message received: $data', tag: 'CALL');
      
      if (data['type'] == 'call_answer') {
        AppLogger.log('✅ Call answered by driver', tag: 'CALL');
        _stopRingtone();
        onCallStateChanged?.call('Connected');
        _callStartTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      } else if (data['type'] == 'call_reject') {
        AppLogger.log('❌ Call rejected by driver', tag: 'CALL');
        _stopRingtone();
        onCallStateChanged?.call('Call rejected');
      } else if (data['type'] == 'call_end') {
        AppLogger.log('📞 Call ended', tag: 'CALL');
        _stopRingtone();
        onCallStateChanged?.call('Call ended');
      }
    });
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

  Future<Map<String, dynamic>> initiateCall(int rideId) async {
    try {
      AppLogger.log('📞 Initiating call for ride ID: $rideId', tag: 'CALL');
      final headers = await _getHeaders();
      AppLogger.log('📤 Sending POST request to: $baseUrl/rides/$rideId/call', tag: 'CALL');
      
      final response = await http.post(
        Uri.parse('$baseUrl/rides/$rideId/call'),
        headers: headers,
      );

      AppLogger.log('📥 Response status: ${response.statusCode}', tag: 'CALL');
      AppLogger.log('📥 Response body: ${response.body}', tag: 'CALL');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _currentSessionId = data['session_id'];
        AppLogger.log('✅ Call initiated successfully', tag: 'CALL');
        AppLogger.log('🆔 Session ID: $_currentSessionId', tag: 'CALL');
        AppLogger.log('💬 Message: ${data['message']}', tag: 'CALL');
        
        // Start playing ringtone
        _playRingtone();
        
        return data;
      } else {
        AppLogger.log('❌ Failed to initiate call: ${response.body}', tag: 'CALL');
        throw Exception('Failed to initiate call: ${response.body}');
      }
    } catch (e) {
      AppLogger.error('❌ Call initiation failed', error: e, tag: 'CALL');
      rethrow;
    }
  }

  Future<void> endCall(int? sessionId, int duration) async {
    if (sessionId == null) {
      AppLogger.log('⚠️ No session ID, skipping end call', tag: 'CALL');
      return;
    }
    
    try {
      AppLogger.log('📞 Ending call - Session ID: $sessionId, Duration: $duration seconds', tag: 'CALL');
      _stopRingtone();
      
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/calls/$sessionId/end'),
        headers: headers,
        body: json.encode({'duration': duration}),
      );

      AppLogger.log('📥 End call response status: ${response.statusCode}', tag: 'CALL');
      AppLogger.log('📥 End call response body: ${response.body}', tag: 'CALL');

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
  }

  void toggleSpeaker(bool isSpeakerOn) {
    AppLogger.log('🔊 Speaker toggled: $isSpeakerOn', tag: 'CALL');
  }

  void dispose() {
    AppLogger.log('🧹 Disposing CallService...', tag: 'CALL');
    _stopRingtone();
    _audioPlayer.dispose();
    _socketService?.disconnect();
    AppLogger.log('✅ CallService disposed', tag: 'CALL');
  }
}