import 'package:flutter/material.dart';
import 'package:muvam/core/services/referral_service.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/features/referral/data/models/referral_model.dart';
import 'package:share_plus/share_plus.dart';

class ReferralProvider extends ChangeNotifier {
  final ReferralService _referralService = ReferralService();

  ReferralData? _referralData;
  bool _isLoading = false;
  String? _errorMessage;

  ReferralData? get referralData => _referralData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchReferralCode() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      AppLogger.log('Fetching referral code');

      final result = await _referralService.getReferralCode();

      if (result['success'] == true && result['data'] != null) {
        _referralData = ReferralData.fromJson(result['data']);
        _errorMessage = null;
        AppLogger.log('Referral data parsed successfully');
        AppLogger.log('Code: ${_referralData?.code}');
        AppLogger.log('Total Uses: ${_referralData?.totalUses}');
      } else {
        _errorMessage = result['message'] ?? 'Failed to fetch referral code';
        _referralData = null;
        AppLogger.log('Failed to fetch referral: $_errorMessage');
      }
    } catch (e) {
      _errorMessage = 'Error fetching referral code: $e';
      AppLogger.log('Exception in fetchReferralCode: $e');
      _referralData = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> shareReferralCode() async {
    if (_referralData == null) {
      AppLogger.log('No referral data available to share');
      return;
    }

    try {
      final String message =
          'Join Muvam using my referral code: ${_referralData!.code}\n\n'
          'Download the app and sign up here:\n${_referralData!.shareUrl}\n\n'
          'Get amazing rides with Muvam!';

      AppLogger.log('Sharing referral code: ${_referralData!.code}');
      AppLogger.log('Share URL: ${_referralData!.shareUrl}');

      await Share.share(message, subject: 'Join Muvam with my referral code');

      AppLogger.log('Referral code shared successfully');
    } catch (e) {
      AppLogger.log('Error sharing referral code: $e');
      _errorMessage = 'Failed to share referral code';
      notifyListeners();
    }
  }

  void clearData() {
    _referralData = null;
    _errorMessage = null;
    notifyListeners();
  }
}
