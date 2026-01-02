// // Example: How to send call notification when initiating a call

// import 'package:muvam/core/services/call_notification_service.dart';
// import 'package:muvam/core/services/call_service.dart';
// import 'package:muvam/core/utils/app_logger.dart';

// class CallInitiationExample {
//   /// Example: Passenger calls driver
//   static Future<void> passengerCallsDriver({
//     required int rideId,
//     required String driverId,
//     required String passengerName,
//   }) async {
//     try {
//       AppLogger.log('📞 Initiating call to driver', tag: 'CALL_EXAMPLE');

//       // 1. Initialize call via WebSocket/API
//       final callService = CallService();
//       await callService.initialize();

//       // This will create a session and send call_initiate via WebSocket
//       await callService.initiateCall(rideId);

//       // 2. Send FCM notification to driver
//       // This makes the driver's phone ring!
//       await CallNotificationService.sendIncomingCallNotification(
//         receiverId: driverId,
//         callerName: passengerName,
//         sessionId: callService.sessionId ?? '',
//         rideId: rideId,
//       );

//       AppLogger.log(
//         '✅ Call initiated and notification sent',
//         tag: 'CALL_EXAMPLE',
//       );
//     } catch (e) {
//       AppLogger.error(
//         '❌ Failed to initiate call',
//         error: e,
//         tag: 'CALL_EXAMPLE',
//       );
//     }
//   }

//   /// Example: Driver calls passenger
//   static Future<void> driverCallsPassenger({
//     required int rideId,
//     required String passengerId,
//     required String driverName,
//   }) async {
//     try {
//       AppLogger.log('📞 Initiating call to passenger', tag: 'CALL_EXAMPLE');

//       // 1. Initialize call
//       final callService = CallService();
//       await callService.initialize();
//       await callService.initiateCall(rideId);

//       // 2. Send FCM notification to passenger
//       await CallNotificationService.sendIncomingCallNotification(
//         receiverId: passengerId,
//         callerName: driverName,
//         sessionId: callService.sessionId ?? '',
//         rideId: rideId,
//       );

//       AppLogger.log(
//         '✅ Call initiated and notification sent',
//         tag: 'CALL_EXAMPLE',
//       );
//     } catch (e) {
//       AppLogger.error(
//         '❌ Failed to initiate call',
//         error: e,
//         tag: 'CALL_EXAMPLE',
//       );
//     }
//   }

//   /// Example: Handle call end
//   static Future<void> handleCallEnd({
//     required String receiverId,
//     required String callerName,
//     String? reason,
//   }) async {
//     try {
//       await CallNotificationService.sendCallEndedNotification(
//         receiverId: receiverId,
//         callerName: callerName,
//         reason: reason,
//       );

//       AppLogger.log('✅ Call ended notification sent', tag: 'CALL_EXAMPLE');
//     } catch (e) {
//       AppLogger.error(
//         '❌ Failed to send call ended notification',
//         error: e,
//         tag: 'CALL_EXAMPLE',
//       );
//     }
//   }

//   /// Example: Handle missed call
//   static Future<void> handleMissedCall({
//     required String receiverId,
//     required String callerName,
//     required int rideId,
//   }) async {
//     try {
//       await CallNotificationService.sendMissedCallNotification(
//         receiverId: receiverId,
//         callerName: callerName,
//         rideId: rideId,
//       );

//       AppLogger.log('✅ Missed call notification sent', tag: 'CALL_EXAMPLE');
//     } catch (e) {
//       AppLogger.error(
//         '❌ Failed to send missed call notification',
//         error: e,
//         tag: 'CALL_EXAMPLE',
//       );
//     }
//   }
// }

// // ============================================
// // USAGE IN YOUR EXISTING CODE
// // ============================================

// /*
// In your chat_screen.dart or wherever you initiate calls:

// // When user taps the call button:
// void _initiateCall() async {
//   final prefs = await SharedPreferences.getInstance();
//   final userName = prefs.getString('user_name') ?? 'Passenger';
  
//   await CallInitiationExample.passengerCallsDriver(
//     rideId: widget.rideId,
//     driverId: widget.driverId,
//     passengerName: userName,
//   );
  
//   // Navigate to call screen
//   Navigator.push(
//     context,
//     MaterialPageRoute(
//       builder: (context) => CallScreen(
//         driverName: widget.driverName,
//         rideId: widget.rideId,
//       ),
//     ),
//   );
// }

// // When call ends:
// void _onCallEnded(String reason) async {
//   await CallInitiationExample.handleCallEnd(
//     receiverId: widget.driverId,
//     callerName: 'You',
//     reason: reason,
//   );
// }

// // When call is rejected/missed:
// void _onCallRejected() async {
//   await CallInitiationExample.handleMissedCall(
//     receiverId: widget.driverId,
//     callerName: 'You',
//     rideId: widget.rideId,
//   );
// }
// */
