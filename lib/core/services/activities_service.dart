import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:muvam/core/constants/url_constants.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActivitiesService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, dynamic>> getRides({
    String? status,
    int? limit,
    int? offset,
  }) async {
    final token = await _getToken();

    if (token == null) {
      AppLogger.log('No auth token found');
      return {'success': false, 'message': 'No authentication token'};
    }

    final requestBody = <String, dynamic>{};
    if (status != null) requestBody['status'] = status;
    if (limit != null) requestBody['limit'] = limit;
    if (offset != null) requestBody['offset'] = offset;

    AppLogger.log('FETCHING RIDES');
    AppLogger.log('URL: ${UrlConstants.baseUrl}${UrlConstants.rides}');
    AppLogger.log('Method: POST');
    AppLogger.log('Status filter: ${status ?? "all"}');
    AppLogger.log('Request Body: ${jsonEncode(requestBody)}');
    AppLogger.log('Token: ${token.substring(0, 20)}...');

    try {
      final response = await http.post(
        Uri.parse('${UrlConstants.baseUrl}${UrlConstants.rides}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      AppLogger.log('Response Status: ${response.statusCode}');
      AppLogger.log('Response bodyy--++++--: ${response.body}');
      AppLogger.log('Response Headers: ${response.headers}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.log(
          'Successssss: ${data.toString().substring(0, min(200, data.toString().length))}',
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
    final token = await _getToken();

    if (token == null) {
      AppLogger.log('No auth token found');
      return {'success': false, 'message': 'No authentication token'};
    }

    final url = '${UrlConstants.baseUrl}${UrlConstants.rides}/$rideId';

    AppLogger.log('FETCHING RIDE DETAILS');
    AppLogger.log('URL: $url');
    AppLogger.log('Method: GET');
    AppLogger.log('Ride ID: $rideId');
    AppLogger.log('Token: ${token.substring(0, 20)}...');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.log('Response Status: ${response.statusCode}');
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
