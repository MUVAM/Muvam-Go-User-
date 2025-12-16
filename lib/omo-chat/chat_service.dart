// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:muvam/src/feature/messages/model/chat_model.dart';
// import '../../../core/storage/storage_manager.dart';

// class ChatService {
//   static const String _baseUrl = 'http://20.119.80.237';

//   static Future<List<ChatModel>> fetchChats() async {
//     final token = StorageManager.getAccessToken();

//     final response = await http.get(
//       Uri.parse('$_baseUrl/chat/'),
//       headers: {
//         'Authorization': 'Bearer $token',
//         'Content-Type': 'application/json',
//       },
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body)['data'] as List;
//       return data.map((item) => ChatModel.fromJson(item)).toList();
//     } else {
//       throw Exception('Failed to load chats. Status: ${response.statusCode}');
//     }
//   }

//   static Future<LastMessage?> getLatestMessageForRoom(String roomId) async {
//     try {
//       final chats = await fetchChats();
//       // Find the chat with matching roomId, if any
//       for (final chat in chats) {
//         if (chat.lastMessage != null && chat.lastMessage!.room == roomId) {
//           return chat.lastMessage;
//         }
//       }
//       return null;
//     } catch (e) {
//       print('Error getting latest message: $e');
//       return null;
//     }
//   }

//   static Future<bool?> blockOrReportUser({
//     required int userId,
//     required String type,
//   }) async {
//     final token = StorageManager.getAccessToken();

//     final response = await http.post(
//       Uri.parse('$_baseUrl/accounts/report_block/'),
//       headers: {
//         'Authorization': 'Bearer $token',
//         'Content-Type': 'application/json',
//       },
//       body: jsonEncode({
//         'type': type,
//         'user_id': userId,
//       }),
//     );

//     final data = jsonDecode(response.body);
//     if (response.statusCode == 200 && data['status'] == true) {
//       return null;
//     } else {
//       print('❌ Response body: ${response.body}');
//       throw Exception('Failed to $type user. Status: ${response.statusCode}');
//     }
//   }
// }
