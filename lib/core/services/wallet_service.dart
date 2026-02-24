import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:muvam/core/services/api_client.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/features/wallet/data/models/wallet_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muvam/core/constants/url_constants.dart';

class WalletService {
  final _client = ApiClient();

  Future<CreateVirtualAccountResponse> createVirtualAccount(
    CreateVirtualAccountRequest request,
  ) async {
    AppLogger.log('Creating virtual account…');

    final response = await _client.post(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.createVirtualAccount}'),
      body: jsonEncode(request.toJson()),
    );

    AppLogger.log('Create virtual account response: ${response.statusCode}');

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 202) {
      AppLogger.log('Virtual account createdddddd: ${response.body}');
      final jsonResponse = jsonDecode(response.body);
      return CreateVirtualAccountResponse.fromJson(jsonResponse);
    } else {
      AppLogger.log('Failed to create virtual account: ${response.body}');
      final errorBody = jsonDecode(response.body);
      throw Exception(
        errorBody['message'] ?? 'Failed to create virtual account',
      );
    }
  }

  Future<void> saveVirtualAccountData(
    CreateVirtualAccountResponse accountData,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('account_number', accountData.accountNumber);
    await prefs.setString('account_name', accountData.accountName);
    await prefs.setString('bank_name', accountData.bankName);
    await prefs.setString('bank_code', accountData.bankCode);
    await prefs.setString('currency', accountData.currency);
    await prefs.setInt('wallet_id', accountData.walletId);

    if (accountData.wallet != null) {
      await prefs.setDouble('wallet_balance', accountData.wallet!.balance);
      await prefs.setBool('wallet_verified', accountData.wallet!.isVerified);
    }
  }

  Future<Map<String, dynamic>> getVirtualAccountData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'account_number': prefs.getString('account_number'),
      'account_name': prefs.getString('account_name'),
      'bank_name': prefs.getString('bank_name'),
      'bank_code': prefs.getString('bank_code'),
      'currency': prefs.getString('currency'),
      'wallet_id': prefs.getInt('wallet_id'),
      'wallet_balance': prefs.getDouble('wallet_balance'),
      'wallet_verified': prefs.getBool('wallet_verified'),
    };
  }

  Future<bool> hasVirtualAccount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('account_number');
  }

  Future<void> clearVirtualAccountData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('account_number');
    await prefs.remove('account_name');
    await prefs.remove('bank_name');
    await prefs.remove('bank_code');
    await prefs.remove('currency');
    await prefs.remove('wallet_id');
    await prefs.remove('wallet_balance');
    await prefs.remove('wallet_verified');
  }

  Future<WalletSummaryResponse> getWalletSummary() async {
    debugPrint('🟢 WalletService.getWalletSummary called');
    try {
      final url = '${UrlConstants.baseUrl}${UrlConstants.walletSummary}';
      debugPrint('🟢 URL: $url');

      final response = await _client
          .get(Uri.parse(url))
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('🔴 Request TIMED OUT after 30 seconds');
              throw Exception('Request timed out');
            },
          );

      debugPrint('🟢 Response status: ${response.statusCode}');
      debugPrint('🟢 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return WalletSummaryResponse.fromJson(jsonResponse);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          errorBody['message'] ?? 'Failed to fetch wallet summary',
        );
      }
    } catch (e, stack) {
      debugPrint('🔴 WalletService.getWalletSummary ERROR: $e');
      debugPrint('🔴 Stack: $stack');
      rethrow;
    }
  }

  Future<VirtualAccountInfo?> getVirtualAccount() async {
    AppLogger.log('Getting virtual account…');
    AppLogger.log(
      'URL: ${UrlConstants.baseUrl}${UrlConstants.getVirtualAccount}',
    );

    final response = await _client.get(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.getVirtualAccount}'),
    );

    AppLogger.log('Get virtual account response: ${response.body}');

    if (response.statusCode == 200) {
      AppLogger.log('Virtual account found: ${response.body}');
      final jsonResponse = jsonDecode(response.body);
      return VirtualAccountInfo.fromJson(jsonResponse);
    } else if (response.statusCode == 404) {
      AppLogger.log('No virtual account found (404)');
      return null;
    } else {
      AppLogger.log('Error fetching virtual account: ${response.body}');
      final errorBody = jsonDecode(response.body);
      throw Exception(
        errorBody['message'] ?? 'Failed to fetch virtual account',
      );
    }
  }
}
