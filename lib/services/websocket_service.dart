import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/url_constants.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  
  bool get isConnected => _isConnected;

  Future<void> connect() async {
    try {
      final token = await _getToken();
      final wsUrl = 'ws://44.222.121.219/api/v1/ws?authorization=Bearer%20$token';
      
      print('=== WEBSOCKET CONNECTION ===');
      print('Token: Bearer $token');
      print('User Type: CUSTOMER');
      print('Connecting to: $wsUrl');
      print('Note: Using Bearer token in query param (Flutter limitation)');
      
      _channel = WebSocketChannel.connect(
        Uri.parse(wsUrl),
      );
      
      _isConnected = true;
      print('WebSocket connected successfully to: $wsUrl');
      
      // Send authentication as first message
      sendMessage({
        'type': 'auth',
        'token': 'Bearer $token',
      });
      print('Authentication message sent');
      
      // Listen for incoming messages
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          print('WebSocket error: $error');
          _isConnected = false;
        },
        onDone: () {
          print('WebSocket connection closed');
          _isConnected = false;
        },
      );
    } catch (e) {
      print('Failed to connect WebSocket: $e');
      _isConnected = false;
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final type = data['type'];
      
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
      }
    } catch (e) {
      print('Error parsing WebSocket message: $e');
    }
  }

  void _handleRideAccepted(Map<String, dynamic> data) {
    print('Ride accepted: $data');
    // Handle ride acceptance logic
  }

  void _handleRideUpdate(Map<String, dynamic> data) {
    print('Ride update: $data');
    // Handle ride status updates
  }

  void _handleChatMessage(Map<String, dynamic> data) {
    print('Chat message: $data');
    // Handle incoming chat messages
  }

  void _handleDriverLocation(Map<String, dynamic> data) {
    print('Driver location: $data');
    // Handle driver location updates
  }

  void sendMessage(Map<String, dynamic> message) {
    print('=== WEBSOCKET SEND ATTEMPT ===');
    print('Connected: $_isConnected');
    print('Channel: ${_channel != null}');
    print('Message: $message');
    
    if (_isConnected && _channel != null) {
      final jsonMessage = jsonEncode(message);
      print('Sending JSON: $jsonMessage');
      _channel!.sink.add(jsonMessage);
      print('Message sent to WebSocket successfully');
    } else {
      print('WebSocket not connected - cannot send message');
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

  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
      _isConnected = false;
      print('WebSocket disconnected');
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}