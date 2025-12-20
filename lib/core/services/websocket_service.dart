import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:muvam/core/constants/url_constants.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/features/home/data/models/ride_models.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import '../constants/url_constants.dart';
// //FOR PASSENGER
// class WebSocketService {
//   WebSocketChannel? _channel;
//   bool _isConnected = false;
//   bool _isConnecting = false;
//   int _reconnectAttempts = 0;
//   static const int _maxReconnectAttempts = 5;

//   // Callbacks for different message types
//   Function(Map<String, dynamic>)? onRideAccepted;
//   Function(Map<String, dynamic>)? onRideUpdate;
//   Function(ChatMessage)? onChatMessage;
//   Function(Map<String, dynamic>)? onDriverLocation;
//   Function(Map<String, dynamic>)? onIncomingCall;
//   Function(Map<String, dynamic>)? onRideCompleted;

//   bool get isConnected => _isConnected;

//   Future<void> connect() async {
//     AppLogger.log('🚀 WEBSOCKET CONNECT METHOD CALLED');

//     if (_isConnected) {
//       AppLogger.log('⚠️ WebSocket already connected, skipping...');
//       return;
//     }

//     if (_isConnecting) {
//       AppLogger.log('⚠️ Connection already in progress, skipping...');
//       return;
//     }

//     _isConnecting = true;

//     try {
//       final token = await _getToken();
//       AppLogger.log(
//         '🔍 Token check result: ${token != null ? 'Found' : 'Not found'}',
//       );
//       if (token == null) {
//         AppLogger.log('❌ No auth token found for WebSocket');
//         return;
//       }

//       AppLogger.log('=== WEBSOCKET CONNECTION START ===');
//       AppLogger.log('🔗 Connecting to: ${UrlConstants.wsUrl}');
//       AppLogger.log('🔑 Using token: ${token.substring(0, 20)}...');
//       AppLogger.log('⏰ Connection time: ${DateTime.now()}');
//       AppLogger.log('🌐 Attempting WebSocket.connect...');

//       final webSocket = await WebSocket.connect(
//         UrlConstants.wsUrl,
//         headers: {'Authorization': 'Bearer $token'},
//       );

//       AppLogger.log('🔌 WebSocket.connect completed');
//       _channel = IOWebSocketChannel(webSocket);
//       _isConnected = true;
//       AppLogger.log('✅ WebSocket connected successfully!');
//       AppLogger.log('🎯 Ready to receive messages...');
//       AppLogger.log('📊 Connection state: $_isConnected');
//       AppLogger.log('📡 Channel created: ${_channel != null}');

//       _channel!.stream.listen(
//         (message) {
//           AppLogger.log('📥 WebSocket message received at ${DateTime.now()}');
//           _handleMessage(message);
//         },
//         onError: (error) {
//           AppLogger.log('❌ WebSocket error: $error');
//           _isConnected = false;
//           _isConnecting = false;
//           _reconnectAttempts++;
//           if (_reconnectAttempts <= _maxReconnectAttempts) {
//             _reconnect();
//           }
//         },
//         onDone: () {
//           AppLogger.log('🔌 WebSocket connection closed at ${DateTime.now()}');
//           AppLogger.log('🔍 Close reason: Server closed connection');
//           _isConnected = false;
//           _isConnecting = false;
//           _reconnectAttempts++;
//           if (_reconnectAttempts <= _maxReconnectAttempts) {
//             _reconnect();
//           }
//         },
//       );

//       AppLogger.log('✅ WebSocket listener setup complete');
//       _reconnectAttempts = 0;
//       _isConnecting = false;

//       AppLogger.log('🎯 WebSocket ready - no automatic test message sent');
//     } catch (e) {
//       AppLogger.log('❌ Failed to connect WebSocket: $e');
//       _isConnected = false;
//       _isConnecting = false;
//       _reconnectAttempts++;

//       if (_reconnectAttempts <= _maxReconnectAttempts) {
//         final delay = _getReconnectDelay();
//         AppLogger.log(
//           '🔄 Will attempt reconnection #$_reconnectAttempts in ${delay}s...',
//         );
//         _reconnect();
//       } else {
//         AppLogger.log(
//           '❌ Max reconnection attempts reached. Stopping reconnection.',
//         );
//       }
//     }
//     AppLogger.log('=== WEBSOCKET CONNECTION END ===\n');
//   }

//   void _reconnect() async {
//     final delay = _getReconnectDelay();
//     await Future.delayed(Duration(seconds: delay));
//     if (!_isConnected && !_isConnecting) {
//       connect();
//     }
//   }

//   int _getReconnectDelay() {
//     switch (_reconnectAttempts) {
//       case 1:
//         return 3;
//       case 2:
//         return 6;
//       case 3:
//         return 12;
//       case 4:
//         return 24;
//       default:
//         return 60;
//     }
//   }

//   void _handleMessage(dynamic message) {
//     AppLogger.log('=== WEBSOCKET MESSAGE RECEIVED ===');
//     AppLogger.log('📨 RAW MESSAGE: $message');
//     AppLogger.log('📋 Message type: ${message.runtimeType}');
//     AppLogger.log('📏 Message length: ${message.toString().length}');
//     AppLogger.log('📄 FULL RAW MESSAGE CONTENT: ${message.toString()}');

//     try {
//       AppLogger.log('🔄 Attempting to parse JSON from raw message...');
//       final data = jsonDecode(message);
//       AppLogger.log('🔍 Parsed JSON: $data');
//       AppLogger.log('🔍 JSON keys: ${data.keys.toList()}');
//       final type = data['type'];
//       AppLogger.log('🏷️ Message type from JSON: $type');

//       switch (type) {
//         case 'ride_accepted':
//           _handleRideAccepted(data);
//           break;
//         case 'ride_update':
//           _handleRideUpdate(data);
//           break;
//         case 'chat':
//         case 'chat_message':
//           _handleChatMessage(data);
//           break;
//         case 'driver_location':
//           _handleDriverLocation(data);
//           break;
//         case 'call_initiate':
//           _handleIncomingCall(data);
//           break;
//         case 'ride_completed':
//           _handleRideCompleted(data);
//           break;
//         default:
//           AppLogger.log('Unknown message type: $type');
//           AppLogger.log('Full message data: $data');
//       }
//     } catch (e) {
//       AppLogger.log('Error parsing WebSocket message: $e');
//       AppLogger.log('Raw message that failed: $message');
//     }
//     AppLogger.log('=== END WEBSOCKET MESSAGE ===\n');
//   }

//   void _handleRideAccepted(Map<String, dynamic> data) {
//     AppLogger.log('🚗 RIDE ACCEPTED MESSAGE:');
//     AppLogger.log('   Data: $data');

//     if (onRideAccepted != null) {
//       onRideAccepted!(data);
//     }
//   }

//   void _handleRideUpdate(Map<String, dynamic> data) {
//     AppLogger.log('📱 RIDE UPDATE MESSAGE:');
//     AppLogger.log('   Data: $data');

//     if (onRideUpdate != null) {
//       onRideUpdate!(data);
//     }
//   }

//   void _handleChatMessage(Map<String, dynamic> data) async {
//     AppLogger.log('💬 CHAT MESSAGE:');
//     AppLogger.log('   Full Data: $data');

//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final currentUserId = prefs.getString('user_id') ?? '';

//       // Extract message data from nested structure
//       final messageData = data['data'] ?? data;
//       AppLogger.log('   Message Data: $messageData');
      
//       // Transform backend format to expected format
//       final transformedData = {
//         'id': DateTime.now().millisecondsSinceEpoch.toString(),
//         'message': messageData['message'] ?? '',
//         'sender_id': messageData['sender_id'] ?? messageData['user_id'] ?? '',
//         'sender_type': messageData['sender_type'] ?? 'driver',
//         'timestamp': data['timestamp'] ?? DateTime.now().toIso8601String(),
//       };
//       AppLogger.log('   Transformed Data: $transformedData');
      
//       final chatMessage = ChatMessage.fromJson(transformedData, currentUserId);
//       AppLogger.log('   Parsed ChatMessage: ${chatMessage.message}');
      
//       if (onChatMessage != null) {
//         onChatMessage!(chatMessage);
//         AppLogger.log('   ✅ Chat message callback invoked');
//       } else {
//         AppLogger.log('   ⚠️ No chat message callback registered');
//       }
//     } catch (e, stackTrace) {
//       AppLogger.log('❌ Error handling chat message: $e');
//       AppLogger.log('   Stack trace: $stackTrace');
//     }
//   }

//   void _handleDriverLocation(Map<String, dynamic> data) {
//     AppLogger.log('📍 DRIVER LOCATION MESSAGE:');
//     AppLogger.log('   Data: $data');

//     if (onDriverLocation != null) {
//       onDriverLocation!(data);
//     }
//   }

//   void _handleIncomingCall(Map<String, dynamic> data) {
//     AppLogger.log('📞 INCOMING CALL MESSAGE:');
//     AppLogger.log('   Data: $data');

//     if (onIncomingCall != null) {
//       onIncomingCall!(data);
//     }
//   }

//   void _handleRideCompleted(Map<String, dynamic> data) {
//     AppLogger.log('🏁 RIDE COMPLETED MESSAGE:');
//     AppLogger.log('   RAW MESSAGE AS STRING FOR PASSENGER: "${data.toString()}"');
//     AppLogger.log('   Data: $data');

//     if (onRideCompleted != null) {
//       AppLogger.log('   ✅ Calling onRideCompleted callback');
//       onRideCompleted!(data);
//     } else {
//       AppLogger.log('   ⚠️ No onRideCompleted callback registered');
//     }
//   }

//   void sendMessage(Map<String, dynamic> message) {
//     AppLogger.log('=== WEBSOCKET SEND DEBUG ===');
//     AppLogger.log('Connected: $_isConnected');
//     AppLogger.log('Channel exists: ${_channel != null}');
//     AppLogger.log('Raw message: $message');

//     if (!_isConnected || _channel == null) {
//       AppLogger.log('❌ WebSocket not ready - forcing reconnect');
//       _forceReconnectAndSend(message);
//       return;
//     }

//     try {
//       final jsonMessage = jsonEncode(message);
//       AppLogger.log('📤 Sending exact JSON: $jsonMessage');
//       AppLogger.log('📤 Message length: ${jsonMessage.length} chars');

//       _channel!.sink.add(jsonMessage);
//       AppLogger.log('✅ Message added to sink successfully');

//       // Force flush
//       if (_channel!.sink is IOSink) {
//         (_channel!.sink as IOSink).flush();
//         AppLogger.log('✅ Sink flushed');
//       }
//     } catch (e, stackTrace) {
//       AppLogger.log('❌ Send failed: $e');
//       AppLogger.log('❌ Stack: $stackTrace');
//       _isConnected = false;
//     }
//   }

//   void _forceReconnectAndSend(Map<String, dynamic> message) async {
//     _isConnected = false;
//     _channel = null;

//     await connect();

//     if (_isConnected && _channel != null) {
//       final jsonMessage = jsonEncode(message);
//       _channel!.sink.add(jsonMessage);
//       AppLogger.log('✅ Message sent after forced reconnection');
//     } else {
//       AppLogger.log('❌ Forced reconnection failed');
//     }
//   }

//   void sendChatMessage(String message, String rideId) {
//     sendMessage({
//       'type': 'chat_message',
//       'message': message,
//       'ride_id': rideId,
//       'timestamp': DateTime.now().toIso8601String(),
//     });
//   }

//   void sendRideRequest(Map<String, dynamic> rideData) {
//     sendMessage({
//       'type': 'ride_request',
//       'data': rideData,
//       'timestamp': DateTime.now().toIso8601String(),
//     });
//   }

//   void disconnect() {
//     if (_channel != null) {
//       _channel!.sink.close();
//       _channel = null;
//       _isConnected = false;
//       _isConnecting = false;
//       _reconnectAttempts = 0;
//       AppLogger.log('WebSocket disconnected');
//     }
//   }

//   void resetConnection() {
//     AppLogger.log('🔄 Resetting WebSocket connection...');
//     disconnect();
//     _reconnectAttempts = 0;
//     connect();
//   }

//   Future<String?> _getToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString('auth_token');
//   }

//   void testConnection() {
//     AppLogger.log('=== CONNECTION TEST ===');
//     AppLogger.log('_isConnected: $_isConnected');
//     AppLogger.log('_channel != null: ${_channel != null}');
//     if (_channel != null) {
//       AppLogger.log('Channel type: ${_channel.runtimeType}');
//       AppLogger.log('Sink type: ${_channel!.sink.runtimeType}');
//     }

//     // Send a simple test message
//     sendMessage({
//       'type': 'test',
//       'message': 'Connection test',
//       'timestamp': DateTime.now().toIso8601String(),
//     });
//   }
// }





























// import 'dart:convert';
// import 'dart:io';
// import 'package:muvam/core/utils/app_logger.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:web_socket_channel/io.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../constants/url_constants.dart';

//FOR PASSENGER - Unified WebSocketService with Call Support
// class WebSocketService {
//   static WebSocketService? _instance;
//   WebSocketChannel? _channel;
//   bool _isConnected = false;
//   bool _isConnecting = false;
//   int _reconnectAttempts = 0;
//   static const int _maxReconnectAttempts = 5;

//   // Callbacks for different message types
//   Function(Map<String, dynamic>)? onRideAccepted;
//   Function(Map<String, dynamic>)? onRideUpdate;
//   Function(ChatMessage)? onChatMessage;
//   Function(Map<String, dynamic>)? onDriverLocation;
//   Function(Map<String, dynamic>)? onIncomingCall; // For ALL call messages
//   Function(Map<String, dynamic>)? onRideCompleted;

//   bool get isConnected => _isConnected;

//   // Singleton pattern
//   static WebSocketService get instance {
//     _instance ??= WebSocketService._internal();
//     return _instance!;
//   }

//   WebSocketService._internal();

//   Future<void> connect() async {
//     AppLogger.log('🚀 WEBSOCKET CONNECT METHOD CALLED');

//     if (_isConnected) {
//       AppLogger.log('⚠️ WebSocket already connected, skipping...');
//       return;
//     }

//     if (_isConnecting) {
//       AppLogger.log('⚠️ Connection already in progress, skipping...');
//       return;
//     }

//     _isConnecting = true;

//     try {
//       final token = await _getToken();
//       AppLogger.log(
//         '🔍 Token check result: ${token != null ? 'Found' : 'Not found'}',
//       );
//       if (token == null) {
//         AppLogger.log('❌ No auth token found for WebSocket');
//         _isConnecting = false;
//         return;
//       }

//       AppLogger.log('=== WEBSOCKET CONNECTION START ===');
//       AppLogger.log('🔗 Connecting to: ${UrlConstants.wsUrl}');
//       AppLogger.log('🔑 Using token: ${token.substring(0, 20)}...');
//       AppLogger.log('⏰ Connection time: ${DateTime.now()}');
//       AppLogger.log('🌐 Attempting WebSocket.connect...');

//       final webSocket = await WebSocket.connect(
//         UrlConstants.wsUrl,
//         headers: {'Authorization': 'Bearer $token'},
//       );

//       AppLogger.log('🔌 WebSocket.connect completed');
//       _channel = IOWebSocketChannel(webSocket);
//       _isConnected = true;
//       AppLogger.log('✅ WebSocket connected successfully!');
//       AppLogger.log('🎯 Ready to receive messages...');
//       AppLogger.log('📊 Connection state: $_isConnected');
//       AppLogger.log('📡 Channel created: ${_channel != null}');

//       _channel!.stream.listen(
//         (message) {
//           AppLogger.log('📥 WebSocket message received at ${DateTime.now()}');
//           _handleMessage(message);
//         },
//         onError: (error) {
//           AppLogger.log('❌ WebSocket error: $error');
//           _isConnected = false;
//           _isConnecting = false;
//           _reconnectAttempts++;
//           if (_reconnectAttempts <= _maxReconnectAttempts) {
//             _reconnect();
//           }
//         },
//         onDone: () {
//           AppLogger.log('🔌 WebSocket connection closed at ${DateTime.now()}');
//           AppLogger.log('🔍 Close reason: Server closed connection');
//           _isConnected = false;
//           _isConnecting = false;
//           _reconnectAttempts++;
//           if (_reconnectAttempts <= _maxReconnectAttempts) {
//             _reconnect();
//           }
//         },
//       );

//       AppLogger.log('✅ WebSocket listener setup complete');
//       _reconnectAttempts = 0;
//       _isConnecting = false;

//       AppLogger.log('🎯 WebSocket ready');
//     } catch (e) {
//       AppLogger.log('❌ Failed to connect WebSocket: $e');
//       _isConnected = false;
//       _isConnecting = false;
//       _reconnectAttempts++;

//       if (_reconnectAttempts <= _maxReconnectAttempts) {
//         final delay = _getReconnectDelay();
//         AppLogger.log(
//           '🔄 Will attempt reconnection #$_reconnectAttempts in ${delay}s...',
//         );
//         _reconnect();
//       } else {
//         AppLogger.log(
//           '❌ Max reconnection attempts reached. Stopping reconnection.',
//         );
//       }
//     }
//     AppLogger.log('=== WEBSOCKET CONNECTION END ===\n');
//   }

//   void _reconnect() async {
//     final delay = _getReconnectDelay();
//     await Future.delayed(Duration(seconds: delay));
//     if (!_isConnected && !_isConnecting) {
//       connect();
//     }
//   }

//   int _getReconnectDelay() {
//     switch (_reconnectAttempts) {
//       case 1:
//         return 3;
//       case 2:
//         return 6;
//       case 3:
//         return 12;
//       case 4:
//         return 24;
//       default:
//         return 60;
//     }
//   }

//   void _handleMessage(dynamic message) {
//     AppLogger.log('=== WEBSOCKET MESSAGE RECEIVED ===');
//     AppLogger.log('📨 RAW MESSAGE: $message');
//     AppLogger.log('📋 Message type: ${message.runtimeType}');
//     AppLogger.log('📏 Message length: ${message.toString().length}');

//     try {
//       AppLogger.log('🔄 Attempting to parse JSON from raw message...');
//       final data = jsonDecode(message);
//       AppLogger.log('🔍 Parsed JSON: $data');
//       AppLogger.log('🔍 JSON keys: ${data.keys.toList()}');
//       final type = data['type'];
//       AppLogger.log('🏷️ Message type from JSON: $type');

//       switch (type) {
//         case 'ride_accepted':
//           _handleRideAccepted(data);
//           break;
//         case 'ride_update':
//           _handleRideUpdate(data);
//           break;
//         case 'chat':
//         case 'chat_message':
//           _handleChatMessage(data);
//           break;
//         case 'driver_location':
//           _handleDriverLocation(data);
//           break;
//         // CRITICAL: Handle ALL call-related messages
//         case 'call_initiate':
//         case 'call_answer':
//         case 'call_reject':
//         case 'call_end':
//         case 'call_offer':
//         case 'call_answer_sdp':
//         case 'call_ice_candidate':
//           _handleCallMessage(data);
//           break;
//         case 'ride_completed':
//           _handleRideCompleted(data);
//           break;
//         default:
//           AppLogger.log('Unknown message type: $type');
//           AppLogger.log('Full message data: $data');
//       }
//     } catch (e) {
//       AppLogger.log('Error parsing WebSocket message: $e');
//       AppLogger.log('Raw message that failed: $message');
//     }
//     AppLogger.log('=== END WEBSOCKET MESSAGE ===\n');
//   }

//   void _handleRideAccepted(Map<String, dynamic> data) {
//     AppLogger.log('🚗 RIDE ACCEPTED MESSAGE:');
//     AppLogger.log('   Data: $data');

//     if (onRideAccepted != null) {
//       onRideAccepted!(data);
//     }
//   }

//   void _handleRideUpdate(Map<String, dynamic> data) {
//     AppLogger.log('📱 RIDE UPDATE MESSAGE:');
//     AppLogger.log('   Data: $data');

//     if (onRideUpdate != null) {
//       onRideUpdate!(data);
//     }
//   }

//   void _handleChatMessage(Map<String, dynamic> data) async {
//     AppLogger.log('💬 CHAT MESSAGE:');
//     AppLogger.log('   Full Data: $data');

//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final currentUserId = prefs.getString('user_id') ?? '';

//       // Extract message data from nested structure
//       final messageData = data['data'] ?? data;
//       AppLogger.log('   Message Data: $messageData');
      
//       // Transform backend format to expected format
//       final transformedData = {
//         'id': DateTime.now().millisecondsSinceEpoch.toString(),
//         'message': messageData['message'] ?? '',
//         'sender_id': messageData['sender_id'] ?? messageData['user_id'] ?? '',
//         'sender_type': messageData['sender_type'] ?? 'driver',
//         'timestamp': data['timestamp'] ?? DateTime.now().toIso8601String(),
//       };
//       AppLogger.log('   Transformed Data: $transformedData');
      
//       final chatMessage = ChatMessage.fromJson(transformedData, currentUserId);
//       AppLogger.log('   Parsed ChatMessage: ${chatMessage.message}');
      
//       if (onChatMessage != null) {
//         onChatMessage!(chatMessage);
//         AppLogger.log('   ✅ Chat message callback invoked');
//       } else {
//         AppLogger.log('   ⚠️ No chat message callback registered');
//       }
//     } catch (e, stackTrace) {
//       AppLogger.log('❌ Error handling chat message: $e');
//       AppLogger.log('   Stack trace: $stackTrace');
//     }
//   }

//   void _handleDriverLocation(Map<String, dynamic> data) {
//     AppLogger.log('📍 DRIVER LOCATION MESSAGE:');
//     AppLogger.log('   Data: $data');

//     if (onDriverLocation != null) {
//       onDriverLocation!(data);
//     }
//   }

//   // CRITICAL: Route ALL call messages to the same callback
//   void _handleCallMessage(Map<String, dynamic> data) {
//     final type = data['type'];
//     AppLogger.log('📞 CALL MESSAGE: $type');
//     AppLogger.log('   Data: $data');

//     if (onIncomingCall != null) {
//       AppLogger.log('✅ Routing call message to callback');
//       onIncomingCall!(data);
//     } else {
//       AppLogger.log('⚠️ No call callback registered!');
//     }
//   }

//   void _handleRideCompleted(Map<String, dynamic> data) {
//     AppLogger.log('🏁 RIDE COMPLETED MESSAGE:');
//     AppLogger.log('   Data: $data');

//     if (onRideCompleted != null) {
//       AppLogger.log('   ✅ Calling onRideCompleted callback');
//       onRideCompleted!(data);
//     } else {
//       AppLogger.log('   ⚠️ No onRideCompleted callback registered');
//     }
//   }

//   void sendMessage(Map<String, dynamic> message) {
//     AppLogger.log('=== WEBSOCKET SEND DEBUG ===');
//     AppLogger.log('Connected: $_isConnected');
//     AppLogger.log('Channel exists: ${_channel != null}');
//     AppLogger.log('Raw message: $message');

//     if (!_isConnected || _channel == null) {
//       AppLogger.log('❌ WebSocket not ready - forcing reconnect');
//       _forceReconnectAndSend(message);
//       return;
//     }

//     try {
//       // Add timestamp if not present
//       if (!message.containsKey('timestamp')) {
//         message['timestamp'] = DateTime.now().toIso8601String();
//       }

//       final jsonMessage = jsonEncode(message);
//       AppLogger.log('📤 Sending exact JSON: $jsonMessage');
//       AppLogger.log('📤 Message length: ${jsonMessage.length} chars');

//       _channel!.sink.add(jsonMessage);
//       AppLogger.log('✅ Message added to sink successfully');

//       // Force flush
//       if (_channel!.sink is IOSink) {
//         (_channel!.sink as IOSink).flush();
//         AppLogger.log('✅ Sink flushed');
//       }
//     } catch (e, stackTrace) {
//       AppLogger.log('❌ Send failed: $e');
//       AppLogger.log('❌ Stack: $stackTrace');
//       _isConnected = false;
//     }
//   }

//   void _forceReconnectAndSend(Map<String, dynamic> message) async {
//     _isConnected = false;
//     _channel = null;

//     await connect();

//     if (_isConnected && _channel != null) {
//       final jsonMessage = jsonEncode(message);
//       _channel!.sink.add(jsonMessage);
//       AppLogger.log('✅ Message sent after forced reconnection');
//     } else {
//       AppLogger.log('❌ Forced reconnection failed');
//     }
//   }

//   void sendChatMessage(String message, String rideId) {
//     sendMessage({
//       'type': 'chat_message',
//       'message': message,
//       'ride_id': rideId,
//     });
//   }

//   void sendRideRequest(Map<String, dynamic> rideData) {
//     sendMessage({
//       'type': 'ride_request',
//       'data': rideData,
//     });
//   }

//   void disconnect() {
//     if (_channel != null) {
//       _channel!.sink.close();
//       _channel = null;
//       _isConnected = false;
//       _isConnecting = false;
//       _reconnectAttempts = 0;
//       AppLogger.log('WebSocket disconnected');
//     }
//   }

//   void resetConnection() {
//     AppLogger.log('🔄 Resetting WebSocket connection...');
//     disconnect();
//     _reconnectAttempts = 0;
//     connect();
//   }

//   Future<String?> _getToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString('auth_token');
//   }

//   void testConnection() {
//     AppLogger.log('=== CONNECTION TEST ===');
//     AppLogger.log('_isConnected: $_isConnected');
//     AppLogger.log('_channel != null: ${_channel != null}');
//     if (_channel != null) {
//       AppLogger.log('Channel type: ${_channel.runtimeType}');
//       AppLogger.log('Sink type: ${_channel!.sink.runtimeType}');
//     }

//     // Send a simple test message
//     sendMessage({
//       'type': 'test',
//       'message': 'Connection test',
//     });
//   }
// }























// // FOR PASSENGER - FIXED WebSocketService
// class WebSocketService {
//   static WebSocketService? _instance;
//   WebSocketChannel? _channel;
//   bool _isConnected = false;
//   bool _isConnecting = false;
//   int _reconnectAttempts = 0;
//   static const int _maxReconnectAttempts = 5;

//   // FIXED: Callbacks should accept Map<String, dynamic>
//   Function(Map<String, dynamic>)? onRideAccepted;
//   Function(Map<String, dynamic>)? onRideUpdate;
//   Function(Map<String, dynamic>)? onChatMessage; // CHANGED TYPE
//   Function(Map<String, dynamic>)? onDriverLocation;
//   Function(Map<String, dynamic>)? onIncomingCall;
//   Function(Map<String, dynamic>)? onRideCompleted;

//   bool get isConnected => _isConnected;

//   static WebSocketService get instance {
//     _instance ??= WebSocketService._internal();
//     return _instance!;
//   }

//   WebSocketService._internal();

//   Future<void> connect() async {
//     AppLogger.log('🚀 WEBSOCKET CONNECT METHOD CALLED');

//     if (_isConnected) {
//       AppLogger.log('⚠️ WebSocket already connected, skipping...');
//       return;
//     }

//     if (_isConnecting) {
//       AppLogger.log('⚠️ Connection already in progress, skipping...');
//       return;
//     }

//     _isConnecting = true;

//     try {
//       final token = await _getToken();
//       AppLogger.log(
//         '🔍 Token check result: ${token != null ? 'Found' : 'Not found'}',
//       );
//       if (token == null) {
//         AppLogger.log('❌ No auth token found for WebSocket');
//         _isConnecting = false;
//         return;
//       }

//       AppLogger.log('=== WEBSOCKET CONNECTION START ===');
//       AppLogger.log('🔗 Connecting to: ${UrlConstants.wsUrl}');
//       AppLogger.log('🔑 Using token: ${token.substring(0, 20)}...');
//       AppLogger.log('⏰ Connection time: ${DateTime.now()}');
//       AppLogger.log('🌐 Attempting WebSocket.connect...');

//       final webSocket = await WebSocket.connect(
//         UrlConstants.wsUrl,
//         headers: {'Authorization': 'Bearer $token'},
//       );

//       AppLogger.log('🔌 WebSocket.connect completed');
//       _channel = IOWebSocketChannel(webSocket);
//       _isConnected = true;
//       AppLogger.log('✅ WebSocket connected successfully!');
//       AppLogger.log('🎯 Ready to receive messages...');
//       AppLogger.log('📊 Connection state: $_isConnected');
//       AppLogger.log('📡 Channel created: ${_channel != null}');

//       _channel!.stream.listen(
//         (message) {
//           AppLogger.log('📥 WebSocket message received at ${DateTime.now()}');
//           _handleMessage(message);
//         },
//         onError: (error) {
//           AppLogger.log('❌ WebSocket error: $error');
//           _isConnected = false;
//           _isConnecting = false;
//           _reconnectAttempts++;
//           if (_reconnectAttempts <= _maxReconnectAttempts) {
//             _reconnect();
//           }
//         },
//         onDone: () {
//           AppLogger.log('🔌 WebSocket connection closed at ${DateTime.now()}');
//           AppLogger.log('🔍 Close reason: Server closed connection');
//           _isConnected = false;
//           _isConnecting = false;
//           _reconnectAttempts++;
//           if (_reconnectAttempts <= _maxReconnectAttempts) {
//             _reconnect();
//           }
//         },
//       );

//       AppLogger.log('✅ WebSocket listener setup complete');
//       _reconnectAttempts = 0;
//       _isConnecting = false;

//       AppLogger.log('🎯 WebSocket ready');
//     } catch (e) {
//       AppLogger.log('❌ Failed to connect WebSocket: $e');
//       _isConnected = false;
//       _isConnecting = false;
//       _reconnectAttempts++;

//       if (_reconnectAttempts <= _maxReconnectAttempts) {
//         final delay = _getReconnectDelay();
//         AppLogger.log(
//           '🔄 Will attempt reconnection #$_reconnectAttempts in ${delay}s...',
//         );
//         _reconnect();
//       } else {
//         AppLogger.log(
//           '❌ Max reconnection attempts reached. Stopping reconnection.',
//         );
//       }
//     }
//     AppLogger.log('=== WEBSOCKET CONNECTION END ===\n');
//   }

//   void _reconnect() async {
//     final delay = _getReconnectDelay();
//     await Future.delayed(Duration(seconds: delay));
//     if (!_isConnected && !_isConnecting) {
//       connect();
//     }
//   }

//   int _getReconnectDelay() {
//     switch (_reconnectAttempts) {
//       case 1:
//         return 3;
//       case 2:
//         return 6;
//       case 3:
//         return 12;
//       case 4:
//         return 24;
//       default:
//         return 60;
//     }
//   }

//   void _handleMessage(dynamic message) {
//     AppLogger.log('=== WEBSOCKET MESSAGE RECEIVED ===');
//     AppLogger.log('📨 RAW MESSAGE FORPASSENGER: $message');
//     AppLogger.log('📋 Message type: ${message.runtimeType}');
//     AppLogger.log('📏 Message length: ${message.toString().length}');

//     try {
//       AppLogger.log('🔄 Attempting to parse JSON from raw message FROM PASSENGER...');
//       final data = jsonDecode(message);
//       AppLogger.log('🔍 Parsed JSON: $data');
//       AppLogger.log('🔍 JSON keys: ${data.keys.toList()}');
//       final type = data['type'];
//       AppLogger.log('🏷️ Message type from JSON: $type');

//       switch (type) {
//         case 'ride_accepted':
//           _handleRideAccepted(data);
//           break;
//         case 'ride_update':
//           _handleRideUpdate(data);
//           break;
//         case 'chat':
//         case 'chat_message':
//           _handleChatMessage(data);
//           break;
//         case 'driver_location':
//           _handleDriverLocation(data);
//           break;
//         case 'call_initiate':
//         case 'call_answer':
//         case 'call_reject':
//         case 'call_end':
//         case 'call_offer':
//         case 'call_answer_sdp':
//         case 'call_ice_candidate':
//           _handleCallMessage(data);
//           break;
//         case 'ride_completed':
//           _handleRideCompleted(data);
//           break;
//         default:
//           AppLogger.log('Unknown message type: $type');
//           AppLogger.log('Full message data: $data');
//       }
//     } catch (e) {
//       AppLogger.log('Error parsing WebSocket message: $e');
//       AppLogger.log('Raw message that failed: $message');
//     }
//     AppLogger.log('=== END WEBSOCKET MESSAGE ===\n');
//   }

//   void _handleRideAccepted(Map<String, dynamic> data) {
//     AppLogger.log('🚗 RIDE ACCEPTED MESSAGE:');
//     AppLogger.log('   Data: $data');

//     if (onRideAccepted != null) {
//       onRideAccepted!(data);
//     }
//   }

//   void _handleRideUpdate(Map<String, dynamic> data) {
//     AppLogger.log('📱 RIDE UPDATE MESSAGE:');
//     AppLogger.log('   Data: $data');

//     if (onRideUpdate != null) {
//       onRideUpdate!(data);
//     }
//   }

//   // FIXED: Pass raw data instead of transforming to ChatMessage
//   void _handleChatMessage(Map<String, dynamic> data) {
//     AppLogger.log('💬 CHAT MESSAGE:');
//     AppLogger.log('   Full Data: $data');

//     try {
//       // Pass the complete data to callback - let ChatScreen handle parsing
//       if (onChatMessage != null) {
//         AppLogger.log('✅ Calling onChatMessage callback with raw data');
//         onChatMessage!(data);
//       } else {
//         AppLogger.log('⚠️ No chat message callback registered');
//       }
//     } catch (e, stackTrace) {
//       AppLogger.log('❌ Error handling chat message: $e');
//       AppLogger.log('   Stack trace: $stackTrace');
//     }
//   }

//   void _handleDriverLocation(Map<String, dynamic> data) {
//     AppLogger.log('📍 DRIVER LOCATION MESSAGE:');
//     AppLogger.log('   Data: $data');

//     if (onDriverLocation != null) {
//       onDriverLocation!(data);
//     }
//   }

//   void _handleCallMessage(Map<String, dynamic> data) {
//     final type = data['type'];
//     AppLogger.log('📞 CALL MESSAGE: $type');
//     AppLogger.log('   Data: $data');

//     if (onIncomingCall != null) {
//       AppLogger.log('✅ Routing call message to callback');
//       onIncomingCall!(data);
//     } else {
//       AppLogger.log('⚠️ No call callback registered!');
//     }
//   }

//   void _handleRideCompleted(Map<String, dynamic> data) {
//     AppLogger.log('🏁 RIDE COMPLETED MESSAGE:');
//     AppLogger.log('   Data: $data');

//     if (onRideCompleted != null) {
//       AppLogger.log('   ✅ Calling onRideCompleted callback');
//       onRideCompleted!(data);
//     } else {
//       AppLogger.log('   ⚠️ No onRideCompleted callback registered');
//     }
//   }

//   void sendMessage(Map<String, dynamic> message) {
//     AppLogger.log('=== WEBSOCKET SEND DEBUG ===');
//     AppLogger.log('Connected: $_isConnected');
//     AppLogger.log('Channel exists: ${_channel != null}');
//     AppLogger.log('Raw message  FROM PASSENGER: $message');

//     if (!_isConnected || _channel == null) {
//       AppLogger.log('❌ WebSocket not ready - forcing reconnect');
//       _forceReconnectAndSend(message);
//       return;
//     }

//     try {
//       // Add timestamp if not present
//       if (!message.containsKey('timestamp')) {
//         message['timestamp'] = DateTime.now().toIso8601String();
//       }

//       final jsonMessage = jsonEncode(message);
//       AppLogger.log('📤 Sending exact JSON: $jsonMessage');
//       AppLogger.log('📤 Message length: ${jsonMessage.length} chars');

//       _channel!.sink.add(jsonMessage);
//       AppLogger.log('✅ Message added to sink successfully');

//       // Force flush
//       if (_channel!.sink is IOSink) {
//         (_channel!.sink as IOSink).flush();
//         AppLogger.log('✅ Sink flushed');
//       }
//     } catch (e, stackTrace) {
//       AppLogger.log('❌ Send failed: $e');
//       AppLogger.log('❌ Stack: $stackTrace');
//       _isConnected = false;
//     }
//   }

//   void _forceReconnectAndSend(Map<String, dynamic> message) async {
//     _isConnected = false;
//     _channel = null;

//     await connect();

//     if (_isConnected && _channel != null) {
//       final jsonMessage = jsonEncode(message);
//       _channel!.sink.add(jsonMessage);
//       AppLogger.log('✅ Message sent after forced reconnection');
//     } else {
//       AppLogger.log('❌ Forced reconnection failed');
//     }
//   }

//   // REMOVED: Old sendChatMessage method - use sendMessage directly

//   void sendRideRequest(Map<String, dynamic> rideData) {
//     sendMessage({'type': 'ride_request', 'data': rideData});
//   }

//   void disconnect() {
//     if (_channel != null) {
//       _channel!.sink.close();
//       _channel = null;
//       _isConnected = false;
//       _isConnecting = false;
//       _reconnectAttempts = 0;
//       AppLogger.log('WebSocket disconnected');
//     }
//   }

//   void resetConnection() {
//     AppLogger.log('🔄 Resetting WebSocket connection...');
//     disconnect();
//     _reconnectAttempts = 0;
//     connect();
//   }

//   Future<String?> _getToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString('auth_token');
//   }

//   void testConnection() {
//     AppLogger.log('=== CONNECTION TEST ===');
//     AppLogger.log('_isConnected: $_isConnected');
//     AppLogger.log('_channel != null: ${_channel != null}');
//     if (_channel != null) {
//       AppLogger.log('Channel type: ${_channel.runtimeType}');
//       AppLogger.log('Sink type: ${_channel!.sink.runtimeType}');
//     }

//     // Send a simple test message
//     sendMessage({'type': 'test', 'message': 'Connection test'});
//   }
// }
























// FIXED WebSocket Service - Synchronous setup
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class WebSocketService {
  static WebSocketService? _instance;
  WebSocket? _socket;
  final String? token;
  bool _isConnected = false;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  // Callbacks for different message types
  Function(dynamic)? onMessageReceived;
  Function(Map<String, dynamic>)? onRideAccepted;
  Function(Map<String, dynamic>)? onRideUpdate;
  Function(Map<String, dynamic>)? onChatMessage;
  Function(Map<String, dynamic>)? onDriverLocation;
  Function(Map<String, dynamic>)? onIncomingCall;
  Function(Map<String, dynamic>)? onRideCompleted;
  Function(Map<String, dynamic>)? onRideRequest;

  bool get isConnected => _isConnected;

  // Singleton pattern
  static WebSocketService get instance {
    _instance ??= WebSocketService._internal();
    return _instance!;
  }

  WebSocketService._internal() : token = null;

  Future<void> connect() async {
    print('🚀 NATIVE WEBSOCKET CONNECT');

    if (_isConnected) {
      print('⚠️ Already connected');
      return;
    }

    if (_isConnecting) {
      print('⚠️ Connection in progress');
      return;
    }

    _isConnecting = true;

    try {
      // Get token from storage
      final authToken = await _getToken();
      if (authToken == null) {
        print('❌ No auth token found');
        _isConnecting = false;
        return;
      }

      print('═══════════════════════════════════════');
      print('NATIVE WEBSOCKET CONNECTION');
      print('═══════════════════════════════════════');
      print('URL: ${UrlConstants.wsUrl}');
      print('Token: ${authToken.substring(0, 20)}...');
      print('Time: ${DateTime.now()}');
      print('═══════════════════════════════════════');

      // Parse URL
      final uri = Uri.parse(UrlConstants.wsUrl);

      // Headers - Try lowercase 'authorization' to match Postman exactly
      final headers = {'authorization': 'Bearer $authToken'};

      print('📋 Headers:');
      headers.forEach((key, value) {
        print(
          ' headerss  $key: ${value.length > 50 ? "${value.substring(0, 50)}..." : value}',
        );
      });

      // Connect using native WebSocket
      print('🌐 Connecting...');
      _socket = await WebSocket.connect(
        uri.toString(), 
        headers: headers,
      );

      print('✅ WebSocket connected!');
      print('   ReadyState: ${_socket!.readyState}');
      print('');
      
      // CRITICAL: Setup listeners IMMEDIATELY and SYNCHRONOUSLY
      print('🎧 Setting up listeners NOW...');
      _setupListenersSync();
      print('✅ Listeners attached');
      print('');
      
      // Small delay to let the connection stabilize
      print('⏳ Stabilizing connection...');
      await Future.delayed(Duration(milliseconds: 200));
      print('✅ Connection stabilized');
      print('');
      
      // NOW it's safe to mark as connected
      _reconnectAttempts = 0;
      _isConnecting = false;
      _isConnected = true;

      print('✅ Native WebSocket FULLY ready');
      print('═══════════════════════════════════════');
      print('');
    } catch (e, stack) {
      print('❌ Connection error: $e');
      print('Stack: $stack');
      _isConnected = false;
      _isConnecting = false;
      _socket = null;
      _reconnectAttempts++;

      if (_reconnectAttempts <= _maxReconnectAttempts) {
        _reconnect();
      }
    }
  }

  // CRITICAL: Synchronous listener setup - no async gaps
  void _setupListenersSync() {
    if (_socket == null) {
      print('❌ Cannot setup listeners - socket is null');
      return;
    }

    print('   Attaching onData handler...');
    print('   Attaching onDone handler...');
    print('   Attaching onError handler...');
    
    _socket!.listen(
      (event) {
        print('');
        print('═══════════════════════════════════════');
        print('📥 MESSAGE RECEIVED');
        print('═══════════════════════════════════════');
        print('Time: ${DateTime.now()}');
        print('Event type: ${event.runtimeType}');
        print('Raw event: $event');

        try {
          // Handle both String and List<int> responses
          String messageStr;
          if (event is String) {
            messageStr = event;
          } else if (event is List<int>) {
            messageStr = utf8.decode(event);
          } else {
            messageStr = event.toString();
          }
          
          print('Decoded message: $messageStr');
          
          final data = jsonDecode(messageStr);
          print('Parsed JSON: $data');
          print('Message type: ${data['type']}');
          print('═══════════════════════════════════════');
          print('');

          // Call general message callback
          if (onMessageReceived != null) {
            onMessageReceived!(data);
          }

          // Route to specific handlers
          _handleMessage(data);
        } catch (e, stack) {
          print('❌ Message parse error: $e');
          print('Stack: $stack');
          print('═══════════════════════════════════════');
          print('');
        }
      },
      onDone: () {
        print('');
        print('═══════════════════════════════════════');
        print('⚠️ WebSocket connection CLOSED');
        print('═══════════════════════════════════════');
        print('Time: ${DateTime.now()}');
        print('Close code: ${_socket?.closeCode}');
        print('Close reason: ${_socket?.closeReason}');
        print('Was Connected: $_isConnected');
        print('Is Connecting: $_isConnecting');
        print('═══════════════════════════════════════');
        print('');

        bool wasConnected = _isConnected;
        _isConnected = false;
        _isConnecting = false;

        // Only reconnect if we were actually connected (not during initial setup)
        if (wasConnected) {
          _reconnectAttempts++;
          if (_reconnectAttempts <= _maxReconnectAttempts) {
            _reconnect();
          }
        }
      },
      onError: (error) {
        print('');
        print('═══════════════════════════════════════');
        print('❌ WebSocket ERROR');
        print('═══════════════════════════════════════');
        print('Time: ${DateTime.now()}');
        print('Error: $error');
        print('Error type: ${error.runtimeType}');
        print('═══════════════════════════════════════');
        print('');

        _isConnected = false;
        _isConnecting = false;
      },
      cancelOnError: false,
    );
    
    print('   ✅ All handlers attached successfully');
  }
Function(Map<String, dynamic>)? onChatNotification;

  void _handleMessage(Map<String, dynamic> data) {
    final type = data['type'];
    print('🔀 Routing message type: $type');

    switch (type) {
      case 'ride_accepted':
        print('   → ride_accepted handler');
        if (onRideAccepted != null) onRideAccepted!(data);
        break;
      case 'ride_update':
        print('   → ride_update handler');
        if (onRideUpdate != null) onRideUpdate!(data);
        break;
      case 'chat':
      case 'chat_message':
        print('   → chat handler');
        if (onChatMessage != null) {
          onChatMessage!(data);
        }if (onChatNotification != null) {
          onChatNotification!(
            data,
          ); // Pass null for context, we'll handle it in HomeScreen
        }  else {
          print('   ⚠️ No chat handler registered!');
        }
        break;
      case 'driver_location':
        print('   → driver_location handler');
        if (onDriverLocation != null) onDriverLocation!(data);
        break;
      case 'call_initiate':
      case 'call_answer':
      case 'call_reject':
      case 'call_end':
      case 'call_offer':
      case 'call_answer_sdp':
      case 'call_ice_candidate':
        print('   → call handler');
        if (onIncomingCall != null) onIncomingCall!(data);
        break;
      case 'ride_completed':
        print('   → ride_completed handler');
        if (onRideCompleted != null) onRideCompleted!(data);
        break;
      case 'ride_request':
      case 'new_ride':
        print('   → ride_request handler');
        if (onRideRequest != null) onRideRequest!(data);
        break;
      default:
        print('   ⚠️ Unknown message type: $type');
    }
  }

  void _reconnect() async {
    final delay = _getReconnectDelay();
    print('⏰ Reconnecting in ${delay}s... (attempt ${_reconnectAttempts}/${_maxReconnectAttempts})');
    await Future.delayed(Duration(seconds: delay));

    if (!_isConnected && !_isConnecting) {
      connect();
    }
  }

  int _getReconnectDelay() {
    switch (_reconnectAttempts) {
      case 1:
        return 2;
      case 2:
        return 4;
      case 3:
        return 8;
      default:
        return 15;
    }
  }

  // Send JSON with extensive logging
  void _sendJson(Map<String, dynamic> message) {
    print('');
    print('═══════════════════════════════════════');
    print('📤 ATTEMPTING TO SEND MESSAGE');
    print('═══════════════════════════════════════');
    print('Time: ${DateTime.now()}');
    
    // Pre-flight checks
    print('PRE-FLIGHT CHECKS:');
    print('   _isConnected: $_isConnected');
    print('   _isConnecting: $_isConnecting');
    print('   _socket != null: ${_socket != null}');
    
    if (_socket != null) {
      print('   _socket.readyState: ${_socket!.readyState}');
      print('   WebSocket.open: ${WebSocket.open}');
      print('   States match: ${_socket!.readyState == WebSocket.open}');
      print('   _socket.closeCode: ${_socket!.closeCode}');
      print('   _socket.closeReason: ${_socket!.closeReason}');
    }
    
    print('');
    print('MESSAGE PAYLOAD:');
    print('   $message');
    print('');

    // Check 1: Socket exists
    if (_socket == null) {
      print('❌ SEND BLOCKED: Socket is null');
      print('═══════════════════════════════════════');
      print('');
      return;
    }

    // Check 2: Marked as connected
    if (!_isConnected) {
      print('❌ SEND BLOCKED: Not marked as connected');
      print('   Hint: Connection may still be initializing');
      print('═══════════════════════════════════════');
      print('');
      return;
    }

    // Check 3: Socket is open
    if (_socket!.readyState != WebSocket.open) {
      print('❌ SEND BLOCKED: Socket not in OPEN state');
      print('   Current state: ${_socket!.readyState}');
      print('   Expected state: ${WebSocket.open}');
      print('═══════════════════════════════════════');
      print('');
      
      // Try to reconnect if socket is closed
      _isConnected = false;
      _reconnect();
      return;
    }

    // All checks passed, send the message
    try {
      final jsonMessage = jsonEncode(message);
      print('SENDING:');
      print('   JSON string: $jsonMessage');
      print('   Length: ${jsonMessage.length} bytes');
      print('');
      
      _socket!.add(jsonMessage);
      
      print('✅ MESSAGE SENT SUCCESSFULLY');
      print('   Message added to socket send buffer');
      print('   Socket state after send: ${_socket!.readyState}');
      print('   Waiting for server response...');
      print('═══════════════════════════════════════');
      print('');
    } catch (e, stackTrace) {
      print('❌ SEND EXCEPTION: $e');
      print('Stack trace:');
      print('$stackTrace');
      print('═══════════════════════════════════════');
      print('');
      
      // Mark as disconnected and try to reconnect
      _isConnected = false;
      _reconnect();
    }
  }

  // Public send methods
  void sendMessage(Map<String, dynamic> message) {
    // Add timestamp if not present
    // if (!message.containsKey('timestamp')) {
    //   message['timestamp'] = DateTime.now().toIso8601String();
    // }
    _sendJson(message);
  }
Future<void> sendChatMessage(int rideId, String message) async {
  print('💬 sendChatMessage called');
  print('   Ride: $rideId');
  print('   Message: "$message"');
  
  // Get user info from SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('user_id');
  final userName = prefs.getString('user_name') ?? 
                   prefs.getString('name') ?? 
                   'Unknown User';
  
  print('   User ID: $userId');
  print('   User Name: $userName');
  
  // Create timestamp with timezone offset (mimicking Postman format)
  final now = DateTime.now();
  final offset = now.timeZoneOffset;
  final offsetHours = offset.inHours;
  final offsetMinutes = offset.inMinutes.remainder(60);
  final offsetString = '${offsetHours >= 0 ? '+' : ''}${offsetHours.toString().padLeft(2, '0')}:${offsetMinutes.abs().toString().padLeft(2, '0')}';
  final timestamp = '${now.toIso8601String()}$offsetString';
  
  final payload = {
    "type": "chat",
    "data": {
      "ride_id": rideId,  // ← Now uses actual ride ID
      "message": message,  // ← Now uses actual message
    },
    "timestamp": timestamp,  // ← Proper timezone format
  };
  
  print('   Full payload: $payload');
  print('   Timestamp format: $timestamp');
  _sendJson(payload);
}

  void sendRideRequest(Map<String, dynamic> rideData) {
    _sendJson({
      'type': 'ride_request',
      'data': rideData,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Listeners
  void listenToMessages(Function(dynamic) callback) {
    onMessageReceived = callback;
  }

  void disconnect() {
    print('🔌 Disconnecting WebSocket');
    _socket?.close();
    _socket = null;
    _isConnected = false;
    _isConnecting = false;
    _reconnectAttempts = 0;
    print('✅ WebSocket disconnected');
  }

  void resetConnection() {
    print('🔄 Resetting connection');
    disconnect();
    _reconnectAttempts = 0;
    connect();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  void dispose() {
    disconnect();
  }
}