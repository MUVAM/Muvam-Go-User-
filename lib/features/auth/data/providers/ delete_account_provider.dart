import 'package:flutter/material.dart';
import 'package:muvam/core/services/delete_account_service.dart';
import 'package:muvam/core/utils/app_logger.dart';

class DeleteAccountProvider extends ChangeNotifier {
  final DeleteAccountService _deleteAccountService = DeleteAccountService();

  bool _isDeleting = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isDeleting => _isDeleting;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<bool> deleteAccount(String reason) async {
    _isDeleting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      AppLogger.log('Deleting account with reason: $reason');

      final result = await _deleteAccountService.deleteAccount(reason);

      if (result['success'] == true) {
        _successMessage = result['message'] ?? 'Account deleted successfully';
        _errorMessage = null;
        AppLogger.log('Success: $_successMessage');
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to delete account';
        _successMessage = null;
        AppLogger.log('Failed: $_errorMessage');
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error deleting account: $e';
      _successMessage = null;
      AppLogger.log('Exception in deleteAccount: $e');
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
