import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/colors.dart';
import '../constants/images.dart';
import '../models/ride_models.dart';
import '../services/websocket_service.dart';
import 'call_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatScreen extends StatefulWidget {
  final Driver driver;
  final String rideId;
  final String currentUserId;

  const ChatScreen({
    super.key,
    required this.driver,
    required this.rideId,
    required this.currentUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final WebSocketService _webSocketService = WebSocketService();
  List<ChatMessage> messages = [];

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() async {
    await _webSocketService.connect();
    _listenToMessages();
  }

  void _listenToMessages() {
    _webSocketService.onChatMessage = (chatMessage) {
      if (!chatMessage.isMe) {
        setState(() {
          messages.add(chatMessage);
        });
      }
    };
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              width: 353.w,
              height: 30.h,
              margin: EdgeInsets.only(top: 20.h, left: 20.w, right: 20.w),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.arrow_back,
                      size: 24.sp,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 15.w),
                  CircleAvatar(
                    radius: 15.r,
                    backgroundImage: widget.driver.profilePicture.isNotEmpty
                        ? NetworkImage(widget.driver.profilePicture)
                        : AssetImage(ConstImages.avatar) as ImageProvider,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      widget.driver.name,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w500,
                        height: 21 / 18,
                        letterSpacing: -0.32,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showCallOptionsSheet(),
                    child: Icon(Icons.call, size: 24.sp, color: Colors.black),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            Divider(thickness: 1, color: Colors.grey.shade300),

            // Chat Messages
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(20.w),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return _buildChatBubble(message);
                },
              ),
            ),

            // Message Input
            Container(
              margin: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      width: 324.w,
                      height: 50.h,
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Color(0xFFB1B1B1).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15.r),
                      ),
                      child: TextField(
                        controller: messageController,
                        decoration: InputDecoration(
                          hintText: 'Send message',
                          hintStyle: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Color(0xFFB1B1B1),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 15.h),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  GestureDetector(
                    onTap: () {
                      if (messageController.text.isNotEmpty) {
                        _sendMessage(messageController.text);
                      }
                    },
                    child: Container(
                      width: 21.w,
                      height: 21.h,
                      child: Icon(Icons.send, size: 21.sp, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(String text) {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: text,
      senderId: widget.currentUserId,
      senderType: 'user',
      timestamp: DateTime.now(),
      isMe: true,
    );

    setState(() {
      messages.add(message);
      messageController.clear();
    });

    // Send message via WebSocket
    _webSocketService.sendChatMessage(text, widget.rideId);
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildChatBubble(ChatMessage message) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 10.h,
          left: message.isMe ? 50.w : 0,
          right: message.isMe ? 0 : 50.w,
        ),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: message.isMe
              ? Color(ConstColors.mainColor)
              : Color(0xFFB1B1B1).withOpacity(0.5),
          borderRadius: BorderRadius.only(
            topLeft: message.isMe ? Radius.circular(5.r) : Radius.circular(0),
            topRight: message.isMe ? Radius.circular(0) : Radius.circular(5.r),
            bottomRight: Radius.circular(5.r),
            bottomLeft: Radius.circular(5.r),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: message.isMe ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 5.h),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 8.sp,
                fontWeight: FontWeight.w500,
                height: 1.0,
                letterSpacing: -0.32,
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCallOptionsSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 69.w,
              height: 5.h,
              margin: EdgeInsets.only(bottom: 20.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.5.r),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Call ${widget.driver.name}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Divider(thickness: 1, color: Colors.grey.shade300),
            ListTile(
              title: Text(
                'Call via app',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              trailing: Icon(Icons.phone, size: 24.sp, color: Colors.black),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CallScreen(driverName: widget.driver.name),
                  ),
                );
              },
            ),
            Divider(thickness: 1, color: Colors.grey.shade300),
            ListTile(
              title: Text(
                'Call via phone',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              trailing: Icon(Icons.phone, size: 24.sp, color: Colors.black),
              onTap: () async {
                Navigator.pop(context);
                final Uri phoneUri = Uri(
                  scheme: 'tel',
                  path: widget.driver.phoneNumber,
                );
                if (await canLaunchUrl(phoneUri)) {
                  await launchUrl(phoneUri);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
