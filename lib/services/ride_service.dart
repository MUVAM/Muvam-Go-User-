import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/url_constants.dart';
import '../models/ride_models.dart';

class RideService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<RideEstimateResponse> estimateRide(RideEstimateRequest request, String vehicleType) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.rideEstimate}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(request.toJson()),
    );

    print('Estimate Response Status: ${response.statusCode}');
    print('Estimate Response Body: ${response.body}');

    if (response.statusCode == 200) {
      return RideEstimateResponse.fromJson(jsonDecode(response.body), vehicleType);
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

    print('Ride Request Response Status: ${response.statusCode}');
    print('Ride Request Response Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return RideResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to request ride: ${response.body}');
    }
  }
}