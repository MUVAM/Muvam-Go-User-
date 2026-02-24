import 'dart:convert';
import 'dart:math';
import 'package:muvam/core/constants/url_constants.dart';
import 'package:muvam/core/services/api_client.dart';
import 'package:muvam/core/utils/app_logger.dart';

class ActivitiesService {
  final _client = ApiClient();

  Future<Map<String, dynamic>> getRides({
    String? status,
    int? limit,
    int? offset,
  }) async {
    final requestBody = <String, dynamic>{};
    if (status != null) requestBody['status'] = status;

    AppLogger.log('FETCHING RIDES');
    AppLogger.log('URL: ${UrlConstants.baseUrl}${UrlConstants.rides}');
    AppLogger.log('Method: POST');
    AppLogger.log('Status filter: ${status ?? "all"}');
    AppLogger.log('Request Body: ${jsonEncode(requestBody)}');

    try {
      final response = await _client.post(
        Uri.parse('${UrlConstants.baseUrl}${UrlConstants.rides}'),
        body: jsonEncode(requestBody),
      );

      AppLogger.log('Response Status: ${response.statusCode}');
      AppLogger.log('Response Body: ${response.body}');
      AppLogger.log('Response Headers: ${response.headers}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.log(
          'Success: ${data.toString().substring(0, min(200, data.toString().length))}',
        );
        return {'success': true, 'data': data};
      } else {
        AppLogger.log('Failed: ${response.body}');
        return {
          'success': false,
          'message':
              'Failed with status ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      AppLogger.log('Exception in getRides: $e');
      return {'success': false, 'message': 'Exception: $e'};
    } finally {
      AppLogger.log('END FETCHING RIDES');
    }
  }

  Future<Map<String, dynamic>> getRideDetails(int rideId) async {
    final url = '${UrlConstants.baseUrl}${UrlConstants.rides}/$rideId';

    AppLogger.log('FETCHING RIDE DETAILS');
    AppLogger.log('URL: $url');
    AppLogger.log('Method: GET');
    AppLogger.log('Ride ID: $rideId');

    try {
      final response = await _client.get(Uri.parse(url));

      AppLogger.log('Response Status: ${response.statusCode}');
      AppLogger.log('Response Headers: ${response.headers}');
      AppLogger.log('Response boyyyyyyyyyyyyy: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.log(
          'Success: ${data.toString().substring(0, min(200, data.toString().length))}',
        );
        return {'success': true, 'data': data};
      } else {
        AppLogger.log('Failed: ${response.body}');
        return {
          'success': false,
          'message':
              'Failed with status ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      AppLogger.log('Exception in getRideDetails: $e');
      return {'success': false, 'message': 'Exception: $e'};
    } finally {
      AppLogger.log('END FETCHING RIDE DETAILS');
    }
  }

  Future<Map<String, dynamic>> getRidesByStatus(String status) async {
    return getRides(status: status);
  }

  Future<Map<String, dynamic>> getAllRides() async {
    return getRides();
  }

  Future<Map<String, dynamic>> getPrebookedRides() async {
    return getRides(status: 'prebooked');
  }

  Future<Map<String, dynamic>> getActiveRides() async {
    return getRides(status: 'active');
  }

  Future<Map<String, dynamic>> getHistoryRides() async {
    return getRides(status: 'history');
  }
}
