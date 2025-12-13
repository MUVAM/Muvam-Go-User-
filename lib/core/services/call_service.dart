import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:muvam/core/constants/url_constants.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CallService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, dynamic>> initiateCall(int rideId) async {
    final token = await _getToken();
    
    final response = await http.post(
      Uri.parse('${UrlConstants.baseUrl}/rides/$rideId/call'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    AppLogger.log('Initiate Call Response Status: ${response.statusCode}');
    AppLogger.log('Initiate Call Response Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to initiate call: ${response.body}');
    }
  }

  Future<void> answerCall(int sessionId) async {
    final token = await _getToken();
    
    final response = await http.post(
      Uri.parse('${UrlConstants.baseUrl}/calls/$sessionId/answer'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    AppLogger.log('Answer Call Response Status: ${response.statusCode}');
    AppLogger.log('Answer Call Response Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to answer call: ${response.body}');
    }
  }

  Future<void> rejectCall(int sessionId) async {
    final token = await _getToken();
    
    final response = await http.post(
      Uri.parse('${UrlConstants.baseUrl}/calls/$sessionId/reject'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    AppLogger.log('Reject Call Response Status: ${response.statusCode}');
    AppLogger.log('Reject Call Response Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to reject call: ${response.body}');
    }
  }

  Future<void> endCall(int sessionId, int duration) async {
    final token = await _getToken();
    
    final response = await http.post(
      Uri.parse('${UrlConstants.baseUrl}/calls/$sessionId/end'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'duration': duration}),
    );

    AppLogger.log('End Call Response Status: ${response.statusCode}');
    AppLogger.log('End Call Response Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to end call: ${response.body}');
    }
  }
}