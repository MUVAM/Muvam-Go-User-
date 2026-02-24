import 'dart:convert';
import 'package:muvam/core/constants/url_constants.dart';
import 'package:muvam/core/services/api_client.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/features/home/data/models/favorite_location_model.dart';

class FavoriteLocationService {
  final _client = ApiClient();

  // Save a favorite location (home, work, or favourite)
  Future<FavoriteLocationResponse> saveFavoriteLocation({
    required String name,
    required String destLocation,
    required String destAddress,
  }) async {
    AppLogger.log('Saving favorite location: $name', tag: 'FAV_LOCATION');

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
      final response = await _client.post(
        Uri.parse('${UrlConstants.baseUrl}${UrlConstants.favouriteLocation}/'),
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

  // Get all favorite locations
  Future<List<FavoriteLocation>> getFavoriteLocations() async {
    AppLogger.log('Fetching favorite locations', tag: 'FAV_LOCATION');

    try {
      final response = await _client.get(
        Uri.parse('${UrlConstants.baseUrl}${UrlConstants.favouriteLocation}/'),
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

  // Delete a favorite location
  Future<bool> deleteFavoriteLocation(int id) async {
    AppLogger.log('Deleting favorite location: $id', tag: 'FAV_LOCATION');

    try {
      final response = await _client.delete(
        Uri.parse(
          '${UrlConstants.baseUrl}${UrlConstants.favouriteLocation}/$id',
        ),
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
