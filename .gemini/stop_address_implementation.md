# Stop Address Implementation

## Summary
Added `stop_address` field to the RideRequest model to support multi-stop rides. The field is optional and will only be included in the API request when provided.

## Changes Made

### **File:** `lib/features/home/data/models/ride_models.dart`

#### 1. **Added stopAddress Field**

```dart
class RideRequest {
  final String dest;
  final String destAddress;
  final String paymentMethod;
  final String pickup;
  final String pickupAddress;
  final String serviceType;
  final String vehicleType;
  final bool? scheduled;
  final String? scheduledAt;
  final String? stopAddress;  // ✅ NEW FIELD

  RideRequest({
    required this.dest,
    required this.destAddress,
    required this.paymentMethod,
    required this.pickup,
    required this.pickupAddress,
    required this.serviceType,
    required this.vehicleType,
    this.scheduled,
    this.scheduledAt,
    this.stopAddress,  // ✅ NEW PARAMETER
  });
```

#### 2. **Updated toJson() Method**

```dart
Map<String, dynamic> toJson() {
  final Map<String, dynamic> json = {
    "pickup": pickup,
    "dest": dest,
    "pickup_address": pickupAddress,
    "dest_address": destAddress,
    "service_type": serviceType,
    "vehicle_type": vehicleType,
    "payment_method": _getPaymentMethodKey(paymentMethod),
  };

  if (scheduled == true && scheduledAt != null) {
    json["scheduled"] = scheduled;
    json["scheduled_at"] = scheduledAt;
  }

  // ✅ NEW: Only include stop_address if provided
  if (stopAddress != null && stopAddress!.isNotEmpty) {
    json["stop_address"] = stopAddress;
  }

  return json;
}
```

## How It Works

### Request Without Stop Address
```json
{
  "pickup": "POINT(-122.4194 37.7749)",
  "dest": "POINT(-122.4084 37.7849)",
  "pickup_address": "123 Main St",
  "dest_address": "456 Oak Ave",
  "service_type": "standard",
  "vehicle_type": "sedan",
  "payment_method": "in_car"
}
```

### Request With Stop Address
```json
{
  "pickup": "POINT(-122.4194 37.7749)",
  "dest": "POINT(-122.4084 37.7849)",
  "pickup_address": "123 Main St",
  "dest_address": "456 Oak Ave",
  "service_type": "standard",
  "vehicle_type": "sedan",
  "payment_method": "in_car",
  "stop_address": "789 Elm Street"  // ✅ Included when provided
}
```

## Usage Example

### Creating a Ride Request with Stop Address

```dart
final request = RideRequest(
  pickup: "POINT(-122.4194 37.7749)",
  dest: "POINT(-122.4084 37.7849)",
  pickupAddress: "123 Main St",
  destAddress: "456 Oak Ave",
  serviceType: "standard",
  vehicleType: "sedan",
  paymentMethod: "Pay in car",
  stopAddress: "789 Elm Street",  // ✅ Optional stop address
);

// Send request
final response = await rideService.requestRide(request);
```

### Creating a Ride Request without Stop Address

```dart
final request = RideRequest(
  pickup: "POINT(-122.4194 37.7749)",
  dest: "POINT(-122.4084 37.7849)",
  pickupAddress: "123 Main St",
  destAddress: "456 Oak Ave",
  serviceType: "standard",
  vehicleType: "sedan",
  paymentMethod: "Pay in car",
  // stopAddress not provided - will not be included in JSON
);
```

## Integration Points

### Where to Add Stop Address

When creating a `RideRequest` in your code, you can now optionally include the `stopAddress` parameter:

**Example in home_screen.dart:**
```dart
Future<RideResponse> _requestRide({
  bool isScheduled = false,
  DateTime? scheduledDateTime,
  String? stopAddress,  // Add this parameter
}) async {
  // ... existing code ...
  
  final request = RideRequest(
    pickup: pickupCoords,
    dest: destCoords,
    pickupAddress: pickupAddr,
    destAddress: destAddr,
    serviceType: _currentEstimate!.serviceType,
    vehicleType: vehicleType,
    paymentMethod: selectedPaymentMethod,
    scheduled: isScheduled,
    scheduledAt: isScheduled ? scheduledDateTime?.toUtc().toIso8601String() + 'Z' : null,
    stopAddress: stopAddress,  // ✅ Pass stop address
  );
  
  return await _rideService.requestRide(request);
}
```

## API Request Format

### Endpoint
```
POST /api/v1/rides/request
```

### Headers
```
Content-Type: application/json
Authorization: Bearer {token}
```

### Request Body (with stop_address)
```json
{
  "pickup": "POINT(-122.4194 37.7749)",
  "dest": "POINT(-122.4084 37.7849)",
  "pickup_address": "123 Main St",
  "dest_address": "456 Oak Ave",
  "stop_address": "789 Elm Street",
  "service_type": "standard",
  "vehicle_type": "sedan",
  "payment_method": "in_car"
}
```

## Benefits

✅ **Optional Field** - Only included when needed
✅ **Backward Compatible** - Existing code continues to work
✅ **Clean Implementation** - Follows existing pattern
✅ **Type Safe** - Nullable String type
✅ **Automatic Serialization** - toJson() handles it automatically

## Testing

### Test Cases

1. **Request without stop address**
   - Create RideRequest without stopAddress
   - Verify JSON doesn't include "stop_address" key
   
2. **Request with stop address**
   - Create RideRequest with stopAddress
   - Verify JSON includes "stop_address" key with correct value

3. **Request with empty stop address**
   - Create RideRequest with stopAddress = ""
   - Verify JSON doesn't include "stop_address" key (empty check)

4. **Request with null stop address**
   - Create RideRequest with stopAddress = null
   - Verify JSON doesn't include "stop_address" key

### Example Test

```dart
void testStopAddress() {
  // Test with stop address
  final requestWithStop = RideRequest(
    pickup: "POINT(-122.4194 37.7749)",
    dest: "POINT(-122.4084 37.7849)",
    pickupAddress: "123 Main St",
    destAddress: "456 Oak Ave",
    serviceType: "standard",
    vehicleType: "sedan",
    paymentMethod: "in_car",
    stopAddress: "789 Elm Street",
  );
  
  final jsonWithStop = requestWithStop.toJson();
  assert(jsonWithStop.containsKey("stop_address"));
  assert(jsonWithStop["stop_address"] == "789 Elm Street");
  
  // Test without stop address
  final requestWithoutStop = RideRequest(
    pickup: "POINT(-122.4194 37.7749)",
    dest: "POINT(-122.4084 37.7849)",
    pickupAddress: "123 Main St",
    destAddress: "456 Oak Ave",
    serviceType: "standard",
    vehicleType: "sedan",
    paymentMethod: "in_car",
  );
  
  final jsonWithoutStop = requestWithoutStop.toJson();
  assert(!jsonWithoutStop.containsKey("stop_address"));
}
```

## Logging

The existing ride request logging in `ride_service.dart` will automatically show the stop_address when included:

```
🔍 REQUEST BODY BREAKDOWN:
  pickup: POINT(-122.4194 37.7749)
  dest: POINT(-122.4084 37.7849)
  pickup_address: 123 Main St
  dest_address: 456 Oak Ave
  stop_address: 789 Elm Street  ✅ Will appear when provided
  service_type: standard
  vehicle_type: sedan
  payment_method: in_car
```

## Next Steps

1. **Update UI** - Add input field for stop address (if needed)
2. **Pass stop address** - Update ride request calls to include stop address
3. **Test** - Verify stop address is sent correctly to backend
4. **Handle response** - Ensure backend returns stop address in response (if applicable)

The `stop_address` field is now ready to use! Simply pass it when creating a `RideRequest` and it will automatically be included in the API request.
