// import 'dart:convert';
// import 'dart:io';
// import 'dart:async';
// import 'package:muvam/core/constants/url_constants.dart';
// import 'package:muvam/core/utils/app_logger.dart';
// import 'package:muvam/features/home/data/models/ride_models.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:web_socket_channel/io.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// // import '../constants/url_constants.dart';
// // //FOR PASSENGER
// // FIXED WebSocket Service - Synchronous setup
// import 'dart:convert';
// import 'dart:io';
// import 'package:shared_preferences/shared_preferences.dart';

// class WebSocketService {
//   static WebSocketService? _instance;
//   WebSocket? _socket;
//   final String? token;
//   bool _isConnected = false;
//   bool _isConnecting = false;
//   int _reconnectAttempts = 0;
//   static const int _maxReconnectAttempts = 5;

//   // Callbacks for different message types
//   Function(dynamic)? onMessageReceived;
//   Function(Map<String, dynamic>)? onRideAccepted;
//   Function(Map<String, dynamic>)? onRideUpdate;
//   Function(Map<String, dynamic>)? onChatMessage;
//   Function(Map<String, dynamic>)? onDriverLocation;
//   Function(Map<String, dynamic>)? onIncomingCall;
//   Function(Map<String, dynamic>)? onRideCompleted;
//   Function(Map<String, dynamic>)? onRideRequest;

//   bool get isConnected => _isConnected;

//   // Singleton pattern
//   static WebSocketService get instance {
//     _instance ??= WebSocketService._internal();
//     return _instance!;
//   }

//   WebSocketService._internal() : token = null;

//   Future<void> connect() async {
//     print('🚀 NATIVE WEBSOCKET CONNECT');

//     if (_isConnected) {
//       print('⚠️ Already connected');
//       return;
//     }

//     if (_isConnecting) {
//       print('⚠️ Connection in progress');
//       return;
//     }

//     _isConnecting = true;

//     try {
//       // Get token from storage
//       final authToken = await _getToken();
//       if (authToken == null) {
//         print('❌ No auth token found');
//         _isConnecting = false;
//         return;
//       }

//       print('═══════════════════════════════════════');
//       print('NATIVE WEBSOCKET CONNECTION');
//       print('═══════════════════════════════════════');
//       print('URL: ${UrlConstants.wsUrl}');
//       print('Token: ${authToken.substring(0, 20)}...');
//       print('Time: ${DateTime.now()}');
//       print('═══════════════════════════════════════');

//       // Parse URL
//       final uri = Uri.parse(UrlConstants.wsUrl);

//       // Headers - Try lowercase 'authorization' to match Postman exactly
//       final headers = {'authorization': 'Bearer $authToken'};

//       print('📋 Headers:');
//       headers.forEach((key, value) {
//         print(
//           ' headerss  $key: ${value.length > 50 ? "${value.substring(0, 50)}..." : value}',
//         );
//       });

//       // Connect using native WebSocket
//       print('🌐 Connecting...');
//       _socket = await WebSocket.connect(
//         uri.toString(), 
//         headers: headers,
//       );

//       print('✅ WebSocket connected!');
//       print('   ReadyState: ${_socket!.readyState}');
//       print('');
      
//       // CRITICAL: Setup listeners IMMEDIATELY and SYNCHRONOUSLY
//       print('🎧 Setting up listeners NOW...');
//       _setupListenersSync();
//       print('✅ Listeners attached');
//       print('');
      
//       // Small delay to let the connection stabilize
//       print('⏳ Stabilizing connection...');
//       await Future.delayed(Duration(milliseconds: 200));
//       print('✅ Connection stabilized');
//       print('');
      
//       // NOW it's safe to mark as connected
//       _reconnectAttempts = 0;
//       _isConnecting = false;
//       _isConnected = true;

//       print('✅ Native WebSocket FULLY ready');
//       print('═══════════════════════════════════════');
//       print('');
//     } catch (e, stack) {
//       print('❌ Connection error: $e');
//       print('Stack: $stack');
//       _isConnected = false;
//       _isConnecting = false;
//       _socket = null;
//       _reconnectAttempts++;

//       if (_reconnectAttempts <= _maxReconnectAttempts) {
//         _reconnect();
//       }
//     }
//   }

//   // CRITICAL: Synchronous listener setup - no async gaps
//   void _setupListenersSync() {
//     if (_socket == null) {
//       print('❌ Cannot setup listeners - socket is null');
//       return;
//     }

//     print('   Attaching onData handler...');
//     print('   Attaching onDone handler...');
//     print('   Attaching onError handler...');
    
//     _socket!.listen(
//       (event) {
//         print('');
//         print('═══════════════════════════════════════');
//         print('📥 MESSAGE RECEIVED');
//         print('═══════════════════════════════════════');
//         print('Time: ${DateTime.now()}');
//         print('Event type: ${event.runtimeType}');
//         print('Raw event: $event');

//         try {
//           // Handle both String and List<int> responses
//           String messageStr;
//           if (event is String) {
//             messageStr = event;
//           } else if (event is List<int>) {
//             messageStr = utf8.decode(event);
//           } else {
//             messageStr = event.toString();
//           }
          
//           print('Decoded message: $messageStr');
          
//           final data = jsonDecode(messageStr);
//           print('Parsed JSON: $data');
//           print('Message type: ${data['type']}');
//           print('═══════════════════════════════════════');
//           print('');

//           // Call general message callback
//           if (onMessageReceived != null) {
//             onMessageReceived!(data);
//           }

//           // Route to specific handlers
//           _handleMessage(data);
//         } catch (e, stack) {
//           print('❌ Message parse error: $e');
//           print('Stack: $stack');
//           print('═══════════════════════════════════════');
//           print('');
//         }
//       },
//       onDone: () {
//         print('');
//         print('═══════════════════════════════════════');
//         print('⚠️ WebSocket connection CLOSED');
//         print('═══════════════════════════════════════');
//         print('Time: ${DateTime.now()}');
//         print('Close code: ${_socket?.closeCode}');
//         print('Close reason: ${_socket?.closeReason}');
//         print('Was Connected: $_isConnected');
//         print('Is Connecting: $_isConnecting');
//         print('═══════════════════════════════════════');
//         print('');

//         bool wasConnected = _isConnected;
//         _isConnected = false;
//         _isConnecting = false;

//         // Only reconnect if we were actually connected (not during initial setup)
//         if (wasConnected) {
//           _reconnectAttempts++;
//           if (_reconnectAttempts <= _maxReconnectAttempts) {
//             _reconnect();
//           }
//         }
//       },
//       onError: (error) {
//         print('');
//         print('═══════════════════════════════════════');
//         print('❌ WebSocket ERROR');
//         print('═══════════════════════════════════════');
//         print('Time: ${DateTime.now()}');
//         print('Error: $error');
//         print('Error type: ${error.runtimeType}');
//         print('═══════════════════════════════════════');
//         print('');

//         _isConnected = false;
//         _isConnecting = false;
//       },
//       cancelOnError: false,
//     );
    
//     print('   ✅ All handlers attached successfully');
//   }
// Function(Map<String, dynamic>)? onChatNotification;

// void _handleMessage(Map<String, dynamic> data) {
//   final type = data['type'];
//   print('🔀 Routing message type: $type');
//   print('📊 Message data: $data');

//   switch (type) {
//     case 'ride_accepted':
//       print('   → ride_accepted handler');
//       if (onRideAccepted != null) onRideAccepted!(data);
//       break;
      
//     case 'ride_update':
//       print('   → ride_update handler');
//       if (onRideUpdate != null) onRideUpdate!(data);
//       break;
      
//     case 'chat':
//     case 'chat_message':
//       print('   → chat handler');
//       if (onChatMessage != null) {
//         onChatMessage!(data);
//       }
//       if (onChatNotification != null) {
//         onChatNotification!(data);
//       } else {
//         print('   ⚠️ No chat handler registered!');
//       }
//       break;
      
//     case 'driver_location':
//       print('   → driver_location handler');
//       if (onDriverLocation != null) onDriverLocation!(data);
//       break;
      
//     // CRITICAL: All call-related messages go to onIncomingCall
//     case 'call_initiate':
//     case 'call_answer':
//     case 'call_reject':
//     case 'call_end':
//     case 'call_offer':
//     case 'call_answer_sdp':
//     case 'call_ice_candidate':
//       print('   → 📞 CALL MESSAGE DETECTED: $type');
//       print('   → Checking if onIncomingCall handler exists: ${onIncomingCall != null}');
      
//       if (onIncomingCall != null) {
//         print('   → 📢 Calling onIncomingCall handler now...');
//         print('   → 📊 Call data being passed: $data');
//         onIncomingCall!(data);
//         print('   → ✅ onIncomingCall handler called successfully');
//       } else {
//         print('   → ❌❌❌ NO CALL HANDLER REGISTERED! ❌❌❌');
//         print('   → This is why incoming calls are not showing!');
//         print('   → Make sure to set _webSocketService.onIncomingCall before connecting');
//         print('   → Current handlers status:');
//         print('   →   - onIncomingCall: ${onIncomingCall != null}');
//         print('   →   - onRideAccepted: ${onRideAccepted != null}');
//         print('   →   - onChatMessage: ${onChatMessage != null}');
//       }
//       break;
      
//     case 'ride_completed':
//       print('   → ride_completed handler');
//       if (onRideCompleted != null) onRideCompleted!(data);
//       break;
      
//     case 'ride_request':
//     case 'new_ride':
//       print('   → ride_request handler');
//       if (onRideRequest != null) onRideRequest!(data);
//       break;
      
//     default:
//       print('   ⚠️ Unknown message type: $type');
//       print('   ⚠️ Full message: $data');
//   }
// }


//   void _reconnect() async {
//     final delay = _getReconnectDelay();
//     print('⏰ Reconnecting in ${delay}s... (attempt ${_reconnectAttempts}/${_maxReconnectAttempts})');
//     await Future.delayed(Duration(seconds: delay));

//     if (!_isConnected && !_isConnecting) {
//       connect();
//     }
//   }

//   int _getReconnectDelay() {
//     switch (_reconnectAttempts) {
//       case 1:
//         return 2;
//       case 2:
//         return 4;
//       case 3:
//         return 8;
//       default:
//         return 15;
//     }
//   }

//   // Send JSON with extensive logging
//   void _sendJson(Map<String, dynamic> message) {
//     print('');
//     print('═══════════════════════════════════════');
//     print('📤 ATTEMPTING TO SEND MESSAGE');
//     print('═══════════════════════════════════════');
//     print('Time: ${DateTime.now()}');
    
//     // Pre-flight checks
//     print('PRE-FLIGHT CHECKS:');
//     print('   _isConnected: $_isConnected');
//     print('   _isConnecting: $_isConnecting');
//     print('   _socket != null: ${_socket != null}');
    
//     if (_socket != null) {
//       print('   _socket.readyState: ${_socket!.readyState}');
//       print('   WebSocket.open: ${WebSocket.open}');
//       print('   States match: ${_socket!.readyState == WebSocket.open}');
//       print('   _socket.closeCode: ${_socket!.closeCode}');
//       print('   _socket.closeReason: ${_socket!.closeReason}');
//     }
    
//     print('');
//     print('MESSAGE PAYLOAD:');
//     print('   $message');
//     print('');

//     // Check 1: Socket exists
//     if (_socket == null) {
//       print('❌ SEND BLOCKED: Socket is null');
//       print('═══════════════════════════════════════');
//       print('');
//       return;
//     }

//     // Check 2: Marked as connected
//     if (!_isConnected) {
//       print('❌ SEND BLOCKED: Not marked as connected');
//       print('   Hint: Connection may still be initializing');
//       print('═══════════════════════════════════════');
//       print('');
//       return;
//     }

//     // Check 3: Socket is open
//     if (_socket!.readyState != WebSocket.open) {
//       print('❌ SEND BLOCKED: Socket not in OPEN state');
//       print('   Current state: ${_socket!.readyState}');
//       print('   Expected state: ${WebSocket.open}');
//       print('═══════════════════════════════════════');
//       print('');
      
//       // Try to reconnect if socket is closed
//       _isConnected = false;
//       _reconnect();
//       return;
//     }

//     // All checks passed, send the message
//     try {
//       final jsonMessage = jsonEncode(message);
//       print('SENDING:');
//       print('   JSON string: $jsonMessage');
//       print('   Length: ${jsonMessage.length} bytes');
//       print('');
      
//       _socket!.add(jsonMessage);
      
//       print('✅ MESSAGE SENT SUCCESSFULLY');
//       print('   Message added to socket send buffer');
//       print('   Socket state after send: ${_socket!.readyState}');
//       print('   Waiting for server response...');
//       print('═══════════════════════════════════════');
//       print('');
//     } catch (e, stackTrace) {
//       print('❌ SEND EXCEPTION: $e');
//       print('Stack trace:');
//       print('$stackTrace');
//       print('═══════════════════════════════════════');
//       print('');
      
//       // Mark as disconnected and try to reconnect
//       _isConnected = false;
//       _reconnect();
//     }
//   }

//   // Public send methods
//   void sendMessage(Map<String, dynamic> message) {
//     // Add timestamp if not present
//     // if (!message.containsKey('timestamp')) {
//     //   message['timestamp'] = DateTime.now().toIso8601String();
//     // }
//     _sendJson(message);
//   }
// Future<void> sendChatMessage(int rideId, String message) async {
//   print('💬 sendChatMessage called');
//   print('   Ride: $rideId');
//   print('   Message: "$message"');
  
//   // Get user info from SharedPreferences
//   final prefs = await SharedPreferences.getInstance();
//   final userId = prefs.getString('user_id');
//   final userName = prefs.getString('user_name') ?? 
//                    prefs.getString('name') ?? 
//                    'Unknown User';
  
//   print('   User ID: $userId');
//   print('   User Name: $userName');
  
//   // Create timestamp with timezone offset (mimicking Postman format)
//   final now = DateTime.now();
//   final offset = now.timeZoneOffset;
//   final offsetHours = offset.inHours;
//   final offsetMinutes = offset.inMinutes.remainder(60);
//   final offsetString = '${offsetHours >= 0 ? '+' : ''}${offsetHours.toString().padLeft(2, '0')}:${offsetMinutes.abs().toString().padLeft(2, '0')}';
//   final timestamp = '${now.toIso8601String()}$offsetString';
  
//   final payload = {
//     "type": "chat",
//     "data": {
//       "ride_id": rideId,  // ← Now uses actual ride ID
//       "message": message,  // ← Now uses actual message
//     },
//     "timestamp": timestamp,  // ← Proper timezone format
//   };
  
//   print('   Full payload: $payload');
//   print('   Timestamp format: $timestamp');
//   _sendJson(payload);
// }

//   void sendRideRequest(Map<String, dynamic> rideData) {
//     _sendJson({
//       'type': 'ride_request',
//       'data': rideData,
//       'timestamp': DateTime.now().toIso8601String(),
//     });
//   }

//   // Listeners
//   void listenToMessages(Function(dynamic) callback) {
//     onMessageReceived = callback;
//   }

//   void disconnect() {
//     print('🔌 Disconnecting WebSocket');
//     _socket?.close();
//     _socket = null;
//     _isConnected = false;
//     _isConnecting = false;
//     _reconnectAttempts = 0;
//     print('✅ WebSocket disconnected');
//   }

//   void resetConnection() {
//     print('🔄 Resetting connection');
//     disconnect();
//     _reconnectAttempts = 0;
//     connect();
//   }

//   Future<String?> _getToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString('auth_token');
//   }

//   void dispose() {
//     disconnect();
//   }
// }




import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/url_constants.dart';

//FOR DRIVER
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

  // List of listeners for incoming calls instead of single callback
  final List<Function(Map<String, dynamic>)> _incomingCallListeners = [];

  // Deprecated: use addIncomingCallListener
  set onIncomingCall(Function(Map<String, dynamic>)? callback) {
    if (callback != null) {
      addIncomingCallListener(callback);
    }
  }

  // Helper to maintain compatibility but it's not a true getter anymore
  Function(Map<String, dynamic>)? get onIncomingCall =>
      _incomingCallListeners.isNotEmpty ? _incomingCallListeners.last : null;

  void addIncomingCallListener(Function(Map<String, dynamic>) listener) {
    if (!_incomingCallListeners.contains(listener)) {
      _incomingCallListeners.add(listener);
      print(
        '✅ Added incoming call listener. Total listeners: ${_incomingCallListeners.length}',
      );
    }
  }

  void removeIncomingCallListener(Function(Map<String, dynamic>) listener) {
    _incomingCallListeners.remove(listener);
    print(
      '✅ Removed incoming call listener. Remaining listeners: ${_incomingCallListeners.length}',
    );
  }

  Function(Map<String, dynamic>)?
  onRideCompleted; // Callback for ride completion
  Function(Map<String, dynamic>)? onRideRequest;

  bool get isConnected => _isConnected;

  // Singleton pattern
  static WebSocketService get instance {
    _instance ??= WebSocketService._internal();
    return _instance!;
  }

  WebSocketService._internal() : token = null;
  Function(Map<String, dynamic>)? onChatNotification;

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
      _socket = await WebSocket.connect(uri.toString(), headers: headers);

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

  void _handleMessage(Map<String, dynamic> data) async {
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
        } else {
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
        // CRITICAL FIX: Filter call messages based on recipient
        await _handleCallMessage(data, type);
        break;
      case 'ride_completed':
        print('🎉 Ride completed message received: $data');
        if (onRideCompleted != null) {
          onRideCompleted!(data);
        } else {
          print('⚠️ No ride completed handler registered!');
        }
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

  // CRITICAL FIX: Filter call messages to ensure they go to the right recipient
  Future<void> _handleCallMessage(
    Map<String, dynamic> data,
    String type,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('user_id');

      print('═══════════════════════════════════════');
      print('🔍 CALL MESSAGE FILTERING');
      print('═══════════════════════════════════════');
      print('Message type: $type');
      print('Current user ID: $currentUserId');

      final messageData = data['data'];
      if (messageData != null) {
        final callerId = messageData['caller_id']?.toString();
        final recipientId = messageData['recipient_id']?.toString();

        print('Caller ID: $callerId');
        print('Recipient ID: $recipientId');

        // For call_initiate: only show to recipient (not the caller)
        if (type == 'call_initiate') {
          if (recipientId != null && recipientId == currentUserId) {
            print('✅ This user IS the recipient - showing incoming call');
            print(
              '🔍 onIncomingCall listeners count: ${_incomingCallListeners.length}',
            );
            if (_incomingCallListeners.isNotEmpty) {
              print(
                '📞 Notify all ${_incomingCallListeners.length} incoming call listeners...',
              );
              try {
                for (var listener in List.from(_incomingCallListeners)) {
                  try {
                    listener(data);
                  } catch (e) {
                    print('❌ Error in listener: $e');
                  }
                }
                print('✅ All listeners notified successfully');
              } catch (e, stack) {
                print('❌ Error calling listeners: $e');
                print('Stack: $stack');
              }
            } else {
              print('❌ No incoming call listeners registered!');
            }
          } else if (callerId == currentUserId) {
            print('⚠️ This user is the CALLER - ignoring call_initiate');
          } else {
            print('⚠️ This call is for someone else - ignoring');
          }
        }
        // For other call messages: route to the appropriate party
        else {
          // call_answer, call_reject, call_end should go to the caller
          if (type == 'call_answer' ||
              type == 'call_reject' ||
              type == 'call_end') {
            if (callerId == currentUserId) {
              print('✅ Routing $type to caller');
              for (var listener in List.from(_incomingCallListeners)) {
                try {
                  listener(data);
                } catch (e) {
                  print('❌ Error in listener: $e');
                }
              }
            } else {
              print('⚠️ This message is not for this user');
            }
          }
          // WebRTC signaling messages (offer, answer, ICE) should go to both parties
          else if (type == 'call_offer' ||
              type == 'call_answer_sdp' ||
              type == 'call_ice_candidate') {
            if (recipientId == currentUserId) {
              print('✅ Routing WebRTC message to recipient');
              for (var listener in List.from(_incomingCallListeners)) {
                try {
                  listener(data);
                } catch (e) {
                  print('❌ Error in listener: $e');
                }
              }
            } else {
              print('⚠️ WebRTC message not for this user');
            }
          }
        }
      } else {
        print('⚠️ No data field in call message');
        // Fallback: route to handler anyway
        print('⚠️ No data field in call message');
        // Fallback: route to listeners anyway
        for (var listener in List.from(_incomingCallListeners)) {
          try {
            listener(data);
          } catch (e) {
            print('❌ Error in listener: $e');
          }
        }
      }

      print('═══════════════════════════════════════');
    } catch (e) {
      print('❌ Error filtering call message: $e');
      // Fallback: route to handler anyway
      print('❌ Error filtering call message: $e');
      // Fallback: route to listeners anyway
      for (var listener in List.from(_incomingCallListeners)) {
        listener(data);
      }
    }
  }

  void _reconnect() async {
    final delay = _getReconnectDelay();
    print(
      '⏰ Reconnecting in ${delay}s... (attempt $_reconnectAttempts/$_maxReconnectAttempts)',
    );
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
    final userName =
        prefs.getString('user_name') ??
        prefs.getString('name') ??
        'Unknown User';

    print('   User ID: $userId');
    print('   User Name: $userName');

    // Create timestamp with timezone offset (mimicking Postman format)
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    final offsetHours = offset.inHours;
    final offsetMinutes = offset.inMinutes.remainder(60);
    final offsetString =
        '${offsetHours >= 0 ? '+' : ''}${offsetHours.toString().padLeft(2, '0')}:${offsetMinutes.abs().toString().padLeft(2, '0')}';
    final timestamp = '${now.toIso8601String()}$offsetString';

    final payload = {
      "type": "chat",
      "data": {
        "ride_id": rideId, // ← Now uses actual ride ID
        "message": message, // ← Now uses actual message
      },
      "timestamp": timestamp, // ← Proper timezone format
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

