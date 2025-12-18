import 'package:flutter/material.dart';
import 'package:muvam/core/services/auth_service.dart';
import '../models/auth_models.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  VerifyOtpResponse? _verifyOtpResponse;
  RegisterUserResponse? _registerUserResponse;
  Map<String, String?> _userData = {};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  VerifyOtpResponse? get verifyOtpResponse => _verifyOtpResponse;
  RegisterUserResponse? get registerUserResponse => _registerUserResponse;
  Map<String, String?> get userData => _userData;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  Future<bool> sendOtp(String phone) async {
    _setLoading(true);
    _setError(null);

    try {
      await _authService.sendOtp(phone);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resendOtp(String phone) async {
    _setLoading(true);
    _setError(null);

    try {
      await _authService.resendOtp(phone);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyOtp(String code, String phone) async {
    _setLoading(true);
    _setError(null);

    try {
      _verifyOtpResponse = await _authService.verifyOtp(code, phone);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> registerUser(RegisterUserRequest request) async {
    _setLoading(true);
    _setError(null);

    try {
      _registerUserResponse = await _authService.registerUser(request);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // NEW METHOD: Register user with custom JSON
  Future<bool> registerUserWithJson(Map<String, dynamic> requestJson) async {
    _setLoading(true);
    _setError(null);

    try {
      _registerUserResponse = await _authService.registerUserWithJson(
        requestJson,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> completeProfile(CompleteProfileRequest request) async {
    _setLoading(true);
    _setError(null);

    try {
      await _authService.completeProfile(request);
      await _authService.saveUserData(
        request.firstName,
        request.lastName,
        request.email,
      );
      _userData = await _authService.getUserData();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> loadUserData() async {
    _userData = await _authService.getUserData();
    notifyListeners();
  }

  Future<bool> checkTokenValidity() async {
    return await _authService.isTokenValid();
  }

  Future<void> logout() async {
    await _authService.clearToken();
    _verifyOtpResponse = null;
    _registerUserResponse = null;
    _userData = {};
    notifyListeners();
  }
}
