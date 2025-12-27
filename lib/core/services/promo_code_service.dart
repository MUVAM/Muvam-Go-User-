import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:muvam/core/constants/url_constants.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PromoCodeService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, dynamic>> validatePromoCode(String code) async {
    final token = await _getToken();

    if (token == null) {
      AppLogger.log('No auth token found');
      return {'success': false, 'message': 'No authentication token'};
    }

    final url = '${UrlConstants.baseUrl}/promo-codes/validate';

    final requestBody = {'code': code};

    AppLogger.log('URL: $url');
    AppLogger.log('Method: POST');
    AppLogger.log('Request Body: ${jsonEncode(requestBody)}');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      AppLogger.log('Response Status: ${response.statusCode}');
      AppLogger.log('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.log('Promo code validated successfully');
        return {'success': true, 'data': data};
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        final errorMessage = data['error'] ?? 'Invalid promo code';
        AppLogger.log('Validation failed: $errorMessage');
        return {'success': false, 'message': errorMessage};
      } else {
        AppLogger.log('Failed with status: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Failed with status ${response.statusCode}',
        };
      }
    } catch (e) {
      AppLogger.log('Exception in validatePromoCode: $e');
      return {'success': false, 'message': 'Exception: $e'};
    } finally {
      AppLogger.log('==================================');
    }
  }
}
