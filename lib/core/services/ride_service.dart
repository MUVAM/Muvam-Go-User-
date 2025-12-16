import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:muvam/core/constants/url_constants.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/features/home/data/models/ride_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RideService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<RideEstimateResponse> estimateRide(RideEstimateRequest request) async {
    final token = await _getToken();
    final requestBody = request.toJson();
    
    AppLogger.log('=== RIDE ESTIMATE REQUEST ===');
    AppLogger.log('URL: ${UrlConstants.baseUrl}${UrlConstants.rideEstimate}');
    AppLogger.log('Headers: {"Content-Type": "application/json", "Authorization": "Bearer ${token?.substring(0, 20)}..."}');
    AppLogger.log('Request Body: ${jsonEncode(requestBody)}');
    
    final response = await http.post(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.rideEstimate}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );

    AppLogger.log('=== RIDE ESTIMATE RESPONSE ===');
    AppLogger.log('Response Status: ${response.statusCode}');
    AppLogger.log('Response Headers: ${response.headers}');
    AppLogger.log('Response Body: ${response.body}');
    AppLogger.log('=== END RIDE ESTIMATE ===');

    if (response.statusCode == 200) {
      return RideEstimateResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to estimate ride: ${response.body}');
    }
  }

  Future<RideResponse> requestRide(RideRequest request) async {
    final token = await _getToken();
    final requestBody = request.toJson();

    AppLogger.log('=== RIDE REQUEST DEBUG ===');
    AppLogger.log('Request URL: ${UrlConstants.baseUrl}${UrlConstants.rideRequest}');
    AppLogger.log('Request Headers: {"Content-Type": "application/json", "Authorization": "Bearer ${token?.substring(0, 20)}..."}');
    AppLogger.log('🚗 PAYMENT METHOD IN REQUEST: ${request.paymentMethod}');
    AppLogger.log('📋 FULL REQUEST BODY: ${jsonEncode(requestBody)}');
    AppLogger.log('🔍 REQUEST BODY BREAKDOWN:');
    requestBody.forEach((key, value) {
      AppLogger.log('  $key: $value');
    });

    final response = await http.post(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.rideRequest}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );

    AppLogger.log('=== RIDE REQUEST RESPONSE ===');
    AppLogger.log('Response Status: ${response.statusCode}');
    AppLogger.log('Response Headers: ${response.headers}');
    AppLogger.log('📥 FULL RESPONSE BODY: ${response.body}');
    
    if (response.body.isNotEmpty) {
      try {
        final responseJson = jsonDecode(response.body);
        AppLogger.log('🔍 RESPONSE BODY BREAKDOWN:');
        if (responseJson is Map<String, dynamic>) {
          responseJson.forEach((key, value) {
            AppLogger.log('  $key: $value');
          });
        }
      } catch (e) {
        AppLogger.log('❌ Failed to parse response JSON: $e');
      }
    }
    AppLogger.log('=== END RIDE REQUEST ===');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return RideResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to request ride: ${response.body}');
    }
  }

  Future<List<dynamic>> getNearbyRides() async {
    final token = await _getToken();
    AppLogger.log(
      'Using token for nearby rides: ${token?.substring(0, 20)}...',
    );

    final response = await http.get(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.nearbyRides}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    AppLogger.log('Nearby Rides Response Status: ${response.statusCode}');
    AppLogger.log('Nearby Rides Response Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get nearby rides: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getActiveRides() async {
    final token = await _getToken();
    AppLogger.log('=== CHECKING ACTIVE RIDES ===');
    AppLogger.log('Token: ${token?.substring(0, 20)}...');

    final response = await http.post(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.activeRides}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': 'active'}),
    );

    AppLogger.log('Active Rides Response Status: ${response.statusCode}');
    AppLogger.log('Active Rides Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {'success': true, 'data': data};
    } else {
      return {
        'success': false,
        'message': 'Failed to get active rides: ${response.body}',
      };
    }
  }

  Future<Map<String, dynamic>> getRideDetails(int rideId) async {
    final token = await _getToken();
    
    final response = await http.get(
      Uri.parse('${UrlConstants.baseUrl}/api/v1/rides/$rideId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return {'success': true, 'data': jsonDecode(response.body)};
    } else {
      return {
        'success': false,
        'message': 'Failed to get ride details: ${response.body}',
      };
    }
  }

  Future<Map<String, dynamic>> rateRide({
    required int rideId,
    required int score,
    required String comment,
  }) async {
    final token = await _getToken();
    final url = '${UrlConstants.baseUrl}/rides/$rideId/rate';
    final requestBody = {
      'comment': comment,
      'score': score,
    };
    
    AppLogger.log('=== RATE RIDE REQUEST ===', tag: 'RATING');
    AppLogger.log('URL: $url', tag: 'RATING');
    AppLogger.log('Request Body: ${jsonEncode(requestBody)}', tag: 'RATING');
    
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );

    AppLogger.log('Response Status: ${response.statusCode}', tag: 'RATING');
    AppLogger.log('Response Body: ${response.body}', tag: 'RATING');
    AppLogger.log('=== END RATE RIDE ===', tag: 'RATING');

    if (response.statusCode == 200) {
      return {'success': true, 'data': jsonDecode(response.body)};
    } else {
      return {
        'success': false,
        'message': 'Failed to rate ride: ${response.body}',
      };
    }
  }
}
