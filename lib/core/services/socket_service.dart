import 'dart:convert';
import 'dart:io';

import 'package:muvam/core/utils/app_logger.dart';

class SocketService {
  WebSocket? _socket;
  final String token;
  Function(Map<String, dynamic>)? onMessageReceived;

  SocketService(this.token);

  Future<void> connect() async {
    try {
      final uri = Uri.parse('ws://44.222.121.219/api/v1/ws');
      final headers = {
        'Authorization': 'Bearer $token',
        'Origin': 'http://44.222.121.219',
      };
      _socket = await WebSocket.connect(uri.toString(), headers: headers);
      _setupListeners();
      AppLogger.log('WebSocket connected!');
    } catch (e) {
      AppLogger.log('WebSocket connection error: $e');
      rethrow;
    }
  }

  void _setupListeners() {
    _socket?.listen(
      (event) {
        try {
          final data = jsonDecode(event) as Map<String, dynamic>;
          if (onMessageReceived != null) {
            onMessageReceived!(data);
          }
        } catch (e) {
          AppLogger.log('Error parsing message: $e');
        }
      },
      onDone: () {
        AppLogger.log('WebSocket connection closed');
      },
      onError: (error) {
        AppLogger.log('WebSocket error: $error');
      },
    );
  }

  void listenToMessages(Function(Map<String, dynamic>) callback) {
    onMessageReceived = callback;
  }

  void sendMessage(int rideId, String message) {
    final payload = {
      'type': 'chat',
      'data': {'ride_id': rideId, 'message': message},
      'timestamp': DateTime.now().toIso8601String(),
    };

    final jsonMessage = jsonEncode(payload);
    _socket?.add(jsonMessage);
    AppLogger.log('Sent message: $jsonMessage');
  }

  void disconnect() {
    _socket?.close();
    AppLogger.log('WebSocket disconnected');
  }

  void dispose() {
    _socket?.close();
    AppLogger.log('WebSocket closed');
  }
}
