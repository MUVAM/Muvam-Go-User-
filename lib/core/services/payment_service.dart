import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:muvam/core/constants/url_constants.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentService {
  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token != null) {
        AppLogger.log('Auth token retrieved successfully', tag: 'PAYMENT');
      } else {
        AppLogger.warning('No auth token found in SharedPreferences', tag: 'PAYMENT');
      }
      
      return token;
    } catch (e) {
      AppLogger.error('Failed to retrieve auth token', error: e, tag: 'PAYMENT');
      return null;
    }
  }

  Future<Map<String, dynamic>> initializePayment({
    required int rideId,
    required double amount,
  }) async {
    AppLogger.log('💰 Initializing payment for ride $rideId, amount: ₦$amount', tag: 'PAYMENT');
    
    final token = await _getToken();
    
    final response = await http.post(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.paymentInitialize}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'ride_id': rideId,
        'amount': amount,
      }),
    );

    AppLogger.log('Payment Initialize Response Status: ${response.statusCode}');
    AppLogger.log('Payment Initialize Response Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to initialize payment: ${response.body}');
    }
  }
}