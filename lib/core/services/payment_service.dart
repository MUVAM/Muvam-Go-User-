import 'dart:convert';
import 'dart:math';
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
        AppLogger.warning(
          'No auth token found in SharedPreferences',
          tag: 'PAYMENT',
        );
      }

      return token;
    } catch (e) {
      AppLogger.error(
        'Failed to retrieve auth token',
        error: e,
        tag: 'PAYMENT',
      );
      return null;
    }
  }

  String generateReference() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999).toString().padLeft(6, '0');
    final reference = 'MUV-$timestamp-$random';
    AppLogger.log('Generated payment reference: $reference', tag: 'PAYMENT');
    return reference;
  }

  Future<Map<String, dynamic>> initializePayment({
    required int rideId,
    required double amount,
    String? reference,
  }) async {
    final paymentReference = reference ?? generateReference();

    AppLogger.log(
      'Initializing payment for ride $rideId, amount: ₦$amount, reference: $paymentReference',
      tag: 'PAYMENT',
    );

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
        'reference': paymentReference,
      }),
    );

    AppLogger.log('Payment Initialize Response Status: ${response.statusCode}');
    AppLogger.log('Payment Initialize Response Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      if (!responseData.containsKey('reference')) {
        responseData['reference'] = paymentReference;
      }
      return responseData;
    } else {
      throw Exception('Failed to initialize payment: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> verifyPayment(String reference) async {
    AppLogger.log(
      'Verifying payment with reference: $reference',
      tag: 'PAYMENT',
    );

    final token = await _getToken();

    final response = await http.get(
      Uri.parse(
        '${UrlConstants.baseUrl}${UrlConstants.paymentVerify}/$reference',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    AppLogger.log(
      'Payment Verify Response Status: ${response.statusCode}',
      tag: 'PAYMENT',
    );
    AppLogger.log(
      'Payment Verify Response Body: ${response.body}',
      tag: 'PAYMENT',
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      AppLogger.log(
        'Payment verification result: ${responseData['status'] ?? 'unknown'}',
        tag: 'PAYMENT',
      );
      return responseData;
    } else {
      AppLogger.error(
        'Failed to verify payment: ${response.body}',
        tag: 'PAYMENT',
      );
      throw Exception('Failed to verify payment: ${response.body}');
    }
  }
}
