# Payment Verification Implementation

## Summary
Implemented payment reference ID generation and verification for card payments. When a user selects "Pay with card", the system now generates a unique reference ID, includes it in the payment request, and can verify the payment status using the `/api/v1/payment/verify/{reference}` endpoint.

## Changes Made

### 1. **URL Constants** (`lib/core/constants/url_constants.dart`)

Added payment verify endpoint:

```dart
// Payment
static const String paymentInitialize = "/payment/initialize";
static const String paymentVerify = "/payment/verify";  // ✅ New
```

### 2. **Payment Service** (`lib/core/services/payment_service.dart`)

#### Added Reference ID Generation

```dart
/// Generate a unique reference ID for payment
String generateReference() {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final random = Random().nextInt(999999).toString().padLeft(6, '0');
  final reference = 'MUV-$timestamp-$random';
  AppLogger.log('Generated payment reference: $reference', tag: 'PAYMENT');
  return reference;
}
```

**Reference Format:** `MUV-{timestamp}-{random6digits}`

**Example:** `MUV-1735251234567-123456`

#### Updated initializePayment Method

**Before:**
```dart
Future<Map<String, dynamic>> initializePayment({
  required int rideId,
  required double amount,
}) async {
  // ...
  body: jsonEncode({
    'ride_id': rideId,
    'amount': amount,
  }),
}
```

**After:**
```dart
Future<Map<String, dynamic>> initializePayment({
  required int rideId,
  required double amount,
  String? reference,  // ✅ Optional reference parameter
}) async {
  final paymentReference = reference ?? generateReference();  // ✅ Auto-generate if not provided
  
  // ...
  body: jsonEncode({
    'ride_id': rideId,
    'amount': amount,
    'reference': paymentReference,  // ✅ Include reference in request
  }),
  
  // ...
  final responseData = jsonDecode(response.body);
  // Ensure reference is included in response
  if (!responseData.containsKey('reference')) {
    responseData['reference'] = paymentReference;  // ✅ Add reference to response
  }
  return responseData;
}
```

#### Added verifyPayment Method

```dart
Future<Map<String, dynamic>> verifyPayment(String reference) async {
  AppLogger.log('🔍 Verifying payment with reference: $reference', tag: 'PAYMENT');
  
  final token = await _getToken();
  
  final response = await http.get(
    Uri.parse('${UrlConstants.baseUrl}${UrlConstants.paymentVerify}/$reference'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  AppLogger.log('Payment Verify Response Status: ${response.statusCode}', tag: 'PAYMENT');
  AppLogger.log('Payment Verify Response Body: ${response.body}', tag: 'PAYMENT');

  if (response.statusCode == 200) {
    final responseData = jsonDecode(response.body);
    AppLogger.log(
      '✅ Payment verification result: ${responseData['status'] ?? 'unknown'}',
      tag: 'PAYMENT',
    );
    return responseData;
  } else {
    throw Exception('Failed to verify payment: ${response.body}');
  }
}
```

## How to Use

### Step 1: Initialize Payment Service

```dart
import 'package:muvam/core/services/payment_service.dart';

class YourScreen extends StatefulWidget {
  // ...
}

class _YourScreenState extends State<YourScreen> {
  final PaymentService _paymentService = PaymentService();
  
  // ...
}
```

### Step 2: Check Payment Method

When user selects payment method, check if it's card payment:

```dart
if (selectedPaymentMethod == 'Pay with card' || 
    selectedPaymentMethod == 'gateway') {
  // Handle card payment with verification
  await _handleCardPayment();
} else {
  // Handle other payment methods (wallet, in_car, etc.)
  await _handleOtherPayment();
}
```

### Step 3: Handle Card Payment

```dart
Future<void> _handleCardPayment() async {
  try {
    // 1. Generate reference ID
    final reference = _paymentService.generateReference();
    AppLogger.log('Payment reference: $reference');
    
    // 2. Initialize payment (this might open payment gateway)
    final initResponse = await _paymentService.initializePayment(
      rideId: _currentRideResponse!.rideId,
      amount: _currentEstimate!.priceList[selectedVehicle!]['total_fare'],
      reference: reference,
    );
    
    AppLogger.log('Payment initialized: $initResponse');
    
    // 3. Open payment gateway (e.g., Paystack, Flutterwave)
    // The payment gateway URL should be in initResponse['authorization_url']
    // You can use webview_flutter or url_launcher to open it
    
    final paymentUrl = initResponse['authorization_url'];
    if (paymentUrl != null) {
      // Open payment gateway in webview
      await _openPaymentGateway(paymentUrl, reference);
    }
    
  } catch (e) {
    AppLogger.error('Payment initialization failed: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to initialize payment: $e')),
    );
  }
}
```

### Step 4: Open Payment Gateway

```dart
Future<void> _openPaymentGateway(String url, String reference) async {
  // Option 1: Using webview_flutter
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PaymentWebView(
        url: url,
        reference: reference,
        onPaymentComplete: () => _verifyPayment(reference),
      ),
    ),
  );
  
  // Option 2: Using url_launcher
  // await launchUrl(Uri.parse(url));
  // Then poll for verification or use callback URL
}
```

### Step 5: Verify Payment

```dart
Future<void> _verifyPayment(String reference) async {
  try {
    // Show loading
    setState(() {
      _isVerifyingPayment = true;
    });
    
    // Verify payment
    final verifyResponse = await _paymentService.verifyPayment(reference);
    
    AppLogger.log('Payment verification response: $verifyResponse');
    
    // Check payment status
    final status = verifyResponse['status'];
    final success = verifyResponse['success'] ?? false;
    
    if (success && status == 'success') {
      // Payment successful!
      AppLogger.log('✅ Payment verified successfully!');
      
      // Close payment screen
      Navigator.pop(context);
      
      // Show success sheet (e.g., trip scheduled sheet)
      _showTripScheduledSheet(
        pickupAddress: _pickupAddress,
        destAddress: _destAddress,
      );
      
    } else {
      // Payment failed
      AppLogger.warning('❌ Payment verification failed: $status');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
  } catch (e) {
    AppLogger.error('Payment verification error: $e');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to verify payment: $e'),
        backgroundColor: Colors.red,
      ),
    );
    
  } finally {
    setState(() {
      _isVerifyingPayment = false;
    });
  }
}
```

## Complete Payment Flow

### Flow Diagram

```
User selects "Pay with card"
      ↓
Generate reference ID (MUV-{timestamp}-{random})
      ↓
Initialize payment with reference
      ↓
Backend returns payment gateway URL
      ↓
Open payment gateway in WebView
      ↓
User completes payment on gateway
      ↓
Gateway redirects back to app
      ↓
Verify payment with reference ID
      ↓
Check verification response
      ↓
If success → Show success sheet
If failed → Show error message
```

### Example Implementation in home_screen.dart

```dart
// In _HomeScreenState class

final PaymentService _paymentService = PaymentService();
bool _isVerifyingPayment = false;
String? _currentPaymentReference;

Future<void> _requestRide({
  bool isScheduled = false,
  DateTime? scheduledDateTime,
}) async {
  // ... existing code ...
  
  // After creating RideRequest
  final request = RideRequest(
    // ... existing fields ...
    paymentMethod: convertedPaymentMethod,
  );
  
  // Check if card payment
  if (convertedPaymentMethod == 'gateway') {
    // Handle card payment with verification
    await _handleCardPaymentFlow(request, scheduledDateTime);
  } else {
    // Handle other payment methods normally
    final response = await _rideService.requestRide(request);
    // ... handle response ...
  }
}

Future<void> _handleCardPaymentFlow(
  RideRequest request,
  DateTime? scheduledDateTime,
) async {
  try {
    // 1. Generate reference
    _currentPaymentReference = _paymentService.generateReference();
    
    // 2. Request ride first
    final rideResponse = await _rideService.requestRide(request);
    
    if (rideResponse != null) {
      // 3. Initialize payment
      final paymentInit = await _paymentService.initializePayment(
        rideId: rideResponse.rideId,
        amount: _currentEstimate!.priceList[selectedVehicle!]['total_fare'],
        reference: _currentPaymentReference!,
      );
      
      // 4. Open payment gateway
      final paymentUrl = paymentInit['authorization_url'];
      if (paymentUrl != null) {
        await _openPaymentGateway(paymentUrl);
      }
    }
    
  } catch (e) {
    AppLogger.error('Card payment flow error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: $e')),
    );
  }
}

Future<void> _openPaymentGateway(String url) async {
  // Navigate to payment webview
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PaymentWebViewScreen(
        url: url,
        reference: _currentPaymentReference!,
      ),
    ),
  );
  
  // When user returns from payment
  if (result == 'success') {
    await _verifyAndProceed();
  }
}

Future<void> _verifyAndProceed() async {
  if (_currentPaymentReference == null) return;
  
  setState(() {
    _isVerifyingPayment = true;
  });
  
  try {
    final verifyResponse = await _paymentService.verifyPayment(
      _currentPaymentReference!,
    );
    
    if (verifyResponse['success'] == true) {
      // Payment verified! Show success sheet
      _showTripScheduledSheet(
        pickupAddress: _pickupAddress,
        destAddress: _destAddress,
      );
    } else {
      throw Exception('Payment not successful');
    }
    
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment verification failed: $e')),
    );
  } finally {
    setState(() {
      _isVerifyingPayment = false;
    });
  }
}
```

## API Endpoints

### 1. Initialize Payment

**Endpoint:** `POST /api/v1/payment/initialize`

**Request:**
```json
{
  "ride_id": 123,
  "amount": 5000.0,
  "reference": "MUV-1735251234567-123456"
}
```

**Response:**
```json
{
  "success": true,
  "authorization_url": "https://checkout.paystack.com/...",
  "access_code": "abc123xyz",
  "reference": "MUV-1735251234567-123456"
}
```

### 2. Verify Payment

**Endpoint:** `GET /api/v1/payment/verify/{reference}`

**Example:** `GET /api/v1/payment/verify/MUV-1735251234567-123456`

**Response (Success):**
```json
{
  "success": true,
  "status": "success",
  "amount": 5000.0,
  "reference": "MUV-1735251234567-123456",
  "paid_at": "2025-12-26T22:30:00Z"
}
```

**Response (Failed):**
```json
{
  "success": false,
  "status": "failed",
  "message": "Payment was not completed"
}
```

## Reference ID Format

**Pattern:** `MUV-{timestamp}-{random}`

**Components:**
- `MUV` - Prefix for Muvam
- `{timestamp}` - Milliseconds since epoch (13 digits)
- `{random}` - 6-digit random number (padded with zeros)

**Example:** `MUV-1735251234567-123456`

**Why this format?**
- ✅ **Unique** - Timestamp + random ensures uniqueness
- ✅ **Traceable** - Can extract timestamp for debugging
- ✅ **Readable** - Clear prefix identifies it as Muvam payment
- ✅ **URL-safe** - No special characters that need encoding

## Error Handling

### Common Errors

1. **Payment initialization fails**
```dart
try {
  await _paymentService.initializePayment(...);
} catch (e) {
  // Show error to user
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Failed to start payment: $e')),
  );
}
```

2. **Payment verification fails**
```dart
try {
  final result = await _paymentService.verifyPayment(reference);
  if (result['success'] != true) {
    throw Exception('Payment not successful');
  }
} catch (e) {
  // Payment failed or couldn't verify
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Payment verification failed: $e')),
  );
}
```

3. **User cancels payment**
```dart
// In PaymentWebView, detect when user goes back
@override
Widget build(BuildContext context) {
  return WillPopScope(
    onWillPop: () async {
      // User is leaving payment screen
      Navigator.pop(context, 'cancelled');
      return false;
    },
    child: WebView(...),
  );
}
```

## Testing

### Test Reference IDs

For testing, you can use predefined references:

```dart
// Development/Testing
final testReference = 'MUV-TEST-${DateTime.now().millisecondsSinceEpoch}';

// Production
final prodReference = _paymentService.generateReference();
```

### Mock Verification Response

```dart
// For testing without actual payment
Future<Map<String, dynamic>> mockVerifyPayment(String reference) async {
  await Future.delayed(Duration(seconds: 2)); // Simulate network delay
  
  return {
    'success': true,
    'status': 'success',
    'amount': 5000.0,
    'reference': reference,
    'paid_at': DateTime.now().toIso8601String(),
  };
}
```

## Next Steps

To fully implement card payment verification in your app:

1. **Create PaymentWebView Screen** - For displaying payment gateway
2. **Update ride request flow** - Check payment method and handle accordingly
3. **Add loading states** - Show progress during verification
4. **Handle callbacks** - Process payment gateway redirects
5. **Add retry logic** - Allow users to retry failed payments
6. **Store references** - Save payment references for transaction history

## Benefits

✅ **Secure** - Verify payments server-side before proceeding
✅ **Traceable** - Unique reference for each transaction
✅ **Reliable** - Confirmation before showing success
✅ **User-friendly** - Clear feedback on payment status
✅ **Debuggable** - Comprehensive logging for troubleshooting

## Related Files

- `lib/core/services/payment_service.dart` - Payment service with verification
- `lib/core/constants/url_constants.dart` - API endpoint constants
- `lib/features/home/presentation/screens/home_screen.dart` - Where to integrate payment flow
