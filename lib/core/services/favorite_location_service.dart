import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:muvam/core/constants/url_constants.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/features/home/data/models/favorite_location_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteLocationService {
  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      AppLogger.error(
        'Failed to retrieve auth token',
        error: e,
        tag: 'FAV_LOCATION',
      );
      return null;
    }
  }

  /// Save a favorite location (home, work, or favourite)
  Future<FavoriteLocationResponse> saveFavoriteLocation({
    required String name, // 'home', 'work', or 'favourite'
    required String destLocation, // POINT format
    required String destAddress,
  }) async {
    AppLogger.log('📍 Saving favorite location: $name', tag: 'FAV_LOCATION');

    final token = await _getToken();

    final requestBody = {
      'name': name,
      'dest_location': destLocation,
      'dest_address': destAddress,
    };

    AppLogger.log(
      'Request body: ${jsonEncode(requestBody)}',
      tag: 'FAV_LOCATION',
    );

    try {
      final response = await http.post(
        Uri.parse('${UrlConstants.baseUrl}${UrlConstants.favouriteLocation}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      AppLogger.log(
        'Save favorite location response status: ${response.statusCode}',
        tag: 'FAV_LOCATION',
      );
      AppLogger.log(
        'Save favorite location response body: ${response.body}',
        tag: 'FAV_LOCATION',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return FavoriteLocationResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to save favorite location: ${response.body}');
      }
    } catch (e) {
      AppLogger.error(
        'Error saving favorite location',
        error: e,
        tag: 'FAV_LOCATION',
      );
      rethrow;
    }
  }

  /// Get all favorite locations
  Future<List<FavoriteLocation>> getFavoriteLocations() async {
    AppLogger.log('📍 Fetching favorite locations', tag: 'FAV_LOCATION');

    final token = await _getToken();

    try {
      final response = await http.get(
        Uri.parse('${UrlConstants.baseUrl}${UrlConstants.favouriteLocation}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.log(
        'Get favorite locations response status: ${response.statusCode}',
        tag: 'FAV_LOCATION',
      );
      AppLogger.log(
        'Get favorite locations response body: ${response.body}',
        tag: 'FAV_LOCATION',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Handle different response formats
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data')) {
            final data = responseData['data'];
            if (data is List) {
              return data
                  .map((item) => FavoriteLocation.fromJson(item))
                  .toList();
            }
          }
        } else if (responseData is List) {
          return responseData
              .map((item) => FavoriteLocation.fromJson(item))
              .toList();
        }

        return [];
      } else {
        throw Exception('Failed to get favorite locations: ${response.body}');
      }
    } catch (e) {
      AppLogger.error(
        'Error getting favorite locations',
        error: e,
        tag: 'FAV_LOCATION',
      );
      return [];
    }
  }

  /// Delete a favorite location
  Future<bool> deleteFavoriteLocation(int id) async {
    AppLogger.log('📍 Deleting favorite location: $id', tag: 'FAV_LOCATION');

    final token = await _getToken();

    try {
      final response = await http.delete(
        Uri.parse(
          '${UrlConstants.baseUrl}${UrlConstants.favouriteLocation}/$id',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.log(
        'Delete favorite location response status: ${response.statusCode}',
        tag: 'FAV_LOCATION',
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      AppLogger.error(
        'Error deleting favorite location',
        error: e,
        tag: 'FAV_LOCATION',
      );
      return false;
    }
  }
}
