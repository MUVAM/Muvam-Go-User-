import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:muvam/core/constants/url_constants.dart';
import 'package:muvam/core/utils/app_logger.dart';

class DirectionsService {
  final PolylinePoints _polylinePoints = PolylinePoints();

  /// Get route polyline points between two locations using flutter_polyline_points
  Future<List<LatLng>> getRoutePolyline({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
  }) async {
    try {
      // Check if API key is present
      if (UrlConstants.googleMapsApiKey.isEmpty) {
        AppLogger.log('❌ ERROR: Google Maps API key is missing or empty!');
        AppLogger.log('⚠️ Using straight line fallback');
        return [origin, destination];
      }

      AppLogger.log(
        '✅ Google Maps API key is present (length: ${UrlConstants.googleMapsApiKey.length})',
      );
      AppLogger.log('🌐 Fetching directions from Google Maps API...');
      AppLogger.log('📍 Origin: ${origin.latitude}, ${origin.longitude}');
      AppLogger.log(
        '📍 Destination: ${destination.latitude}, ${destination.longitude}',
      );

      List<LatLng> polylineCoordinates = [];

      // Build polyline request
      PolylineRequest request = PolylineRequest(
        origin: PointLatLng(origin.latitude, origin.longitude),
        destination: PointLatLng(destination.latitude, destination.longitude),
        mode: TravelMode.driving,
        optimizeWaypoints: true,
      );

      // Add waypoints if provided
      if (waypoints != null && waypoints.isNotEmpty) {
        request = PolylineRequest(
          origin: PointLatLng(origin.latitude, origin.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.driving,
          optimizeWaypoints: true,
          wayPoints: waypoints
              .map(
                (point) => PolylineWayPoint(
                  location: '${point.latitude},${point.longitude}',
                ),
              )
              .toList(),
        );
      }

      // Get route points using Google Directions API
      PolylineResult result = await _polylinePoints
          .getRouteBetweenCoordinates(
            googleApiKey: UrlConstants.googleMapsApiKey,
            request: request,
          )
          .timeout(Duration(seconds: 10));

      AppLogger.log('📊 API Response status: ${result.status}');

      if (result.points.isNotEmpty) {
        // Convert points to LatLng
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }

        AppLogger.log('✅ Route fetched successfully');
        AppLogger.log('✅ Decoded ${polylineCoordinates.length} route points');

        return polylineCoordinates;
      } else {
        AppLogger.log('❌ No route points found');
        if (result.errorMessage != null && result.errorMessage!.isNotEmpty) {
          AppLogger.log('❌ Error message: ${result.errorMessage}');
        }
      }
    } catch (e, stackTrace) {
      AppLogger.log('❌ Exception getting route: $e');
      AppLogger.log('📚 Stack trace: $stackTrace');
    }

    // Return straight line as fallback
    AppLogger.log(
      '⚠️ FALLBACK: Using straight line between origin and destination',
    );
    AppLogger.log('⚠️ This means the Google Directions API call failed');
    return [origin, destination];
  }

  /// Get estimated duration and distance for a route
  Future<Map<String, dynamic>?> getRouteDetails({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      if (UrlConstants.googleMapsApiKey.isEmpty) {
        AppLogger.log('❌ ERROR: Google Maps API key is missing!');
        return null;
      }

      PolylineResult result = await _polylinePoints
          .getRouteBetweenCoordinates(
            googleApiKey: UrlConstants.googleMapsApiKey,
            request: PolylineRequest(
              origin: PointLatLng(origin.latitude, origin.longitude),
              destination: PointLatLng(
                destination.latitude,
                destination.longitude,
              ),
              mode: TravelMode.driving,
            ),
          )
          .timeout(Duration(seconds: 10));

      if (result.points.isNotEmpty) {
        // Note: flutter_polyline_points doesn't provide distance/duration directly
        // You would need to parse this from the raw response if needed
        // For now, return basic info
        return {'points_count': result.points.length, 'status': result.status};
      }
    } catch (e) {
      AppLogger.log('Error getting route details: $e');
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
