import 'package:flutter/material.dart';
import 'package:muvam/core/services/wallet_service.dart';
import 'package:muvam/features/wallet/data/models/wallet_models.dart';

class WalletProvider with ChangeNotifier {
  final WalletService _walletService = WalletService();

  bool _isLoading = false;
  String? _errorMessage;
  CreateVirtualAccountResponse? _virtualAccountResponse;
  Map<String, dynamic> _virtualAccountData = {};
  WalletSummaryResponse? _walletSummary;
  VirtualAccountInfo? _virtualAccountInfo;
  bool _hasVirtualAccount = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  CreateVirtualAccountResponse? get virtualAccountResponse =>
      _virtualAccountResponse;
  Map<String, dynamic> get virtualAccountData => _virtualAccountData;
  WalletSummaryResponse? get walletSummary => _walletSummary;
  VirtualAccountInfo? get virtualAccountInfo => _virtualAccountInfo;
  bool get hasVirtualAccount => _hasVirtualAccount;

  // Getters for easy access to account details
  String? get accountNumber => _virtualAccountData['account_number'];
  String? get accountName => _virtualAccountData['account_name'];
  String? get bankName => _virtualAccountData['bank_name'];
  String? get bankCode => _virtualAccountData['bank_code'];
  double? get walletBalance => _virtualAccountData['wallet_balance'];
  bool get hasAccount => _virtualAccountData['account_number'] != null;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  Future<bool> createVirtualAccount({String? bvn, String? nin}) async {
    if (bvn == null && nin == null) {
      _setError('Either BVN or NIN is required');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      final request = CreateVirtualAccountRequest(
        kyc: KycData(bvn: bvn, nin: nin),
      );

      _virtualAccountResponse = await _walletService.createVirtualAccount(
        request,
      );

      // Save the account data to SharedPreferences
      await _walletService.saveVirtualAccountData(_virtualAccountResponse!);

      // Load the data into the provider
      _virtualAccountData = await _walletService.getVirtualAccountData();

      // Update virtual account status
      _hasVirtualAccount = true;

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  Future<void> loadVirtualAccountData() async {
    _virtualAccountData = await _walletService.getVirtualAccountData();
    notifyListeners();
  }

  Future<bool> checkHasVirtualAccount() async {
    return await _walletService.hasVirtualAccount();
  }

  Future<void> clearVirtualAccount() async {
    await _walletService.clearVirtualAccountData();
    _virtualAccountResponse = null;
    _virtualAccountData = {};
    _hasVirtualAccount = false;
    _virtualAccountInfo = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String getFormattedBalance() {
    final balance = walletBalance ?? 0.0;
    return '₦${balance.toStringAsFixed(2)}';
  }

  // Wallet Summary Methods
  Future<bool> fetchWalletSummary() async {
    _setLoading(true);
    _setError(null);

    try {
      _walletSummary = await _walletService.getWalletSummary();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  String formatAmount(double amount) {
    return '₦${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  String formatDateTime(String dateTime) {
    try {
      final dt = DateTime.parse(dateTime);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final month = months[dt.month - 1];
      final day = dt.day;
      final year = dt.year;
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$month $day, $year • $hour:$minute $period';
    } catch (e) {
      return dateTime;
    }
  }

  // Check Virtual Account - NEW METHOD
  Future<bool> checkVirtualAccount() async {
    _setLoading(true);
    _setError(null);

    try {
      _virtualAccountInfo = await _walletService.getVirtualAccount();
      _hasVirtualAccount = _virtualAccountInfo != null;
      _setLoading(false);
      return _hasVirtualAccount;
    } catch (e) {
      _hasVirtualAccount = false;
      _virtualAccountInfo = null;
      _setLoading(false);
      return false;
    }
  }
}
