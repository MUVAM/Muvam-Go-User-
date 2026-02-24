import 'dart:convert';
import 'package:muvam/core/services/api_client.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/url_constants.dart';

class DeleteAccountService {
  final _client = ApiClient();

  Future<Map<String, dynamic>> deleteAccount(String reason) async {
    final url = '${UrlConstants.baseUrl}/users/delete';
    final requestBody = {'reason': reason};

    AppLogger.log('==================================');
    AppLogger.log('DELETING ACCOUNT');
    AppLogger.log('==================================');
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

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['error'] != null) {
          final errorMsg = data['message'] ?? data['error'];
          AppLogger.log('Error in 200 response: $errorMsg');
          return {'success': false, 'message': errorMsg};
        }

        if (data['message'] != null) {
          AppLogger.log('Account deleted successfully: ${data['message']}');

          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('auth_token');

          return {'success': true, 'message': data['message'], 'data': data};
        }

        return {'success': false, 'message': 'Unexpected response format'};
      } else {
        final errorMessage =
            data['message'] ?? data['error'] ?? 'Failed to delete account';

        AppLogger.log(
          'Failed with status ${response.statusCode}: $errorMessage',
        );
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      AppLogger.log('Exception in deleteAccount: $e');
      return {
        'success': false,
        'message': 'Failed to delete account. Please try again.',
      };
    } finally {
      AppLogger.log('==================================');
    }
  }
}
