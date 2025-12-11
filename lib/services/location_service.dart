import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/url_constants.dart';
import '../models/location_models.dart';

class LocationService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<List<FavouriteLocation>> getFavouriteLocations() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.favouriteLocation}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => FavouriteLocation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch favourite locations');
    }
  }

  Future<void> addFavouriteLocation(AddFavouriteRequest request) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.favouriteLocation}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add favourite location');
    }
  }

  Future<void> deleteFavouriteLocation(int favId) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.favouriteLocation}/$favId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete favourite location');
    }
  }

  Future<void> saveRecentLocation(String name, String address) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recentLocations = prefs.getStringList('recent_locations') ?? [];
    
    final locationData = jsonEncode({'name': name, 'address': address});
    recentLocations.removeWhere((item) => jsonDecode(item)['name'] == name);
    recentLocations.insert(0, locationData);
    
    if (recentLocations.length > 10) {
      recentLocations = recentLocations.take(10).toList();
    }
    
    await prefs.setStringList('recent_locations', recentLocations);
  }

  Future<List<RecentLocation>> getRecentLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final recentLocations = prefs.getStringList('recent_locations') ?? [];
    
    return recentLocations.map((item) {
      final data = jsonDecode(item);
      return RecentLocation(
        name: data['name'],
        address: data['address'],
      );
    }).toList();
  }
}