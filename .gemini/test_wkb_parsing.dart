import 'dart:typed_data';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Test WKB parsing with the example data from the API
void main() {
  // Example WKB from API response
  final pickupWKB = "0101000020E61000008E356D10F7E21B40C13F000407371640";
  final destWKB = "0101000020E61000008E356D10F7E21B40C13F000407371640";

  AppLogger.log('Testing WKB parsing...');
  AppLogger.log('Pickup WKB: $pickupWKB');
  AppLogger.log('Dest WKB: $destWKB');

  final pickupCoords = parsePostGISLocation(pickupWKB);
  final destCoords = parsePostGISLocation(destWKB);

  if (pickupCoords != null) {
    AppLogger.log(
      '✅ Pickup parsed: lat=${pickupCoords['lat']}, lng=${pickupCoords['lng']}',
    );
    final pickupLatLng = LatLng(pickupCoords['lat']!, pickupCoords['lng']!);
    AppLogger.log('   LatLng: $pickupLatLng');
  } else {
    AppLogger.log('❌ Failed to parse pickup');
  }

  if (destCoords != null) {
    AppLogger.log(
      '✅ Dest parsed: lat=${destCoords['lat']}, lng=${destCoords['lng']}',
    );
    final destLatLng = LatLng(destCoords['lat']!, destCoords['lng']!);
    AppLogger.log('   LatLng: $destLatLng');

    // Calculate midpoint for stop marker
    if (pickupCoords != null) {
      final stopLat = (pickupCoords['lat']! + destCoords['lat']!) / 2;
      final stopLng = (pickupCoords['lng']! + destCoords['lng']!) / 2;
      AppLogger.log('✅ Stop midpoint: lat=$stopLat, lng=$stopLng');
    }
  } else {
    AppLogger.log('❌ Failed to parse destination');
  }
}

Map<String, double>? parsePostGISLocation(String location) {
  try {
    if (location.length >= 50) {
      final hexData = location.substring(18); // Skip SRID part
      final lngHex = hexData.substring(0, 16);
      final latHex = hexData.substring(16, 32);

      final lngBytes = hexToBytes(lngHex);
      final latBytes = hexToBytes(latHex);

      final lng = bytesToDouble(lngBytes);
      final lat = bytesToDouble(latBytes);

      if (lat != null && lng != null) {
        return {'lat': lat, 'lng': lng};
      }
    }
  } catch (e) {
    AppLogger.log('Error parsing PostGIS location: $e');
  }
  return null;
}

List<int> hexToBytes(String hex) {
  final bytes = <int>[];
  for (int i = 0; i < hex.length; i += 2) {
    bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
  }
  return bytes.reversed.toList(); // Reverse for little-endian
}

double? bytesToDouble(List<int> bytes) {
  if (bytes.length != 8) return null;
  final buffer = Uint8List.fromList(bytes).buffer;
  return ByteData.view(buffer).getFloat64(0, Endian.big);
}
