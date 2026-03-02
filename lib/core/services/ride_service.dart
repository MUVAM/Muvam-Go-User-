import 'dart:convert';
import 'dart:developer';
import 'package:muvam/core/constants/url_constants.dart';
import 'package:muvam/core/services/api_client.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/features/home/data/models/ride_models.dart';
import 'package:muvam/features/trips/data/models/ride_user.dart';

class RideService {
  final _client = ApiClient();

  Future<RideEstimateResponse> estimateRide(RideEstimateRequest request) async {
    final requestBody = request.toJson();

    AppLogger.log('=== RIDE ESTIMATE REQUEST ===');
    AppLogger.log('URL: ${UrlConstants.baseUrl}${UrlConstants.rideEstimate}');
    AppLogger.log('Request Body: ${jsonEncode(requestBody)}');

    final response = await _client.post(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.rideEstimate}'),
      body: jsonEncode(requestBody),
    );

    AppLogger.log('=== RIDE ESTIMATE RESPONSE ===');
    AppLogger.log('Response Status: ${response.statusCode}');
    AppLogger.log('Response Body: ${response.body}');
    AppLogger.log('=== END RIDE ESTIMATE ===');

    if (response.statusCode == 200) {
      return RideEstimateResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to estimate ride: ${response.body}');
    }
  }

  Future<RideResponse> requestRide(RideRequest request) async {
    final requestBody = request.toJson();

    AppLogger.log('=== RIDE REQUEST DEBUG ===');
    AppLogger.log('=== RIDE REQUEST BODY $requestBody ===');
    AppLogger.log(
      'Request URL: ${UrlConstants.baseUrl}${UrlConstants.rideRequest}',
    );
    AppLogger.log('PAYMENT METHOD IN REQUEST: ${request.paymentMethod}');
    AppLogger.log('FULL REQUEST BODY: ${jsonEncode(requestBody)}');
    AppLogger.log('REQUEST BODY BREAKDOWN:');
    requestBody.forEach((key, value) {
      AppLogger.log('  $key: $value');
    });

    final response = await _client.post(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.rideRequest}'),
      body: jsonEncode(requestBody),
    );

    AppLogger.log('=== RIDE REQUEST RESPONSE ===');
    AppLogger.log('Response Status: ${response.statusCode}');
    log('FULL RESPONSE BODY: ${response.body}');

    if (response.body.isNotEmpty) {
      try {
        final responseJson = jsonDecode(response.body);
        AppLogger.log('RESPONSE BODY BREAKDOWN:');
        if (responseJson is Map<String, dynamic>) {
          responseJson.forEach((key, value) {
            AppLogger.log('  $key: $value');
          });
        }
      } catch (e) {
        AppLogger.log('Failed to parse response JSON: $e');
      }
    }
    AppLogger.log('=== END RIDE REQUEST ===');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return RideResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to request ride: ${response.body}');
    }
  }

  Future<List<dynamic>> getNearbyRides() async {
    final response = await _client.get(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.nearbyRides}'),
    );

    AppLogger.log('Nearby Rides Response Status: ${response.statusCode}');
    AppLogger.log('Nearby Rides Response Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get nearby rides: ${response.body}');
    }
  }

  Future<Map<String, dynamic>?> getNearbyDrivers({
    required double latitude,
    required double longitude,
  }) async {
    final url =
        '${UrlConstants.baseUrl}${UrlConstants.nearbyDrivers}?longitude=$longitude&latitude=$latitude';

    AppLogger.log('Getting nearby drivers: $url');

    try {
      final response = await _client.get(Uri.parse(url));

      AppLogger.log('Nearby drivers response: ${response.statusCode}');
      AppLogger.log('Nearby drivers body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['drivers'] != null && (data['drivers'] as List).isNotEmpty) {
          return data['drivers'][0];
        }
      }
    } catch (e) {
      AppLogger.log('Failed to fetch nearby drivers: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>> getActiveRides() async {
    AppLogger.log('=== CHECKING ACTIVE RIDES ===');

    final response = await _client.post(
      Uri.parse('${UrlConstants.baseUrl}${UrlConstants.activeRides}'),
      body: jsonEncode({'status': 'active'}),
    );

    AppLogger.log('Active Rides Response Status: ${response.statusCode}');
    AppLogger.log('Active Rides Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {'success': true, 'data': data};
    } else {
      return {
        'success': false,
        'message': 'Failed to get active rides: ${response.body}',
      };
    }
  }

  Future<Map<String, dynamic>> getRideDetails(int rideId) async {
    final response = await _client.get(
      Uri.parse('${UrlConstants.baseUrl}/rides/$rideId'),
    );

    if (response.statusCode == 200) {
      return {'success': true, 'data': jsonDecode(response.body)};
    } else {
      return {
        'success': false,
        'message': 'Failed to get ride details: ${response.body}',
      };
    }
  }

  Future<Map<String, dynamic>> rateRide({
    required int rideId,
    required int score,
    required String comment,
  }) async {
    final url = '${UrlConstants.baseUrl}/rides/$rideId/rate';
    final requestBody = {'comment': comment, 'score': score};

    AppLogger.log('=== RATE RIDE REQUEST ===', tag: 'RATING');
    AppLogger.log('URL: $url', tag: 'RATING');
    AppLogger.log('Request Body: ${jsonEncode(requestBody)}', tag: 'RATING');

    final response = await _client.post(
      Uri.parse(url),
      body: jsonEncode(requestBody),
    );

    AppLogger.log('Response Status: ${response.statusCode}', tag: 'RATING');
    AppLogger.log('Response Body: ${response.body}', tag: 'RATING');
    AppLogger.log('=== END RATE RIDE ===', tag: 'RATING');

    if (response.statusCode == 200) {
      return {'success': true, 'data': jsonDecode(response.body)};
    } else {
      return {
        'success': false,
        'message': 'Failed to rate ride: ${response.body}',
      };
    }
  }

  Future<List<Ride>> getRides({String? status}) async {
    final url = '${UrlConstants.baseUrl}${UrlConstants.rides}';

    AppLogger.log('Getting rides: $url');

    final Map<String, dynamic> body = {};
    if (status != null) {
      body['status'] = status;
    }

    final response = await _client.post(Uri.parse(url), body: jsonEncode(body));

    AppLogger.log('OMOOOOO =======: ${response.statusCode}');
    AppLogger.log('OMOOOOOOO RIDE HEREEEE: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      List<dynamic> jsonList;
      if (responseData is List) {
        jsonList = responseData;
      } else if (responseData is Map && responseData['rides'] != null) {
        jsonList = responseData['rides'];
      } else {
        jsonList = [];
      }

      return jsonList.map((json) => Ride.fromJson(json)).toList();
    } else {
      AppLogger.log('Failed to fetch rides: ${response.body}');
      throw Exception('Failed to fetch rides');
    }
  }

  Future<Ride> getRideById(int rideId) async {
    final url = '${UrlConstants.baseUrl}/rides/$rideId';

    AppLogger.log('Getting ride details: $url');

    final response = await _client.get(Uri.parse(url));

    AppLogger.log('Ride details response: ${response.statusCode}');
    AppLogger.log('Ride details body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return Ride.fromJson(responseData);
    } else {
      AppLogger.log('Failed to fetch ride details: ${response.body}');
      throw Exception('Failed to fetch ride details');
    }
  }

  Future<void> dismissRide(int rideId) async {
    final url = '${UrlConstants.baseUrl}/rides/dismiss/$rideId';

    AppLogger.log('=== DISMISS RIDE REQUEST ===', tag: 'DISMISS');
    AppLogger.log('URL: $url', tag: 'DISMISS');

    final response = await _client.post(Uri.parse(url));

    AppLogger.log('Response Status: ${response.statusCode}', tag: 'DISMISS');
    AppLogger.log('Response Body: ${response.body}', tag: 'DISMISS');
    AppLogger.log('=== END DISMISS RIDE ===', tag: 'DISMISS');

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to dismiss ride: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> sendSOS({
    required String location,
    required String locationAddress,
    required int rideId,
  }) async {
    final url = '${UrlConstants.baseUrl}${UrlConstants.sos}';
    final requestBody = {
      'location': location,
      'location_address': locationAddress,
      'ride_id': rideId,
    };

    AppLogger.log('=== SOS REQUEST ===', tag: 'SOS');
    AppLogger.log('URL: $url', tag: 'SOS');
    AppLogger.log('Request Body: ${jsonEncode(requestBody)}', tag: 'SOS');

    final response = await _client.post(
      Uri.parse(url),
      body: jsonEncode(requestBody),
    );

    AppLogger.log('Response Status: ${response.statusCode}', tag: 'SOS');
    AppLogger.log('Response Body: ${response.body}', tag: 'SOS');
    AppLogger.log('=== END SOS REQUEST ===', tag: 'SOS');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'data': jsonDecode(response.body)};
    } else {
      return {
        'success': false,
        'message': 'Failed to send SOS: ${response.body}',
      };
    }
  }

  Future<Map<String, dynamic>> updateRide({
    required int rideId,
    required String pickup,
    required String pickupAddress,
    required String dest,
    required String destAddress,
    required String paymentMethod,
    required String vehicleType,
    required String serviceType,
  }) async {
    final url = '${UrlConstants.baseUrl}/rides/update/$rideId';
    final requestBody = {
      'pickup': pickup,
      'pickup_address': pickupAddress,
      'dest': dest,
      'dest_address': destAddress,
      'payment_method': paymentMethod,
      'vehicle_type': vehicleType,
      'service_type': serviceType,
    };

    AppLogger.log('=== UPDATE RIDE REQUEST ===', tag: 'UPDATE_RIDE');
    AppLogger.log('URL: $url', tag: 'UPDATE_RIDE');
    AppLogger.log(
      'Request Body: ${jsonEncode(requestBody)}',
      tag: 'UPDATE_RIDE',
    );

    final response = await _client.put(
      Uri.parse(url),
      body: jsonEncode(requestBody),
    );

    AppLogger.log(
      'Response Status: ${response.statusCode}',
      tag: 'UPDATE_RIDE',
    );
    AppLogger.log('Response Body: ${response.body}', tag: 'UPDATE_RIDE');
    AppLogger.log('=== END UPDATE RIDE ===', tag: 'UPDATE_RIDE');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'data': jsonDecode(response.body)};
    } else {
      return {
        'success': false,
        'message': 'Failed to update ride: ${response.body}',
      };
    }
  }

  Future<Map<String, dynamic>> cancelRide({
    required int rideId,
    required String reason,
  }) async {
    final url = '${UrlConstants.baseUrl}/rides/cancel/$rideId';
    final requestBody = {'reason': reason};

    AppLogger.log('=== CANCEL RIDE REQUEST ===', tag: 'CANCEL');
    AppLogger.log('URL: $url', tag: 'CANCEL');
    AppLogger.log('Request Body: ${jsonEncode(requestBody)}', tag: 'CANCEL');

    final response = await _client.post(
      Uri.parse(url),
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'data': jsonDecode(response.body)};
    } else {
      return {'success': false, 'message': jsonDecode(response.body)["error"]};
    }
  }

  Future<Map<String, dynamic>> updatePrebookedRide({
    required int rideId,
    required String dest,
    required String destAddress,
    required String pickup,
    required String pickupAddress,
    required String scheduledAt,
    String? stopAddress,
    required String vehicleType,
  }) async {
    final url = '${UrlConstants.baseUrl}/rides/update/$rideId';

    final requestBody = {
      'dest': dest,
      'dest_address': destAddress,
      'pickup': pickup,
      'pickup_address': pickupAddress,
      'scheduled_at': scheduledAt,
      'vehicle_type': vehicleType,
    };

    if (stopAddress != null && stopAddress.isNotEmpty) {
      requestBody['stop_address'] = stopAddress;
    }

    AppLogger.log('=== UPDATE PREBOOKED RIDE REQUEST ===', tag: 'PREBOOKED');
    AppLogger.log('URL: $url', tag: 'PREBOOKED');
    AppLogger.log('Request Body: ${jsonEncode(requestBody)}', tag: 'PREBOOKED');

    final response = await _client.put(
      Uri.parse(url),
      body: jsonEncode(requestBody),
    );

    AppLogger.log('Response Status: ${response.statusCode}', tag: 'PREBOOKED');
    AppLogger.log('Response Body: ${response.body}', tag: 'PREBOOKED');
    AppLogger.log('=== END UPDATE PREBOOKED RIDE ===', tag: 'PREBOOKED');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'data': jsonDecode(response.body)};
    } else {
      return {
        'success': false,
        'message': 'Failed to update prebooked ride: ${response.body}',
      };
    }
  }
}
