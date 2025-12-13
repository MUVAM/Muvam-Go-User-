import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/services/socket_service.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/chat/data/models/chat_model.dart';
import 'package:muvam/features/chat/data/providers/chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../widgets/chat_bubble.dart';
import 'call_screen.dart';

class ChatScreen extends StatefulWidget {
  final int rideId;
  final String driverName;
  final String? driverImage;

  const ChatScreen({
    super.key,
    required this.rideId,
    required this.driverName,
    this.driverImage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final SocketService socketService;
  bool isLoading = true;
  bool isConnected = false;
  String? currentUserId;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeSocket();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    socketService.disconnect();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  void _initializeSocket() async {
    try {
      final token = await _getToken();
      if (token == null) {
        setState(() {
          isLoading = false;
        });
        CustomFlushbar.showError(
          context: context,
          message: 'Authentication token not found',
        );
        return;
      }

      socketService = SocketService(token);
      await socketService.connect();

      setState(() {
        isConnected = true;
        isLoading = false;
      });

      socketService.listenToMessages((data) {
        _handleIncomingMessage(data);
      });

      AppLogger.log('WebSocket initialized for ride: ${widget.rideId}');
    } catch (e) {
      AppLogger.log('Initialization error: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          isConnected = false;
        });
        CustomFlushbar.showError(
          context: context,
          message: 'Failed to connect to chat',
        );
      }
    }
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    try {
      AppLogger.log('Received data: $data');

      if (data['type'] == 'chat') {
        final messageData = data['data'] as Map<String, dynamic>;
        final rideId = messageData['ride_id'] as int?;

        // Only process messages for current ride
        if (rideId == widget.rideId) {
          final message = ChatMessageModel(
            message: messageData['message'] ?? '',
            timestamp: data['timestamp'] ?? DateTime.now().toIso8601String(),
            rideId: rideId,
            userId: messageData['user_id']?.toString(),
          );

          if (mounted) {
            context.read<ChatProvider>().addMessage(widget.rideId, message);
          }
        }
      }
    } catch (e) {
      AppLogger.log('Error processing message: $e');
    }
  }

  void _sendMessage() {
    if (!isConnected) {
      CustomFlushbar.showError(
        context: context,
        message: 'Not connected to chat',
      );
      return;
    }

    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      socketService.sendMessage(widget.rideId, text);

      // Add message locally for immediate UI update
      final message = ChatMessageModel(
        message: text,
        timestamp: DateTime.now().toIso8601String(),
        rideId: widget.rideId,
        userId: currentUserId,
      );

      context.read<ChatProvider>().addMessage(widget.rideId, message);
      _messageController.clear();
    } catch (e) {
      AppLogger.log('Error sending message: $e');
      CustomFlushbar.showError(
        context: context,
        message: 'Failed to send message',
      );
    }
  }

  String _extractTime(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      return DateFormat('hh:mm a').format(dt);
    } catch (e) {
      return '';
    }
  }

  void _showCallDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
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
            Text(
              'Call ${widget.driverName}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 30.h),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CallScreen(
                      driverName: widget.driverName,
                      rideId: widget.rideId,
                    ),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 15.h),
                child: Row(
                  children: [
                    Icon(Icons.phone_android, size: 24.sp),
                    SizedBox(width: 15.w),
                    Text(
                      'Call via app',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10.h),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _makeCall();
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 15.h),
                child: Row(
                  children: [
                    Icon(Icons.phone, size: 24.sp),
                    SizedBox(width: 15.w),
                    Text(
                      'Call via phone',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  void _makeCall() async {
    // Replace with actual driver phone number
    const phoneNumber = '+1234567890'; // This should come from driver data
    final uri = Uri.parse('tel:$phoneNumber');
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        AppLogger.log('📞 Call initiated to: $phoneNumber', tag: 'CHAT');
      } else {
        CustomFlushbar.showError(
          context: context,
          message: 'Cannot make phone calls on this device',
        );
      }
    } catch (e) {
      AppLogger.error('Failed to make call', error: e, tag: 'CHAT');
      CustomFlushbar.showError(
        context: context,
        message: 'Failed to make call',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
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
                    backgroundImage:
                        widget.driverImage != null &&
                            widget.driverImage!.isNotEmpty
                        ? NetworkImage(widget.driverImage!)
                        : AssetImage(ConstImages.avatar) as ImageProvider,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      widget.driverName,
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
                    onTap: () {
                      AppLogger.log('📞 Call button tapped for driver: ${widget.driverName}', tag: 'CHAT');
                      _showCallDialog();
                    },
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      child: Icon(
                        Icons.phone,
                        size: 24.sp,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            Divider(thickness: 1, color: Colors.grey.shade300),
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Color(ConstColors.mainColor),
                      ),
                    )
                  : Consumer<ChatProvider>(
                      builder: (context, provider, child) {
                        final messages = provider.getMessagesForRide(
                          widget.rideId,
                        );

                        if (messages.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.w),
                              child: Text(
                                "No messages yet. Start the conversation!",
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14.sp,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: EdgeInsets.all(20.w),
                          reverse: true,
                          itemCount: messages.length,
                          controller: _scrollController,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            // Determine if message is from current user
                            // You might need to compare with actual user ID
                            final isMe =
                                message.userId == currentUserId ||
                                message.userId == null;
                            final time = _extractTime(message.timestamp);

                            return ChatBubble(
                              text: message.message,
                              isMe: isMe,
                              time: time,
                            );
                          },
                        );
                      },
                    ),
            ),
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
                        controller: _messageController,
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
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  GestureDetector(
                    onTap: isConnected ? _sendMessage : null,
                    child: Opacity(
                      opacity: isConnected ? 1.0 : 0.4,
                      child: Container(
                        width: 21.w,
                        height: 21.h,
                        child: Icon(
                          Icons.send,
                          size: 21.sp,
                          color: Colors.black,
                        ),
                      ),
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
}
