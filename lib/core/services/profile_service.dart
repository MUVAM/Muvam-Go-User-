import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:muvam/core/utils/app_logger.dart';
import '../constants/url_constants.dart';
import 'auth_service.dart';

class ProfileService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getUserProfile() async {
    final token = await _authService.getToken();
    
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.userProfile}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    AppLogger.log('Profile Response Status: ${response.statusCode}');
    AppLogger.log('Profile Response Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch user profile: ${response.body}');
    }
  }

  Future<void> updateTip(int tip) async {
    final token = await _authService.getToken();
    
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.post(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.userTip}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'tip': tip}),
    );

    AppLogger.log('Update Tip Response Status: ${response.statusCode}');
    AppLogger.log('Update Tip Response Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to update tip: ${response.body}');
    }
  }
}