import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/core/services/socket_service.dart';

class CallService {
  static const String baseUrl = 'https://api.muvam.com/api/v1';
  SocketService? _socketService;
  Function(String)? onCallStateChanged;
  int? _currentSessionId;
  int _callStartTime = 0;

  Future<void> initialize() async {
    final token = await _getToken();
    if (token != null) {
      _socketService = SocketService(token);
      await _socketService!.connect();
      _setupWebSocketListeners();
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
    _socketService?.listenToMessages((data) {
      if (data['type'] == 'call_answer') {
        onCallStateChanged?.call('Connected');
        _callStartTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      } else if (data['type'] == 'call_reject') {
        onCallStateChanged?.call('Call rejected');
      } else if (data['type'] == 'call_end') {
        onCallStateChanged?.call('Call ended');
      }
    });
  }

  Future<Map<String, dynamic>> initiateCall(int rideId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/rides/$rideId/call'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _currentSessionId = data['session_id'];
        AppLogger.log('Call initiated: ${data['message']}', tag: 'CALL');
        return data;
      } else {
        throw Exception('Failed to initiate call: ${response.body}');
      }
    } catch (e) {
      AppLogger.error('Call initiation failed', error: e, tag: 'CALL');
      rethrow;
    }
  }

  Future<void> endCall(int? sessionId, int duration) async {
    if (sessionId == null) return;
    
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/calls/$sessionId/end'),
        headers: headers,
        body: json.encode({'duration': duration}),
      );

      if (response.statusCode == 200) {
        AppLogger.log('Call ended successfully', tag: 'CALL');
      }
    } catch (e) {
      AppLogger.error('Failed to end call', error: e, tag: 'CALL');
    }
  }

  void toggleMute(bool isMuted) {
    AppLogger.log('Mute toggled: $isMuted', tag: 'CALL');
    // TODO: Implement WebRTC mute functionality
  }

  void toggleSpeaker(bool isSpeakerOn) {
    AppLogger.log('Speaker toggled: $isSpeakerOn', tag: 'CALL');
    // TODO: Implement speaker toggle functionality
  }

  void dispose() {
    _socketService?.disconnect();
  }
}