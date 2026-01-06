import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/features/home/data/models/favourite_location_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/url_constants.dart';

class FavouriteLocationService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> addFavouriteLocation(FavouriteLocationRequest request) async {
    final token = await _getToken();
    final url = '${UrlConstants.baseUrl}${UrlConstants.favouriteLocation}';
    final requestBody = jsonEncode(request.toJson());

    AppLogger.log('Adding favourite location:');
    AppLogger.log('URL: $url');
    AppLogger.log('Token: ${token?.substring(0, 20)}...');
    AppLogger.log('Request Body: $requestBody');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: requestBody,
    );

    AppLogger.log('Response Status: ${response.statusCode}');
    AppLogger.log('Response Body: ${response.body}');
    AppLogger.log('Response Headers: ${response.headers}');

    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 202) {
      throw Exception(
        'Failed to add favourite location. Status: ${response.statusCode}, Body: ${response.body}',
      );
    }
  }

  Future<List<FavouriteLocation>> getFavouriteLocations() async {
    final token = await _getToken();
    final url = '${UrlConstants.baseUrl}${UrlConstants.favouriteLocation}';

    AppLogger.log('Getting favourite locations:');
    AppLogger.log('URL: $url');
    AppLogger.log('Token: ${token?.substring(0, 20)}...');

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    AppLogger.log('Response Status: ${response.statusCode}');
    AppLogger.log('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      AppLogger.log('Raw response data: $data');
      AppLogger.log('Parsed ${data.length} favourite locations');

      final List<FavouriteLocation> locations = [];
      for (int i = 0; i < data.length; i++) {
        try {
          AppLogger.log('Processing item $i: ${data[i]}');
          locations.add(FavouriteLocation.fromJson(data[i]));
        } catch (e) {
          AppLogger.log('Error parsing favourite location $i: $e');
        }
      }
      return locations;
    } else {
      throw Exception(
        'Failed to get favourite locations. Status: ${response.statusCode}, Body: ${response.body}',
      );
    }
  }

  Future<void> deleteFavouriteLocation(int favId) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse(
        '${UrlConstants.baseUrl}${UrlConstants.favouriteLocation}/$favId',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete favourite location: ${response.body}');
    }
  }
}
