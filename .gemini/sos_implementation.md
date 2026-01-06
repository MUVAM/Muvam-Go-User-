# SOS Emergency Alert Implementation

## Summary
Implemented SOS emergency alert functionality that allows users to send an emergency alert with their current location, address, and ride information to the backend when they tap the SOS button during an active trip.

## Changes Made

### 1. **URL Constants** (`lib/core/constants/url_constants.dart`)
- Added SOS endpoint:
  ```dart
  static const String sos = "/sos";
  ```

### 2. **RideService** (`lib/core/services/ride_service.dart`)
- Added `sendSOS()` method:
  ```dart
  Future<Map<String, dynamic>> sendSOS({
    required String location,
    required String locationAddress,
    required int rideId,
  })
  ```

#### Method Details:
- **Parameters:**
  - `location`: POINT format string (e.g., "POINT(7.4069943 6.8720015)")
  - `locationAddress`: Human-readable address string
  - `rideId`: Current ride ID

- **Returns:**
  ```dart
  {
    'success': true/false,
    'data': {...} // Response data if successful
    'message': '...' // Error message if failed
  }
  ```

- **Request Body:**
  ```json
  {
    "location": "POINT(longitude latitude)",
    "location_address": "Street, City, State",
    "ride_id": 123
  }
  ```

### 3. **HomeScreen SOS Button** (`lib/features/home/presentation/screens/home_screen.dart`)

#### Implementation Flow:

1. **User taps SOS button** (when trip has started)
2. **Show loading indicator**
3. **Get current GPS location** using Geolocator
4. **Reverse geocode** to get human-readable address
5. **Format location** as POINT string
6. **Send SOS request** to backend
7. **Close loading indicator**
8. **Show success/error message**

#### Code Logic:

```dart
if (hasStarted) {
  // SOS functionality
  if (_activeRide != null) {
    try {
      // 1. Show loading
      showDialog(context, CircularProgressIndicator);
      
      // 2. Get current position
      final position = await Geolocator.getCurrentPosition();
      
      // 3. Get address from coordinates
      final placemarks = await placemarkFromCoordinates(lat, lng);
      final locationAddress = '${street}, ${city}, ${state}';
      
      // 4. Format location as POINT
      final location = 'POINT(${longitude} ${latitude})';
      
      // 5. Send SOS
      final result = await _rideService.sendSOS(
        location: location,
        locationAddress: locationAddress,
        rideId: rideId,
      );
      
      // 6. Close loading
      Navigator.pop(context);
      
      // 7. Show result
      if (result['success']) {
        SnackBar('🆘 SOS alert sent successfully!');
      } else {
        SnackBar('Failed to send SOS');
      }
    } catch (e) {
      // Handle errors
    }
  }
}
```

## User Experience

### Button States:

| Trip Status | Button Text | Icon | Action |
|-------------|-------------|------|--------|
| **Driver on the way** | "Call Driver" | 📞 `Icons.call` | Opens call screen |
| **Driver arrived** | "Cancel" | ❌ `Icons.cancel` | Cancel functionality |
| **Trip started** | "SOS" | 🆘 `Icons.sos` | **Sends emergency alert** |

### SOS Flow:

1. **User is in an active trip** (status: "started")
2. **Emergency situation occurs**
3. **User taps "SOS" button**
4. **Loading indicator appears**
5. **App gets current location** (GPS coordinates)
6. **App converts coordinates to address** (reverse geocoding)
7. **App sends SOS to backend** with:
   - Current location (POINT format)
   - Current address (human-readable)
   - Current ride ID
8. **Success message shown**: "🆘 SOS alert sent successfully!"
9. **Backend can now:**
   - Alert emergency services
   - Notify driver
   - Track user's location
   - Take appropriate action

## API Endpoint

**Endpoint:** `POST /api/v1/sos`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "location": "POINT(7.4069943 6.8720015)",
  "location_address": "123 Main Street, Lagos, Lagos State",
  "ride_id": 456
}
```

**Success Response (200/201):**
```json
{
  // Backend response data
}
```

**Error Response:**
```json
{
  "error": "Error message"
}
```

## Error Handling

The implementation handles several error scenarios:

1. **Location Permission Denied**
   - Geolocator will throw an error
   - User sees: "Error sending SOS: [error details]"

2. **GPS Unavailable**
   - Geolocator timeout or error
   - User sees error message

3. **Reverse Geocoding Fails**
   - Falls back to "Unknown location"
   - SOS still sent with coordinates

4. **Network Error**
   - API call fails
   - User sees: "Failed to send SOS: [error message]"

5. **No Active Ride**
   - Button does nothing if `_activeRide` is null

## Testing Checklist

- [ ] Test SOS button appears when trip starts
- [ ] Test SOS sends correct location data
- [ ] Test SOS sends correct address
- [ ] Test SOS sends correct ride ID
- [ ] Test loading indicator shows and hides properly
- [ ] Test success message displays
- [ ] Test error handling when location permission denied
- [ ] Test error handling when network fails
- [ ] Test reverse geocoding fallback
- [ ] Verify backend receives correct data format
- [ ] Test SOS button only works during active trip

## Security Considerations

- ✅ **Authentication**: Uses Bearer token for API calls
- ✅ **Location Privacy**: Only sent when user explicitly taps SOS
- ✅ **Ride Validation**: Only works with active ride
- ✅ **Error Messages**: Don't expose sensitive information

## Future Enhancements

Potential improvements:
- Add confirmation dialog before sending SOS
- Allow user to add optional message/reason
- Show SOS history in user profile
- Add ability to cancel SOS if sent accidentally
- Implement real-time location tracking after SOS
- Add emergency contact notifications
- Integrate with local emergency services

## Notes

- The SOS button only appears and functions when the trip status is "started"
- Location is formatted as PostGIS POINT format for database compatibility
- Address is obtained through reverse geocoding (may fail in areas with poor mapping data)
- The implementation uses the existing Geolocator and Geocoding packages already in the project
- All SOS requests are logged with the 'SOS' tag for debugging
