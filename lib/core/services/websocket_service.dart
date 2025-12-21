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