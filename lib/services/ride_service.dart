import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:muvam/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/url_constants.dart';
import '../models/ride_models.dart';

class RideService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<RideEstimateResponse> estimateRide(RideEstimateRequest request) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.rideEstimate}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(request.toJson()),
    );

    AppLogger.log('Estimate Response Status: ${response.statusCode}');
    AppLogger.log('Estimate Response Body: ${response.body}');

    if (response.statusCode == 200) {
      return RideEstimateResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to estimate ride: ${response.body}');
    }
  }

  Future<RideResponse> requestRide(RideRequest request) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.rideRequest}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(request.toJson()),
    );

    AppLogger.log('Ride Request Response Status: ${response.statusCode}');
    AppLogger.log('Ride Request Response Body: ${response.body}');

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
}
