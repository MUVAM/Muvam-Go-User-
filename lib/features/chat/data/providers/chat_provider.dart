// // import 'package:flutter/material.dart';
// // import '../models/chat_model.dart';
// // //FOR DRIVER"
// // class ChatProvider with ChangeNotifier {
// //   final Map<int, List<ChatMessageModel>> _messagesByRide = {};
// //   final Map<int, ChatModel> _chats = {};

// //   Map<int, ChatModel> get chats => _chats;

// //   List<ChatMessageModel> getMessagesForRide(int rideId) {
// //     return _messagesByRide[rideId] ?? [];
// //   }

// //   void addChat(ChatModel chat) {
// //     _chats[chat.rideId] = chat;
// //     notifyListeners();
// //   }

// //   void addMessage(int rideId, ChatMessageModel message) {
// //     if (!_messagesByRide.containsKey(rideId)) {
// //       _messagesByRide[rideId] = [];
// //     }
// //     _messagesByRide[rideId]!.insert(0, message);

// //     // Update last message in chat
// //     if (_chats.containsKey(rideId)) {
// //       _chats[rideId] = _chats[rideId]!.copyWith(
// //         lastMessage: message.message,
// //         lastMessageTime: message.timestamp,
// //       );
// //     }

// //     notifyListeners();
// //   }

// //   void setMessages(int rideId, List<ChatMessageModel> messages) {
// //     _messagesByRide[rideId] = messages;
// //     notifyListeners();
// //   }

// //   void clearMessages(int rideId) {
// //     _messagesByRide[rideId]?.clear();
// //     notifyListeners();
// //   }
// // }

// import 'package:flutter/material.dart';

// import '../models/chat_model.dart';

// //FOR DRIVER
// class ChatProvider with ChangeNotifier {
//   final Map<int, List<ChatMessageModel>> _messagesByRide = {};
//   final Map<int, ChatModel> _chats = {};
//   int? _activeRideId; // Track which ride's chat is currently open

//   Map<int, ChatModel> get chats => _chats;
//   int? get activeRideId => _activeRideId;

//   List<ChatMessageModel> getMessagesForRide(int rideId) {
//     return _messagesByRide[rideId] ?? [];
//   }

//   void setActiveRide(int? rideId) {
//     _activeRideId = rideId;
//     notifyListeners();
//   }

//   bool isChatScreenOpen(int rideId) {
//     return _activeRideId == rideId;
//   }

//   void addChat(ChatModel chat) {
//     _chats[chat.rideId] = chat;
//     notifyListeners();
//   }

//   void addMessage(int rideId, ChatMessageModel message) {
//     if (!_messagesByRide.containsKey(rideId)) {
//       _messagesByRide[rideId] = [];
//     }
//     _messagesByRide[rideId]!.insert(0, message);

//     // Update last message in chat
//     if (_chats.containsKey(rideId)) {
//       _chats[rideId] = _chats[rideId]!.copyWith(
//         lastMessage: message.message,
//         lastMessageTime: message.timestamp,
//       );
//     }

//     notifyListeners();
//   }

//   void setMessages(int rideId, List<ChatMessageModel> messages) {
//     _messagesByRide[rideId] = messages;
//     notifyListeners();
//   }

//   void clearMessages(int rideId) {
//     _messagesByRide[rideId]?.clear();
//     notifyListeners();
//   }
// }




















import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_model.dart';

//FOR DRIVER
class ChatProvider with ChangeNotifier {
  final Map<int, List<ChatMessageModel>> _messagesByRide = {};
  final Map<int, ChatModel> _chats = {};
  int? _activeRideId;
  static const String _storageKey = 'chat_messages';

  Map<int, ChatModel> get chats => _chats;
  int? get activeRideId => _activeRideId;

  List<ChatMessageModel> getMessagesForRide(int rideId) {
    return _messagesByRide[rideId] ?? [];
  }

  void setActiveRide(int? rideId) {
    _activeRideId = rideId;
    notifyListeners();
  }

  bool isChatScreenOpen(int rideId) {
    return _activeRideId == rideId;
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

    if (_chats.containsKey(rideId)) {
      _chats[rideId] = _chats[rideId]!.copyWith(
        lastMessage: message.message,
        lastMessageTime: message.timestamp,
      );
    }

    _saveMessages();
    notifyListeners();
  }

  void setMessages(int rideId, List<ChatMessageModel> messages) {
    _messagesByRide[rideId] = messages;
    notifyListeners();
  }

  void clearMessages(int rideId) {
    _messagesByRide[rideId]?.clear();
    _saveMessages();
    notifyListeners();
  }

  Future<void> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final String? messagesJson = prefs.getString(_storageKey);
    
    if (messagesJson != null) {
      final Map<String, dynamic> decoded = json.decode(messagesJson);
      _messagesByRide.clear();
      
      decoded.forEach((key, value) {
        final rideId = int.parse(key);
        final List<dynamic> messagesList = value;
        _messagesByRide[rideId] = messagesList
            .map((m) => ChatMessageModel.fromJson(m))
            .toList();
      });
      
      notifyListeners();
    }
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> toSave = {};
    
    _messagesByRide.forEach((rideId, messages) {
      toSave[rideId.toString()] = messages.map((m) => m.toJson()).toList();
    });
    
    await prefs.setString(_storageKey, json.encode(toSave));
  }
}




