import 'package:flutter/material.dart';
import 'package:muvam/core/services/profile_service.dart';

class ProfileProvider with ChangeNotifier {
  final ProfileService _profileService = ProfileService();

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _profileData;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get profileData => _profileData;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  Future<bool> fetchUserProfile() async {
    _setLoading(true);
    _setError(null);

    try {
      _profileData = await _profileService.getUserProfile();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateTip(int tip) async {
    _setLoading(true);
    _setError(null);

    try {
      await _profileService.updateTip(tip);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
}