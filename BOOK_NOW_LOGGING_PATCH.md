# Book Now Button Logging Patch

## Instructions
Add these imports to your home_screen.dart file at the top:

```dart
import 'package:muvam/core/utils/book_now_logger.dart';
import 'package:muvam/core/utils/debug_helper.dart';
```

## 1. Find the "Book Now" button in your _showBookingDetails() method

Look for this code pattern:
```dart
GestureDetector(
  onTap: !_isBookingRide
      ? () async {
          setBookingState(() {
            _isBookingRide = true;
          });
          try {
            _currentRideResponse = await _requestRide();
            // ... rest of the code
          } catch (e) {
            // ... error handling
          }
        }
      : null,
  child: Container(
    // ... Book Now button UI
  ),
),
```

## 2. Replace the onTap handler with this logged version:

```dart
GestureDetector(
  onTap: !_isBookingRide
      ? () async {
          // LOG: Book Now button tapped
          BookNowLogger.logBookNowTapped(
            fromLocation: fromController.text.isNotEmpty ? fromController.text : 'Current location',
            toLocation: toController.text.isNotEmpty ? toController.text : 'Destination',
            selectedVehicle: selectedVehicle != null 
                ? ['Regular vehicle', 'Fancy vehicle', 'VIP'][selectedVehicle!] 
                : 'Unknown',
            paymentMethod: selectedPaymentMethod,
            isBookingInProgress: _isBookingRide,
          );

          // LOG: Button validation
          BookNowLogger.logButtonValidation(
            isEnabled: !_isBookingRide,
            reason: _isBookingRide ? 'Booking already in progress' : 'Button enabled',
          );

          // LOG: Payment flow start
          BookNowLogger.logPaymentFlowStart(selectedPaymentMethod);

          if (selectedPaymentMethod == 'Pay with card') {
            BookNowLogger.logCardPaymentSelected();
            
            // Check if we need to initialize payment first
            if (_currentRideResponse == null) {
              BookNowLogger.logRideRequestStart();
              
              setBookingState(() {
                _isBookingRide = true;
              });
              
              try {
                _currentRideResponse = await _requestRide();
                
                BookNowLogger.logRideRequestComplete(
                  true, 
                  rideId: _currentRideResponse?.id.toString()
                );
                
                // Now initialize payment
                BookNowLogger.logAsyncOperation('Payment initialization', () async {
                  final paymentData = await _paymentService.initializePayment(
                    rideId: _currentRideResponse!.id,
                    amount: _currentRideResponse!.price,
                  );
                  
                  if (paymentData['authorization_url'] != null) {
                    BookNowLogger.logNavigation('PaymentWebViewScreen', params: {
                      'authorizationUrl': paymentData['authorization_url'],
                      'reference': paymentData['reference'],
                    });
                    
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentWebViewScreen(
                          authorizationUrl: paymentData['authorization_url'],
                          reference: paymentData['reference'],
                          onPaymentSuccess: () {
                            BookNowLogger.logUserInteraction('Payment success callback triggered');
                          },
                        ),
                      ),
                    );
                    
                    BookNowLogger.logNavigation('Returned from PaymentWebViewScreen', params: {
                      'result': result,
                    });
                    
                    if (result == true) {
                      BookNowLogger.logUIStateChange('payment', 'success');
                      // Handle successful payment
                    } else {
                      BookNowLogger.logUIStateChange('payment', 'cancelled');
                      // Handle cancelled payment
                    }
                  } else {
                    BookNowLogger.logCriticalError('No authorization URL in payment response', 
                      context: {'paymentData': paymentData});
                  }
                });
                
              } catch (e, stackTrace) {
                BookNowLogger.logRideRequestComplete(false, error: e.toString());
                BookNowLogger.logCriticalError('Ride request failed', 
                  error: e, 
                  stackTrace: stackTrace,
                  context: {
                    'fromLocation': fromController.text,
                    'toLocation': toController.text,
                    'selectedVehicle': selectedVehicle,
                    'paymentMethod': selectedPaymentMethod,
                  });
                
                if (mounted) {
                  setBookingState(() {
                    _isBookingRide = false;
                  });
                }
              }
            }
          } else {
            BookNowLogger.logPayInCarSelected();
            
            // Original flow for non-card payments
            setBookingState(() {
              _isBookingRide = true;
            });
            
            try {
              BookNowLogger.logRideRequestStart();
              _currentRideResponse = await _requestRide();
              
              BookNowLogger.logRideRequestComplete(
                true, 
                rideId: _currentRideResponse?.id.toString()
              );

              if (mounted) {
                fromController.clear();
                toController.clear();
                setState(() {
                  _showDestinationField = false;
                });
                
                BookNowLogger.logModalEvent('close', 'BookingDetailsSheet');
                Navigator.pop(context);
                
                BookNowLogger.logModalEvent('show', 'BookingRequestSheet');
                _showBookingRequestSheet();
              }
            } catch (e, stackTrace) {
              BookNowLogger.logRideRequestComplete(false, error: e.toString());
              BookNowLogger.logCriticalError('Ride request failed', 
                error: e, 
                stackTrace: stackTrace);
              
              if (mounted) {
                setBookingState(() {
                  _isBookingRide = false;
                });
              }
            }
          }
        }
      : null,
  child: Container(
    // ... existing Book Now button UI code remains the same
  ),
),
```

## 3. Add logging to payment method selection

In your `_buildPaymentOption` method, add logging:

```dart
Widget _buildPaymentOption(String method) {
  final isSelected = selectedPaymentMethod == method;
  return GestureDetector(
    onTap: () {
      BookNowLogger.logUserInteraction('Payment method selected', details: {
        'method': method,
        'previousMethod': selectedPaymentMethod,
      });
      
      setState(() {
        selectedPaymentMethod = method;
      });
      Navigator.pop(context);
    },
    child: Padding(
      // ... existing UI code
    ),
  );
}
```

## 4. Add logging to vehicle selection

In your vehicle selection code, add:

```dart
GestureDetector(
  onTap: () {
    BookNowLogger.logUserInteraction('Vehicle selected', details: {
      'vehicleIndex': i,
      'vehicleType': vehicleType,
      'totalFare': totalFare,
      'previousSelection': selectedVehicle,
    });
    
    setState(() {
      selectedVehicle = i;
    });
    setModalState(() {});
  },
  child: Container(
    // ... existing vehicle option UI
  ),
),
```

## 5. Test the logging

After applying these changes:

1. Run your app
2. Go through the booking flow
3. Select "Pay with card" as payment method
4. Tap "Book Now"
5. Check your console/logs for detailed output

The logs will show you exactly what's happening at each step, including:
- When the button is tapped
- What data is being sent
- API responses
- Navigation events
- Any errors that occur

Look for logs tagged with `[BOOK_NOW]`, `[BOOKING]`, and `[PAYMENT]` to trace the entire flow.