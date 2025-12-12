import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/features/activities/data/models/ride_user.dart';
import 'package:muvam/core/constants/url_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActivitiesService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<List<Ride>> getRides({String? status}) async {
    final token = await _getToken();

    final url = '${UrlConstants.baseUrl}${UrlConstants.rides}';

    AppLogger.log('Getting rides: $url');

    final Map<String, dynamic> body = {};

    if (status != null) {
      body['status'] = status;
    }

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    AppLogger.log('Rides response: ${response.statusCode}');
    AppLogger.log('Rides body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      List<dynamic> jsonList;
      if (responseData is List) {
        jsonList = responseData;
      } else if (responseData is Map && responseData['rides'] != null) {
        jsonList = responseData['rides'];
      } else {
        jsonList = [];
      }

      return jsonList.map((json) => Ride.fromJson(json)).toList();
    } else {
      AppLogger.log('Failed to fetch rides: ${response.body}');
      throw Exception('Failed to fetch rides');
    }
  }

  Future<Ride> getRideById(int rideId) async {
    final token = await _getToken();

    final url = '${UrlConstants.baseUrl}/rides/$rideId';

    AppLogger.log('Getting ride details: $url');

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    AppLogger.log('Ride details response: ${response.statusCode}');
    AppLogger.log('Ride details body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return Ride.fromJson(responseData);
    } else {
      AppLogger.log('Failed to fetch ride details: ${response.body}');
      throw Exception('Failed to fetch ride details');
    }
  }
}
