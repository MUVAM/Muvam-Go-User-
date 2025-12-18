import 'package:flutter/material.dart';
import 'package:muvam/core/services/user_profile_service.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/features/profile/data/models/profile_models.dart';

class UserProfileProvider with ChangeNotifier {
  final UserProfileService _profileService = UserProfileService();

  ProfileResponse? _profileResponse;
  bool _isLoading = false;
  String? _errorMessage;

  ProfileResponse? get profileResponse => _profileResponse;
  UserProfile? get userProfile => _profileResponse?.user;
  Vehicle? get defaultVehicle => _profileResponse?.defaultVehicle;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get userName => userProfile?.fullName ?? 'User';
  String get userShortName => userProfile?.shortName ?? 'User';
  String get userFirstName => userProfile?.firstName ?? '';
  String get userMiddleName => userProfile?.middleName ?? '';
  String get userLastName => userProfile?.lastName ?? '';
  String get userEmail => userProfile?.email ?? '';
  String get userPhone => userProfile?.phone ?? '';
  String get userCity => userProfile?.city ?? '';
  String get userProfilePhoto => userProfile?.profilePhoto ?? '';
  String get userDateOfBirth => userProfile?.dateOfBirth ?? '';
  double get userRating => userProfile?.averageRating ?? 0.0;
  int get ratingCount => userProfile?.ratingCount ?? 0;
  int get defaultTip => userProfile?.defaultTip ?? 0;
  bool get isProfileComplete => userProfile?.profileComplete ?? false;

  Future<bool> fetchUserProfile() async {
    AppLogger.log('UserProfileProvider: Fetching user profile');

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final profile = await _profileService.getUserProfile();

      if (profile != null) {
        _profileResponse = profile;
        _isLoading = false;
        notifyListeners();

        AppLogger.log('UserProfileProvider: Profile loaded successfully');
        AppLogger.log('User: ${profile.user.fullName}');
        AppLogger.log('Email: ${profile.user.email}');
        AppLogger.log('Phone: ${profile.user.phone}');
        AppLogger.log('City: ${profile.user.city}');

        return true;
      } else {
        _errorMessage = 'Failed to load profile';
        _isLoading = false;
        notifyListeners();

        AppLogger.log('UserProfileProvider: Failed to load profile');
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();

      AppLogger.log('UserProfileProvider: Error - $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getCachedUserData() async {
    return await _profileService.getCachedUserData();
  }

  Future<void> clearProfile() async {
    _profileResponse = null;
    _errorMessage = null;
    await _profileService.clearCachedUserData();
    notifyListeners();

    AppLogger.log('UserProfileProvider: Profile cleared');
  }

  Future<void> refreshProfile() async {
    AppLogger.log('UserProfileProvider: Refreshing profile');
    await fetchUserProfile();
  }
}
