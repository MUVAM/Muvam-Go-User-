import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/features/auth/data/models/auth_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/url_constants.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';

  Future<ApiResponse> sendOtp(String phone) async {
    final response = await http.post(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.sendOtp}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(SendOtpRequest(phone: phone).toJson()),
    );

    if (response.statusCode == 200) {
      return ApiResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to send OTP');
    }
  }

  Future<ApiResponse> resendOtp(String phone) async {
    final response = await http.post(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.resendOtp}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(SendOtpRequest(phone: phone).toJson()),
    );

    if (response.statusCode == 200) {
      return ApiResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to resend OTP');
    }
  }

  Future<VerifyOtpResponse> verifyOtp(String code, String phone) async {
    final requestBody = VerifyOtpRequest(code: code, phone: phone).toJson();
    AppLogger.log('Verify OTP Request Body: $requestBody');

    final response = await http.post(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.verifyOtp}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    AppLogger.log('Verify OTP Response Status: ${response.statusCode}');
    AppLogger.log('Verify OTP Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final result = VerifyOtpResponse.fromJson(responseData);

      if (result.token != null) {
        await _saveTokenData(result.token!);
      }

      // Store user ID, name, and email
      if (responseData['user'] != null) {
        final user = responseData['user'];
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('user_id', user['ID'].toString());

        final firstName = user['first_name'] ?? '';
        final lastName = user['last_name'] ?? '';
        final fullName = '$firstName $lastName'.trim();
        await prefs.setString('user_name', fullName);
        await prefs.setString('user_email', user['Email'] ?? '');

        AppLogger.log('Stored user_id: ${user['ID']}');
        AppLogger.log('Stored user_name: $fullName');
        AppLogger.log('Stored user_email: ${user['Email']}');
      }

      return result;
    } else {
      AppLogger.log('Verify OTP Error: ${response.body}');
      throw Exception('Failed to verify OTP: ${response.body}');
    }
  }

  Future<RegisterUserResponse> registerUser(RegisterUserRequest request) async {
    final requestBody = request.toJson();
    requestBody['service_type'] = 'taxi';
    AppLogger.log('Registration request: $requestBody');

    final response = await http.post(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.registerUser}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    AppLogger.log('Register User Response Status: ${response.statusCode}');
    AppLogger.log('Register User Response Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final result = RegisterUserResponse.fromJson(jsonDecode(response.body));
      await _saveToken(result.token);
      return result;
    } else {
      AppLogger.log('Register User Error: ${response.body}');
      throw Exception('Failed to register user: ${response.body}');
    }
  }

  // NEW METHOD: Register user with custom JSON
  Future<RegisterUserResponse> registerUserWithJson(
    Map<String, dynamic> requestBody,
  ) async {
    AppLogger.log('Registration request with JSON: $requestBody');

    final response = await http.post(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.registerUser}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    AppLogger.log('Register User Response Status: ${response.statusCode}');
    AppLogger.log('Register User Response Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      final result = RegisterUserResponse.fromJson(responseData);

      await _saveToken(result.token);

      // Store user data
      if (responseData['user'] != null) {
        final user = responseData['user'];
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('user_id', user['ID'].toString());

        final firstName = user['first_name'] ?? '';
        final lastName = user['last_name'] ?? '';
        final fullName = '$firstName $lastName'.trim();
        await prefs.setString('user_name', fullName);
        await prefs.setString('user_email', user['Email'] ?? '');

        AppLogger.log('Stored user_id: ${user['ID']}');
        AppLogger.log('Stored user_name: $fullName');
      }

      return result;
    } else {
      AppLogger.log('Register User Error: ${response.body}');
      final errorBody = jsonDecode(response.body);
      throw Exception(
        errorBody['message'] ?? 'Failed to register user: ${response.body}',
      );
    }
  }

  // Save TokenData object with access token, refresh token, and expiry
  Future<void> _saveTokenData(TokenData tokenData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, tokenData.accessToken);
    await prefs.setString(_refreshTokenKey, tokenData.refreshToken);

    // Calculate expiry time based on expires_in (in seconds)
    final expiryTime =
        DateTime.now().millisecondsSinceEpoch + (tokenData.expiresIn * 1000);
    await prefs.setInt(_tokenExpiryKey, expiryTime);

    AppLogger.log('Saved access_token: ${tokenData.accessToken}');
    AppLogger.log('Saved refresh_token: ${tokenData.refreshToken}');
    AppLogger.log('Token expires in: ${tokenData.expiresIn} seconds');
  }

  // Legacy method for backward compatibility (for registerUser)
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setInt(
      'token_timestamp',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final expiryTime = prefs.getInt(_tokenExpiryKey);
    final timestamp = prefs.getInt('token_timestamp'); // For legacy tokens

    AppLogger.log('Stored token: $token');
    AppLogger.log('Token expiry time: $expiryTime');

    if (token != null) {
      // Check new token format with expiry time
      if (expiryTime != null) {
        final currentTime = DateTime.now().millisecondsSinceEpoch;
        if (currentTime >= expiryTime) {
          AppLogger.log('Token expired, clearing...');
          await clearToken();
          return null;
        }
        final remainingTime = (expiryTime - currentTime) / 1000;
        AppLogger.log('Token valid for: $remainingTime seconds');
      }
      // Check legacy token format with timestamp
      else if (timestamp != null) {
        final tokenAge = DateTime.now().millisecondsSinceEpoch - timestamp;
        AppLogger.log('Token age: ${tokenAge / 1000} seconds');
        if (tokenAge > 7200000) {
          // 2 hours in milliseconds
          AppLogger.log('Token expired, clearing...');
          await clearToken();
          return null;
        }
      }
    }

    return token;
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_tokenExpiryKey);
    await prefs.remove('token_timestamp');

    // // Delete FCM token on logout
    // try {
    //   final fcmService = FCMNotificationService();
    //   await fcmService.deleteToken();
    //   AppLogger.log('FCM token deleted on logout', tag: 'AUTH');
    // } catch (e) {
    //   AppLogger.error(
    //     'Error deleting FCM token on logout',
    //     error: e,
    //     tag: 'AUTH',
    //   );
    // }
  }

  Future<bool> isTokenValid() async {
    final token = await getToken();
    return token != null;
  }

  Future<ApiResponse> completeProfile(CompleteProfileRequest request) async {
    final token = await getToken();
    final uri = Uri.parse(
      '${UrlConstants.baseUrl}${UrlConstants.completeProfile}',
    );
    final multipartRequest = http.MultipartRequest('POST', uri);

    multipartRequest.headers['Authorization'] = 'Bearer $token';
    multipartRequest.fields['first_name'] = request.firstName;
    if (request.middleName != null) {
      multipartRequest.fields['middle_name'] = request.middleName!;
    }
    multipartRequest.fields['last_name'] = request.lastName;
    multipartRequest.fields['email'] = request.email;

    if (request.profilePhotoPath != null) {
      final file = File(request.profilePhotoPath!);
      multipartRequest.files.add(
        await http.MultipartFile.fromPath('profile_photo', file.path),
      );
    }

    final response = await multipartRequest.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return ApiResponse.fromJson(jsonDecode(responseBody));
    } else {
      throw Exception('Failed to complete profile');
    }
  }

  Future<void> saveUserData(
    String firstName,
    String lastName,
    String email,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('first_name', firstName);
    await prefs.setString('last_name', lastName);
    await prefs.setString('email', email);
  }

  Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'first_name': prefs.getString('first_name'),
      'last_name': prefs.getString('last_name'),
      'email': prefs.getString('email'),
    };
  }
}
