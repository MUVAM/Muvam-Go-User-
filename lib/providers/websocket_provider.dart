import 'package:flutter/material.dart';
import '../services/websocket_service.dart';

class WebSocketProvider with ChangeNotifier {
  final WebSocketService _webSocketService = WebSocketService();
  
  bool get isConnected => _webSocketService.isConnected;

  Future<void> connect() async {
    await _webSocketService.connect();
    notifyListeners();
  }

  void sendChatMessage(String message, String rideId) {
    _webSocketService.sendChatMessage(message, rideId);
  }

  void sendMessage(Map<String, dynamic> message) {
    _webSocketService.sendMessage(message);
  }

  void disconnect() {
    _webSocketService.disconnect();
    notifyListeners();
  }
}