import 'dart:convert';
import 'package:muvam/core/constants/url_constants.dart';
import 'package:muvam/core/services/api_client.dart';
import 'package:muvam/core/utils/app_logger.dart';

class PromoCodeService {
  final _client = ApiClient();

  Future<Map<String, dynamic>> validatePromoCode(String code) async {
    final url = '${UrlConstants.baseUrl}/promo-codes/validate';
    final requestBody = {'code': code};

    AppLogger.log('URL: $url');
    AppLogger.log('Method: POST');
    AppLogger.log('Request Body: ${jsonEncode(requestBody)}');

    try {
      final response = await _client.post(
        Uri.parse(url),
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
