import 'package:flutter/material.dart';
import '../models/chat_model.dart';

class ChatProvider with ChangeNotifier {
  final Map<int, List<ChatMessageModel>> _messagesByRide = {};
  final Map<int, ChatModel> _chats = {};

  Map<int, ChatModel> get chats => _chats;

  List<ChatMessageModel> getMessagesForRide(int rideId) {
    return _messagesByRide[rideId] ?? [];
  }

  void addChat(ChatModel chat) {
    _chats[chat.rideId] = chat;
    notifyListeners();
  }

  void addMessage(int rideId, ChatMessageModel message) {
    if (!_messagesByRide.containsKey(rideId)) {
      _messagesByRide[rideId] = [];
    }
    _messagesByRide[rideId]!.insert(0, message);

    // Update last message in chat
    if (_chats.containsKey(rideId)) {
      _chats[rideId] = _chats[rideId]!.copyWith(
        lastMessage: message.message,
        lastMessageTime: message.timestamp,
      );
    }

    notifyListeners();
  }

  void setMessages(int rideId, List<ChatMessageModel> messages) {
    _messagesByRide[rideId] = messages;
    notifyListeners();
  }

  void clearMessages(int rideId) {
    _messagesByRide[rideId]?.clear();
    notifyListeners();
  }
}
