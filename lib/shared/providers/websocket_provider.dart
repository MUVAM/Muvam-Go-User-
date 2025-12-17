import 'package:flutter/material.dart';
import 'package:muvam/core/services/websocket_service.dart';

class WebSocketProvider with ChangeNotifier {
  // final WebSocketService _webSocketService = WebSocketService.;
final WebSocketService _webSocketService = WebSocketService.instance;

  bool get isConnected => _webSocketService.isConnected;

  Future<void> connect() async {
    await _webSocketService.connect();
    notifyListeners();
  }

  // void sendChatMessage(String message, String rideId) {
  //   _webSocketService.sendChatMessage(message, rideId);
  // }

  void sendMessage(Map<String, dynamic> message) {
    _webSocketService.sendMessage(message);
  }

  // void sendRideRequest(Map<String, dynamic> rideData) {
  //   _webSocketService.sendRideRequest(rideData);
  // }

  void disconnect() {
    _webSocketService.disconnect();
    notifyListeners();
  }
}
