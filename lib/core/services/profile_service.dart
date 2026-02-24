import 'dart:convert';
import 'package:muvam/core/services/api_client.dart';
import 'package:muvam/core/utils/app_logger.dart';
import '../constants/url_constants.dart';

class ProfileService {
  final _client = ApiClient();

  Future<Map<String, dynamic>> getUserProfile() async {
    final response = await _client.get(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.userProfile}'),
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
    final response = await _client.post(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.userTip}'),
      body: jsonEncode({'tip': tip}),
    );

    AppLogger.log('Update Tip Response Status: ${response.statusCode}');
    AppLogger.log('Update Tip Response Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to update tip: ${response.body}');
    }
  }
}
