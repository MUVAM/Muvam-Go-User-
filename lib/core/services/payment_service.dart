import 'dart:convert';
import 'dart:developer' as log;
import 'package:muvam/core/constants/url_constants.dart';
import 'package:muvam/core/services/api_client.dart';
import 'package:muvam/core/utils/app_logger.dart';

class PaymentService {
  final _client = ApiClient();

  Future<Map<String, dynamic>> initializePayment({
    required int rideId,
    required double amount,
    String? reference,
  }) async {
    final paymentReference = reference;

    AppLogger.log(
      'Initializing payment for ride $rideId, amount: ₦$amount, reference: $paymentReference',
      tag: 'PAYMENT',
    );

    final response = await _client.post(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.paymentInitialize}'),
      body: jsonEncode({
        'ride_id': rideId,
        'amount': amount,
        'reference': paymentReference,
      }),
    );

    AppLogger.log('Payment Initialize Response Status: ${response.statusCode}');
    log.log('Payment Initialize Response Body: ${response.body}');

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

    final response = await _client.get(
      Uri.parse(
        '${UrlConstants.baseUrl}${UrlConstants.paymentVerify}/$reference',
      ),
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
