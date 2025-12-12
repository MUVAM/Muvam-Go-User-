import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';

class DirectionsService {
  static const String _apiKey = ApiKeys.googleMapsApiKey;
  
  /// Get route polyline points between two locations
  Future<List<LatLng>> getRoutePolyline({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
  }) async {
    try {
      // Build the URL
      String url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&key=$_apiKey';

      // Add waypoints if provided
      if (waypoints != null && waypoints.isNotEmpty) {
        String waypointsStr = waypoints
            .map((point) => '${point.latitude},${point.longitude}')
            .join('|');
        url += '&waypoints=$waypointsStr';
      }

      print('🗺️ Fetching directions from Google Maps API...');
      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final routes = data['routes'] as List;
          if (routes.isNotEmpty) {
            final route = routes[0];
            final polylinePoints = route['overview_polyline']['points'];
            
            print('✅ Route fetched successfully');
            
            // Decode the polyline
            return _decodePolyline(polylinePoints);
          }
        } else {
          print('❌ Directions API error: ${data['status']}');
          print('Error message: ${data['error_message'] ?? 'No error message'}');
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting route: $e');
    }

    // Return straight line as fallback (API key needed for real routes)
    print('⚠️ Using straight line - need valid Google Maps API key for real routes');
    return [origin, destination];
  }

  /// Decode Google Maps polyline string into list of LatLng points
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      double latitude = lat / 1E5;
      double longitude = lng / 1E5;

      polyline.add(LatLng(latitude, longitude));
    }

    return polyline;
  }

  /// Get estimated duration and distance for a route
  Future<Map<String, dynamic>?> getRouteDetails({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      String url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final routes = data['routes'] as List;
          if (routes.isNotEmpty) {
            final route = routes[0];
            final leg = route['legs'][0];

            return {
              'distance': leg['distance']['text'],
              'distance_value': leg['distance']['value'], // in meters
              'duration': leg['duration']['text'],
              'duration_value': leg['duration']['value'], // in seconds
            };
          }
        }
      }
    } catch (e) {
      print('Error getting route details: $e');
    }

    return null;
  }

  /// Create BitmapDescriptor from widget
  static Future<BitmapDescriptor> createBitmapDescriptorFromWidget(
    Widget widget, {
    required Size size,
  }) async {
    final repaintBoundary = RenderRepaintBoundary();
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final renderView = RenderView(
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration(
        physicalConstraints: BoxConstraints.tight(size),
        logicalConstraints: BoxConstraints.tight(size),
        devicePixelRatio: 1.0,
      ),
      view: view,
    );

    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: widget,
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final image = await repaintBoundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }
}