import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:muvam/core/constants/url_constants.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/features/profile/data/models/profile_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileService {
  Future<ProfileResponse?> getUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        AppLogger.log('No auth token found');
        return null;
      }

      final url = '${UrlConstants.baseUrl}${UrlConstants.userProfile}';
      AppLogger.log('Fetching user profile from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.log('Profile Response Status: ${response.statusCode}');
      AppLogger.log('Profile Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final profileResponse = ProfileResponse.fromJson(data);

        await _cacheUserData(profileResponse.user);

        AppLogger.log('Profile fetched successfully');
        AppLogger.log('User: ${profileResponse.user.fullName}');
        AppLogger.log('Email: ${profileResponse.user.email}');
        AppLogger.log('Role: ${profileResponse.user.role}');

        return profileResponse;
      } else {
        AppLogger.log('Failed to fetch profile: ${response.body}');
        return null;
      }
    } catch (e) {
      AppLogger.log('Error fetching profile: $e');
      return null;
    }
  }

  Future<void> _cacheUserData(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('user_id', user.id.toString());
    await prefs.setString('user_first_name', user.firstName);
    await prefs.setString('user_middle_name', user.middleName);
    await prefs.setString('user_last_name', user.lastName);
    await prefs.setString('user_full_name', user.fullName);
    await prefs.setString('user_email', user.email);
    await prefs.setString('user_phone', user.phone);
    await prefs.setString('user_city', user.city);
    await prefs.setString('user_role', user.role);
    await prefs.setString('user_profile_photo', user.profilePhoto);
    await prefs.setString('user_date_of_birth', user.dateOfBirth);
    await prefs.setBool('user_profile_complete', user.profileComplete);
    await prefs.setDouble('user_average_rating', user.averageRating);
    await prefs.setInt('user_rating_count', user.ratingCount);

    AppLogger.log('User data cached locally');
  }

  Future<Map<String, String?>> getCachedUserData() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'user_id': prefs.getString('user_id'),
      'user_first_name': prefs.getString('user_first_name'),
      'user_middle_name': prefs.getString('user_middle_name'),
      'user_last_name': prefs.getString('user_last_name'),
      'user_full_name': prefs.getString('user_full_name'),
      'user_email': prefs.getString('user_email'),
      'user_phone': prefs.getString('user_phone'),
      'user_city': prefs.getString('user_city'),
      'user_role': prefs.getString('user_role'),
      'user_profile_photo': prefs.getString('user_profile_photo'),
      'user_date_of_birth': prefs.getString('user_date_of_birth'),
    };
  }

  Future<void> clearCachedUserData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('user_id');
    await prefs.remove('user_first_name');
    await prefs.remove('user_middle_name');
    await prefs.remove('user_last_name');
    await prefs.remove('user_full_name');
    await prefs.remove('user_email');
    await prefs.remove('user_phone');
    await prefs.remove('user_city');
    await prefs.remove('user_role');
    await prefs.remove('user_profile_photo');
    await prefs.remove('user_date_of_birth');
    await prefs.remove('user_profile_complete');
    await prefs.remove('user_average_rating');
    await prefs.remove('user_rating_count');

    AppLogger.log('User data cleared from cache');
  }
}
