import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/url_constants.dart';
import '../models/auth_models.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';

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
    print('Verify OTP Request Body: $requestBody');
    
    final response = await http.post(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.verifyOtp}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    print('Verify OTP Response Status: ${response.statusCode}');
    print('Verify OTP Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final result = VerifyOtpResponse.fromJson(jsonDecode(response.body));
      if (result.token != null) {
        await _saveToken(result.token!);
      }
      return result;
    } else {
      print('Verify OTP Error: ${response.body}');
      throw Exception('Failed to verify OTP: ${response.body}');
    }
  }

  Future<RegisterUserResponse> registerUser(RegisterUserRequest request) async {
    final requestBody = request.toJson();
    requestBody['service_type'] = 'taxi'; // Force add service_type
    print('Registration request: $requestBody');
    
    final response = await http.post(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.registerUser}'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    print('Register User Response Status: ${response.statusCode}');
    print('Register User Response Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final result = RegisterUserResponse.fromJson(jsonDecode(response.body));
      await _saveToken(result.token);
      return result;
    } else {
      print('Register User Error: ${response.body}');
      throw Exception('Failed to register user: ${response.body}');
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setInt('token_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final timestamp = prefs.getInt('token_timestamp');
    
    print('Stored token: $token');
    print('Token timestamp: $timestamp');
    
    if (token != null && timestamp != null) {
      final tokenAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      print('Token age: ${tokenAge / 1000} seconds');
      if (tokenAge > 7200000) { // 2 hours in milliseconds
        print('Token expired, clearing...');
        await clearToken();
        return null;
      }
    }
    
    return token;
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove('token_timestamp');
  }

  Future<bool> isTokenValid() async {
    final token = await getToken();
    return token != null;
  }

  Future<ApiResponse> completeProfile(CompleteProfileRequest request) async {
    final token = await getToken();
    final uri = Uri.parse('${UrlConstants.baseUrl}${UrlConstants.completeProfile}');
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

  Future<void> saveUserData(String firstName, String lastName, String email) async {
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