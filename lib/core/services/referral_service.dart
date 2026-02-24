import 'dart:convert';
import 'package:muvam/core/constants/url_constants.dart';
import 'package:muvam/core/services/api_client.dart';
import 'package:muvam/core/utils/app_logger.dart';

class ReferralService {
  final _client = ApiClient();

  Future<Map<String, dynamic>> getReferralCode() async {
    final url = '${UrlConstants.baseUrl}/referrals';

    AppLogger.log('FETCHING REFERRAL CODE');
    AppLogger.log('URL: $url');
    AppLogger.log('Method: POST');

    try {
      final response = await _client.post(Uri.parse(url));

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
