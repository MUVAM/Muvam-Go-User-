import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:muvam/core/utils/app_logger.dart';

class PlacesService {
  static String get _apiKey =>
      dotenv.env['GOOGLE_API_KEY'] ?? dotenv.env['API_KEY'] ?? '';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  Future<List<PlacePrediction>> getPlacePredictions(
    String query, {
    String? sessionToken,
    Position? currentLocation,
  }) async {
    AppLogger.log('Getting place predictions for: "$query"', tag: 'PLACES');

    if (query.isEmpty) {
      AppLogger.log('Query is empty, returning empty list', tag: 'PLACES');
      return [];
    }

    if (_apiKey.isEmpty) {
      AppLogger.error('Google API key is missing!', tag: 'PLACES');
      return [];
    }

    final url = Uri.parse(
      '$_baseUrl/autocomplete/json?input=$query&key=$_apiKey&sessiontoken=${sessionToken ?? ''}&components=country:ng&types=establishment|geocode',
    );

    AppLogger.log(
      'API URL: ${url.toString().replaceAll(_apiKey, 'HIDDEN_KEY')}',
      tag: 'PLACES',
    );

    try {
      final response = await http.get(url);
      AppLogger.log('Response status: ${response.statusCode}', tag: 'PLACES');
      AppLogger.log('Response body: ${response.body}', tag: 'PLACES');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        AppLogger.log('API Status: ${data['status']}', tag: 'PLACES');

        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          AppLogger.log(
            'Found ${predictions.length} predictions',
            tag: 'PLACES',
          );

          final predictionList = predictions
              .map((prediction) => PlacePrediction.fromJson(prediction))
              .toList();

          // Log each prediction
          for (int i = 0; i < predictionList.length; i++) {
            AppLogger.log(
              '   ${i + 1}. ${predictionList[i].description}',
              tag: 'PLACES',
            );
          }

          // Calculate distances if current location is provided
          if (currentLocation != null) {
            AppLogger.log(
              'Calculating distances from current location',
              tag: 'PLACES',
            );
            for (var prediction in predictionList) {
              final placeDetails = await getPlaceDetails(
                prediction.placeId,
                sessionToken: sessionToken,
              );
              if (placeDetails != null) {
                final distance = Geolocator.distanceBetween(
                  currentLocation.latitude,
                  currentLocation.longitude,
                  placeDetails.latitude,
                  placeDetails.longitude,
                );
                prediction.distance = _formatDistance(distance);
              }
            }
          }

          return predictionList;
        } else {
          AppLogger.error(
            'API Error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}',
            tag: 'PLACES',
          );
        }
      } else {
        AppLogger.error('HTTP Error: ${response.statusCode}', tag: 'PLACES');
      }
      return [];
    } catch (e, stackTrace) {
      AppLogger.error(
        'Exception fetching place predictions',
        error: e,
        stackTrace: stackTrace,
        tag: 'PLACES',
      );
      return [];
    }
  }

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  Future<PlaceDetails?> getPlaceDetails(
    String placeId, {
    String? sessionToken,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/details/json?place_id=$placeId&key=$_apiKey&sessiontoken=${sessionToken ?? ''}&fields=geometry,formatted_address,name',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          return PlaceDetails.fromJson(data['result']);
        }
      }
      return null;
    } catch (e) {
      AppLogger.log('Error fetching place details: $e');
      return null;
    }
  }
}

class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
  String? distance;

  PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
    this.distance,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: json['structured_formatting']?['main_text'] ?? '',
      secondaryText: json['structured_formatting']?['secondary_text'] ?? '',
    );
  }
}

class PlaceDetails {
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String name;

  PlaceDetails({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    required this.name,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'];
    final location = geometry['location'];

    return PlaceDetails(
      latitude: location['lat']?.toDouble() ?? 0.0,
      longitude: location['lng']?.toDouble() ?? 0.0,
      formattedAddress: json['formatted_address'] ?? '',
      name: json['name'] ?? '',
    );
  }
}
