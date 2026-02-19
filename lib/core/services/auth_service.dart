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
      String errorMessage = 'Failed to verify OTP';

      try {
        final errorData = jsonDecode(response.body);
        errorMessage =
            errorData['error'] ??
            errorData['message'] ??
            'Failed to verify OTP';
      } catch (e) {
        errorMessage = 'Failed to verify OTP';
      }

      AppLogger.log('Verify OTP Error: $errorMessage');
      throw Exception(errorMessage);
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
      await _saveToken(result.token.accessToken);
      return result;
    } else {
      AppLogger.log('Register User Error: ${response.body}');
      throw Exception('Failed to register user: ${response.body}');
    }
  }

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

      await _saveToken(result.token.accessToken);

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

      String errorMessage =
          errorBody['error'] ??
          errorBody['message'] ??
          'Failed to register user';

      throw Exception(errorMessage);
    }
  }

  Future<void> _saveTokenData(TokenData tokenData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, tokenData.accessToken);
    await prefs.setString(_refreshTokenKey, tokenData.refreshToken);

    // Access token expires in 1 hour (3600 seconds)
    final expiryTime =
        DateTime.now().millisecondsSinceEpoch + (tokenData.expiresIn * 1000);
    await prefs.setInt(_tokenExpiryKey, expiryTime);

    AppLogger.log(
      '✅ Saved access_token: ${tokenData.accessToken}',
      tag: 'AUTH',
    );
    AppLogger.log(
      '✅ Saved refresh_token: ${tokenData.refreshToken}',
      tag: 'AUTH',
    );
    AppLogger.log(
      '⏰ Access token expires in: ${tokenData.expiresIn} seconds (1 hour)',
      tag: 'AUTH',
    );

    final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryTime);
    AppLogger.log('📅 Token will expire at: $expiryDate', tag: 'AUTH');
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    // Default to 1 hour expiry if not provided
    final expiryTime = DateTime.now().millisecondsSinceEpoch + (3600 * 1000);
    await prefs.setInt(_tokenExpiryKey, expiryTime);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final expiryTime = prefs.getInt(_tokenExpiryKey);

    if (token == null) {
      AppLogger.log('❌ No token found', tag: 'AUTH');
      return null;
    }

    if (expiryTime != null) {
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final bufferTime = 5 * 60 * 1000; // 5 minutes before expiry

      // Check if token has already expired
      if (currentTime >= expiryTime) {
        AppLogger.log(
          '⚠️ Token has expired, attempting refresh...',
          tag: 'AUTH',
        );
        final refreshed = await refreshToken();
        if (refreshed) {
          return await getToken();
        } else {
          AppLogger.log('❌ Token refresh failed, clearing tokens', tag: 'AUTH');
          await clearToken();
          return null;
        }
      }

      // Check if token is expiring soon (within 5 minutes)
      if (currentTime >= (expiryTime - bufferTime)) {
        AppLogger.log('🔄 Token expiring soon, refreshing...', tag: 'AUTH');
        final refreshed = await refreshToken();
        if (refreshed) {
          return await getToken();
        }
        // If refresh fails but token is still valid, continue using it
      }

      final remainingTime = (expiryTime - currentTime) / 1000 / 60;
      AppLogger.log(
        '✅ Token valid for: ${remainingTime.toStringAsFixed(1)} minutes',
        tag: 'AUTH',
      );
    }

    return token;
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<bool> refreshToken() async {
    try {
      final refreshToken = await getRefreshToken();

      if (refreshToken == null) {
        AppLogger.log('❌ No refresh token available', tag: 'AUTH');
        return false;
      }

      AppLogger.log('🔄 Attempting to refresh token...', tag: 'AUTH');

      final response = await http
          .post(
            Uri.parse('${UrlConstants.baseUrl}${UrlConstants.refreshToken}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Token refresh request timed out');
            },
          );

      AppLogger.log(
        '📡 Refresh response status: ${response.statusCode}',
        tag: 'AUTH',
      );
      AppLogger.log('📄 Refresh response body: ${response.body}', tag: 'AUTH');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['token'] != null) {
          final tokenData = TokenData.fromJson(responseData['token']);
          await _saveTokenData(tokenData);

          AppLogger.log('✅ Token refreshed successfully!', tag: 'AUTH');
          return true;
        } else {
          AppLogger.log('❌ Invalid response structure', tag: 'AUTH');
          return false;
        }
      } else {
        AppLogger.log('❌ Token refresh failed: ${response.body}', tag: 'AUTH');
        return false;
      }
    } catch (e) {
      AppLogger.log('❌ Token refresh error: $e', tag: 'AUTH');
      return false;
    }
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_tokenExpiryKey);
    AppLogger.log('🗑️ All tokens cleared', tag: 'AUTH');
  }

  Future<bool> isTokenValid() async {
    final token = await getToken();
    final isValid = token != null;
    AppLogger.log('🔐 Token validity check: $isValid', tag: 'AUTH');
    return isValid;
  }

  Future<ApiResponse> completeProfile(CompleteProfileRequest request) async {
    final token = await getToken();
    final uri = Uri.parse(
      '${UrlConstants.baseUrl}${UrlConstants.completeProfile}',
    );
    final multipartRequest = http.MultipartRequest('POST', uri);

    multipartRequest.headers['Authorization'] = 'Bearer $token';
    multipartRequest.fields['first_name'] = request.firstName;
    if (request.middleName != null && request.middleName!.isNotEmpty) {
      multipartRequest.fields['middle_name'] = request.middleName!;
    }
    multipartRequest.fields['last_name'] = request.lastName;
    multipartRequest.fields['email'] = request.email;

    // Add city field if provided
    if (request.city != null && request.city!.isNotEmpty) {
      multipartRequest.fields['city'] = request.city!;
      AppLogger.log('Adding city to profile update: ${request.city}');
    }

    if (request.profilePhotoPath != null) {
      final file = File(request.profilePhotoPath!);
      multipartRequest.files.add(
        await http.MultipartFile.fromPath('profile_photo', file.path),
      );
      AppLogger.log('Adding profile photo: ${request.profilePhotoPath}');
    }

    AppLogger.log(
      'Complete Profile Request Fields: ${multipartRequest.fields}',
    );

    final response = await multipartRequest.send();
    final responseBody = await response.stream.bytesToString();

    AppLogger.log('Complete Profile Response Status: ${response.statusCode}');
    AppLogger.log('Complete Profile Response Body: $responseBody');

    if (response.statusCode == 200) {
      return ApiResponse.fromJson(jsonDecode(responseBody));
    } else {
      throw Exception('Failed to complete profile: $responseBody');
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
