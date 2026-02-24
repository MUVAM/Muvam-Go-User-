import 'dart:convert';
import 'package:muvam/core/services/api_client.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/features/home/data/models/favourite_location_models.dart';
import '../constants/url_constants.dart';

class FavouriteLocationService {
  final _client = ApiClient();

  Future<void> addFavouriteLocation(FavouriteLocationRequest request) async {
    final url = '${UrlConstants.baseUrl}${UrlConstants.favouriteLocation}';
    final requestBody = jsonEncode(request.toJson());

    AppLogger.log('Adding favourite location:');
    AppLogger.log('URL: $url');
    AppLogger.log('Request Body: $requestBody');

    final response = await _client.post(Uri.parse(url), body: requestBody);

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
    final url = '${UrlConstants.baseUrl}${UrlConstants.favouriteLocation}';

    AppLogger.log('Getting favourite locations:');
    AppLogger.log('URL: $url');

    final response = await _client.get(Uri.parse(url));

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
    final response = await _client.delete(
      Uri.parse(
        '${UrlConstants.baseUrl}${UrlConstants.favouriteLocation}/$favId',
      ),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete favourite location: ${response.body}');
    }
  }
}
