import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/url_constants.dart';
import '../models/favourite_location_models.dart';

class FavouriteLocationService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> addFavouriteLocation(FavouriteLocationRequest request) async {
    final token = await _getToken();
    final url = '${UrlConstants.baseUrl}${UrlConstants.favouriteLocation}';
    final requestBody = jsonEncode(request.toJson());
    
    print('🔄 Adding favourite location:');
    print('URL: $url');
    print('Token: ${token?.substring(0, 20)}...');
    print('Request Body: $requestBody');
    
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: requestBody,
    );

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('Response Headers: ${response.headers}');

    if (response.statusCode != 200 && response.statusCode != 201 && response.statusCode != 202) {
      throw Exception('Failed to add favourite location. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<List<FavouriteLocation>> getFavouriteLocations() async {
    final token = await _getToken();
    final url = '${UrlConstants.baseUrl}${UrlConstants.favouriteLocation}';
    
    print('🔄 Getting favourite locations:');
    print('URL: $url');
    print('Token: ${token?.substring(0, 20)}...');
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print('Raw response data: $data');
      print('Parsed ${data.length} favourite locations');
      
      final List<FavouriteLocation> locations = [];
      for (int i = 0; i < data.length; i++) {
        try {
          print('Processing item $i: ${data[i]}');
          locations.add(FavouriteLocation.fromJson(data[i]));
        } catch (e) {
          print('Error parsing favourite location $i: $e');
        }
      }
      return locations;
    } else {
      throw Exception('Failed to get favourite locations. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  Future<void> deleteFavouriteLocation(int favId) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.favouriteLocation}/$favId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete favourite location: ${response.body}');
    }
  }
}