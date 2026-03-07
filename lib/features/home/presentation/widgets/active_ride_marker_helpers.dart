import 'dart:math';
import 'dart:typed_data';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:muvam/core/utils/app_logger.dart';

LatLng? parsePostGISPoint(String pointString) {
  try {
    if (pointString.startsWith('0101000020')) {
      final result = _parsePostGISLocation(pointString);
      if (result != null && result['lat'] != null && result['lng'] != null) {
        return LatLng(result['lat']!, result['lng']!);
      } else {
        return null;
      }
    }

    final coords = pointString
        .replaceAll('POINT(', '')
        .replaceAll(')', '')
        .split(' ');

    if (coords.length == 2) {
      final longitude = double.parse(coords[0]);
      final latitude = double.parse(coords[1]);
      return LatLng(latitude, longitude);
    }
  } catch (e) {
    AppLogger.log('Error parsing PostGIS point: $e');
  }
  return null;
}

Map<String, double>? _parsePostGISLocation(String location) {
  try {
    if (location.length >= 50) {
      final hexData = location.substring(18);
      final lngHex = hexData.substring(0, 16);
      final latHex = hexData.substring(16, 32);

      final lngBytes = _hexToBytes(lngHex);
      final latBytes = _hexToBytes(latHex);

      final lng = _bytesToDouble(lngBytes);
      final lat = _bytesToDouble(latBytes);

      if (lat != null && lng != null) {
        return {'lat': lat, 'lng': lng};
      }
    }
  } catch (e) {
    AppLogger.log('Error parsing PostGIS location: $e');
  }
  return null;
}

List<int> _hexToBytes(String hex) {
  final bytes = <int>[];
  for (int i = 0; i < hex.length; i += 2) {
    bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
  }
  return bytes.reversed.toList();
}

double? _bytesToDouble(List<int> bytes) {
  if (bytes.length != 8) return null;
  final buffer = Uint8List.fromList(bytes).buffer;
  return ByteData.view(buffer).getFloat64(0, Endian.big);
}

LatLngBounds calculateBounds(List<LatLng> positions) {
  double minLat = positions.first.latitude;
  double maxLat = positions.first.latitude;
  double minLng = positions.first.longitude;
  double maxLng = positions.first.longitude;

  for (final pos in positions) {
    minLat = min(minLat, pos.latitude);
    maxLat = max(maxLat, pos.latitude);
    minLng = min(minLng, pos.longitude);
    maxLng = max(maxLng, pos.longitude);
  }

  return LatLngBounds(
    southwest: LatLng(minLat, minLng),
    northeast: LatLng(maxLat, maxLng),
  );
}

List<LatLng> generateCurvedPath(LatLng start, LatLng end) {
  List<LatLng> points = [];

  double midLat = (start.latitude + end.latitude) / 2;
  double midLng = (start.longitude + end.longitude) / 2;

  double offsetLat = (end.longitude - start.longitude) * 0.002;
  double offsetLng = (start.latitude - end.latitude) * 0.002;

  LatLng curvePoint = LatLng(midLat + offsetLat, midLng + offsetLng);

  for (int i = 0; i <= 20; i++) {
    double t = i / 20.0;
    double lat = _quadraticBezier(
      start.latitude,
      curvePoint.latitude,
      end.latitude,
      t,
    );
    double lng = _quadraticBezier(
      start.longitude,
      curvePoint.longitude,
      end.longitude,
      t,
    );
    points.add(LatLng(lat, lng));
  }

  return points;
}

double _quadraticBezier(double p0, double p1, double p2, double t) {
  return (1 - t) * (1 - t) * p0 + 2 * (1 - t) * t * p1 + t * t * p2;
}
