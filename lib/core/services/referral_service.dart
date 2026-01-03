import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:muvam/core/constants/url_constants.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReferralService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, dynamic>> getReferralCode() async {
    final token = await _getToken();

    if (token == null) {
      AppLogger.log('No auth token found');
      return {'success': false, 'message': 'No authentication token'};
    }

    final url = '${UrlConstants.baseUrl}/referrals';

    AppLogger.log('FETCHING REFERRAL CODE');
    AppLogger.log('URL: $url');
    AppLogger.log('Method: POST');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.log('Response Status: ${response.statusCode}');
      AppLogger.log('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.log('Referral code fetched successfully');
        AppLogger.log('Code: ${data['code']}');
        AppLogger.log('Share URL: ${data['share_url']}');
        AppLogger.log('Total Uses: ${data['total_uses']}');
        return {'success': true, 'data': data};
      } else {
        AppLogger.log('Failed: ${response.body}');
        return {
          'success': false,
          'message': 'Failed with status ${response.statusCode}',
        };
      }
    } catch (e) {
      AppLogger.log('Exception in getReferralCode: $e');
      return {'success': false, 'message': 'Exception: $e'};
    } finally {
      AppLogger.log('==================================');
    }
  }
}
