import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/url_constants.dart';
import '../models/ride_models.dart';
class WebSocketService {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  
  // Callbacks for different message types
  Function(Map<String, dynamic>)? onRideAccepted;
  Function(Map<String, dynamic>)? onRideUpdate;
  Function(ChatMessage)? onChatMessage;
  Function(Map<String, dynamic>)? onDriverLocation;
  
  bool get isConnected => _isConnected;

  Future<void> connect() async {
    print('🚀 WEBSOCKET CONNECT METHOD CALLED');
    
    if (_isConnected) {
      print('⚠️ WebSocket already connected, skipping...');
      return;
    }
    
    if (_isConnecting) {
      print('⚠️ Connection already in progress, skipping...');
      return;
    }
    
    _isConnecting = true;
    
    try {
      final token = await _getToken();
      print('🔍 Token check result: ${token != null ? 'Found' : 'Not found'}');
      if (token == null) {
        print('❌ No auth token found for WebSocket');
        return;
      }
      
      print('=== WEBSOCKET CONNECTION START ===');
      print('🔗 Connecting to: ${UrlConstants.wsUrl}');
      print('🔑 Using token: ${token.substring(0, 20)}...');
      print('⏰ Connection time: ${DateTime.now()}');
      print('🌐 Attempting WebSocket.connect...');
      
      final webSocket = await WebSocket.connect(
        UrlConstants.wsUrl,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      print('🔌 WebSocket.connect completed');
      _channel = IOWebSocketChannel(webSocket);
      _isConnected = true;
      print('✅ WebSocket connected successfully!');
      print('🎯 Ready to receive messages...');
      print('📊 Connection state: $_isConnected');
      print('📡 Channel created: ${_channel != null}');
      
      _channel!.stream.listen(
        (message) {
          print('📥 WebSocket message received at ${DateTime.now()}');
          _handleMessage(message);
        },
        onError: (error) {
          print('❌ WebSocket error: $error');
          _isConnected = false;
          _isConnecting = false;
          _reconnectAttempts++;
          if (_reconnectAttempts <= _maxReconnectAttempts) {
            _reconnect();
          }
        },
        onDone: () {
          print('🔌 WebSocket connection closed at ${DateTime.now()}');
          print('🔍 Close reason: Server closed connection');
          _isConnected = false;
          _isConnecting = false;
          _reconnectAttempts++;
          if (_reconnectAttempts <= _maxReconnectAttempts) {
            _reconnect();
          }
        },
      );
      
      print('✅ WebSocket listener setup complete');
      _reconnectAttempts = 0;
      _isConnecting = false;
      
      print('🎯 WebSocket ready - no automatic test message sent');
    } catch (e) {
      print('❌ Failed to connect WebSocket: $e');
      _isConnected = false;
      _isConnecting = false;
      _reconnectAttempts++;
      
      if (_reconnectAttempts <= _maxReconnectAttempts) {
        final delay = _getReconnectDelay();
        print('🔄 Will attempt reconnection #$_reconnectAttempts in ${delay}s...');
        _reconnect();
      } else {
        print('❌ Max reconnection attempts reached. Stopping reconnection.');
      }
    }
    print('=== WEBSOCKET CONNECTION END ===\n');
  }

  void _reconnect() async {
    final delay = _getReconnectDelay();
    await Future.delayed(Duration(seconds: delay));
    if (!_isConnected && !_isConnecting) {
      connect();
    }
  }
  
  int _getReconnectDelay() {
    switch (_reconnectAttempts) {
      case 1: return 3;
      case 2: return 6;
      case 3: return 12;
      case 4: return 24;
      default: return 60;
    }
  }

  void _handleMessage(dynamic message) {
    print('=== WEBSOCKET MESSAGE RECEIVED ===');
    print('📨 RAW MESSAGE: $message');
    print('📋 Message type: ${message.runtimeType}');
    print('📏 Message length: ${message.toString().length}');
    print('📄 FULL RAW MESSAGE CONTENT: ${message.toString()}');
    
    try {
      print('🔄 Attempting to parse JSON from raw message...');
      final data = jsonDecode(message);
      print('🔍 Parsed JSON: $data');
      print('🔍 JSON keys: ${data.keys.toList()}');
      final type = data['type'];
      print('🏷️ Message type from JSON: $type');
      
      switch (type) {
        case 'ride_accepted':
          _handleRideAccepted(data);
          break;
        case 'ride_update':
          _handleRideUpdate(data);
          break;
        case 'chat_message':
          _handleChatMessage(data);
          break;
        case 'driver_location':
          _handleDriverLocation(data);
          break;
        default:
          print('Unknown message type: $type');
          print('Full message data: $data');
      }
    } catch (e) {
      print('Error parsing WebSocket message: $e');
      print('Raw message that failed: $message');
    }
    print('=== END WEBSOCKET MESSAGE ===\n');
  }

  void _handleRideAccepted(Map<String, dynamic> data) {
    print('🚗 RIDE ACCEPTED MESSAGE:');
    print('   Data: $data');
    
    if (onRideAccepted != null) {
      onRideAccepted!(data);
    }
  }

  void _handleRideUpdate(Map<String, dynamic> data) {
    print('📱 RIDE UPDATE MESSAGE:');
    print('   Data: $data');
    
    if (onRideUpdate != null) {
      onRideUpdate!(data);
    }
  }

  void _handleChatMessage(Map<String, dynamic> data) async {
    print('💬 CHAT MESSAGE:');
    print('   Data: $data');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('user_id') ?? '';
      
      final chatMessage = ChatMessage.fromJson(data, currentUserId);
      if (onChatMessage != null) {
        onChatMessage!(chatMessage);
      }
    } catch (e) {
      print('Error handling chat message: $e');
    }
  }

  void _handleDriverLocation(Map<String, dynamic> data) {
    print('📍 DRIVER LOCATION MESSAGE:');
    print('   Data: $data');
    
    if (onDriverLocation != null) {
      onDriverLocation!(data);
    }
  }

  void sendMessage(Map<String, dynamic> message) {
    print('=== WEBSOCKET SEND DEBUG ===');
    print('Connected: $_isConnected');
    print('Channel exists: ${_channel != null}');
    print('Raw message: $message');
    
    if (!_isConnected || _channel == null) {
      print('❌ WebSocket not ready - forcing reconnect');
      _forceReconnectAndSend(message);
      return;
    }
    
    try {
      final jsonMessage = jsonEncode(message);
      print('📤 Sending exact JSON: $jsonMessage');
      print('📤 Message length: ${jsonMessage.length} chars');
      
      _channel!.sink.add(jsonMessage);
      print('✅ Message added to sink successfully');
      
      // Force flush
      if (_channel!.sink is IOSink) {
        (_channel!.sink as IOSink).flush();
        print('✅ Sink flushed');
      }
    } catch (e, stackTrace) {
      print('❌ Send failed: $e');
      print('❌ Stack: $stackTrace');
      _isConnected = false;
    }
  }
  
  void _forceReconnectAndSend(Map<String, dynamic> message) async {
    _isConnected = false;
    _channel = null;
    
    await connect();
    
    if (_isConnected && _channel != null) {
      final jsonMessage = jsonEncode(message);
      _channel!.sink.add(jsonMessage);
      print('✅ Message sent after forced reconnection');
    } else {
      print('❌ Forced reconnection failed');
    }
  }

  void sendChatMessage(String message, String rideId) {
    sendMessage({
      'type': 'chat_message',
      'message': message,
      'ride_id': rideId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void sendRideRequest(Map<String, dynamic> rideData) {
    sendMessage({
      'type': 'ride_request',
      'data': rideData,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
      _isConnected = false;
      _isConnecting = false;
      _reconnectAttempts = 0;
      print('WebSocket disconnected');
    }
  }
  
  void resetConnection() {
    print('🔄 Resetting WebSocket connection...');
    disconnect();
    _reconnectAttempts = 0;
    connect();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  void testConnection() {
    print('=== CONNECTION TEST ===');
    print('_isConnected: $_isConnected');
    print('_channel != null: ${_channel != null}');
    if (_channel != null) {
      print('Channel type: ${_channel.runtimeType}');
      print('Sink type: ${_channel!.sink.runtimeType}');
    }
    
    // Send a simple test message
    sendMessage({
      'type': 'test',
      'message': 'Connection test',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}