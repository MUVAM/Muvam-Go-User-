import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/services/firebase_config_service.dart';
import 'package:muvam/core/services/unified_notification_service.dart';
import 'package:muvam/core/services/websocket_service.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/chat/data/providers/chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/chat_bubble.dart';
import 'call_screen.dart';

class ChatScreen extends StatefulWidget {
  final int rideId;
  final String driverName;
  final String? driverImage;
  final String driverId;
  final String? driverPhone;
  const ChatScreen({
    super.key,
    required this.rideId,
    required this.driverName,
    this.driverImage,
    required this.driverId,
    this.driverPhone,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final WebSocketService _webSocketService;
  bool isLoading = true;
  bool isConnected = false;
  String? currentUserId;
  bool _userIdLoaded = false;
  bool _isSendingMessage = false;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    AppLogger.log('ChatScreen initState - Ride ID: ${widget.rideId}');
    AppLogger.log('PHONE NUMBER ${widget.driverPhone}');

    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _loadUserId();
    await _initializeWebSocket();
  }

  Future<void> _loadUserId() async {
    AppLogger.log('Loading user ID...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      AppLogger.log('User ID: $userId');
      AppLogger.log('Passenger ID: ${widget.driverId}');

      if (mounted) {
        setState(() {
          currentUserId = userId;
          _userIdLoaded = true;
        });
      }
    } catch (e) {
      AppLogger.log('Error loading user ID: $e');
      if (mounted) {
        setState(() {
          _userIdLoaded = true;
        });
      }
    }
  }

  Future<void> _initializeWebSocket() async {
    try {
      AppLogger.log('Initializing ChatScreen WebSocket');

      _webSocketService = WebSocketService.instance;

      if (!_webSocketService.isConnected) {
        AppLogger.log('Connecting...');
        await _webSocketService.connect();
      } else {
        AppLogger.log('Already connected');
      }

      if (mounted) {
        setState(() {
          isConnected = _webSocketService.isConnected;
          isLoading = false;
        });
      }

      // Set this chat as active when screen opens
      context.read<ChatProvider>().setActiveRide(widget.rideId);
      AppLogger.log('Chat screen marked as active for ride ${widget.rideId}');

      AppLogger.log('WebSocket initialized for ChatScreen');
    } catch (e) {
      AppLogger.log('WebSocket initialization error: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          isConnected = false;
        });
      }
    }
  }

  @override
  void dispose() {
    AppLogger.log('ChatScreen dispose');
    // Mark chat as inactive when screen closes
    context.read<ChatProvider>().setActiveRide(null);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // void _handleIncomingMessage(Map<String, dynamic> data) {
  //   try {
  //     AppLogger.log('Chat message handler called');
  //     AppLogger.log('   Data: $data');

  //     final messageData = data['data'] as Map<String, dynamic>?;
  //     if (messageData == null) {
  //       AppLogger.log('No data field');
  //       return;
  //     }

  //     final messageRideId = messageData['ride_id'] ?? data['ride_id'];
  //     AppLogger.log(
  //       '   Message ride: $messageRideId, Current ride: ${widget.rideId}',
  //     );

  //     if (messageRideId != widget.rideId) {
  //       AppLogger.log('Different ride, ignoring');
  //       return;
  //     }

  //     final messageText = messageData['message'] ?? '';
  //     final senderId =
  //         messageData['sender_id']?.toString() ??
  //         data['user_id']?.toString() ??
  //         '';
  //     final timestamp = data['timestamp'] ?? DateTime.now().toIso8601String();

  //     AppLogger.log('Adding message: "$messageText"');
  //     AppLogger.log('   From: $senderId (Current user: $currentUserId)');

  //     if (mounted) {
  //       final message = ChatMessageModel(
  //         message: messageText,
  //         timestamp: timestamp,
  //         rideId: widget.rideId,
  //         userId: senderId,
  //       );

  //       context.read<ChatProvider>().addMessage(widget.rideId, message);

  //       // Auto-scroll
  //       WidgetsBinding.instance.addPostFrameCallback((_) {
  //         if (_scrollController.hasClients) {
  //           _scrollController.animateTo(
  //             0,
  //             duration: Duration(milliseconds: 300),
  //             curve: Curves.easeOut,
  //           );
  //         }
  //       });
  //     }
  //   } catch (e) {
  //     AppLogger.log('Error handling message: $e');
  //   }
  // }

  Future<String> getAccessToken() async {
    final serviceAccountJson =
        await FirebaseConfigService.getServiceAccountConfig();
    List<String> scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging",
    ];
    http.Client client = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
    );
    // get access token using this client
    auth.AccessCredentials credentials = await auth
        .obtainAccessCredentialsViaServiceAccount(
          auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
          scopes,
          client,
        );
    // close the client
    client.close();
    return credentials.accessToken.data;
  }

  void _sendMessage() async {
    AppLogger.log('');
    AppLogger.log('SEND MESSAGE INITIATED');

    // Prevent duplicate sends
    if (_isSendingMessage) {
      AppLogger.log('Already sending a message, ignoring duplicate tap');
      AppLogger.log('');
      return;
    }

    if (!_userIdLoaded) {
      AppLogger.log('User ID not loaded');
      AppLogger.log('');
      return;
    }

    if (!isConnected) {
      AppLogger.log('Not connected');
      AppLogger.log('');
      CustomFlushbar.showError(
        context: context,
        message: 'Not connected to chat',
      );
      return;
    }

    // Get the text BEFORE clearing to avoid empty message
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      AppLogger.log('Empty message');
      AppLogger.log('');
      return;
    }

    // Clear the text field IMMEDIATELY to prevent duplicate sends
    _messageController.clear();

    // Set flag to prevent duplicate sends
    setState(() {
      _isSendingMessage = true;
    });

    try {
      AppLogger.log('Message: "$text"');
      AppLogger.log('Ride ID: ${widget.rideId}');
      AppLogger.log('User ID: $currentUserId');
      AppLogger.log('Time: ${DateTime.now().toIso8601String()}');

      // Get user name from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userName =
          prefs.getString('user_name') ??
          prefs.getString('name') ??
          'Unknown User';

      AppLogger.log('User Name: $userName');

      // Send with sender_id and sender_name in data object
      _webSocketService.sendMessage({
        "type": 'chat',
        'data': {
          'ride_id': widget.rideId,
          'message': text,
          'sender_id': currentUserId,
          'sender_name': userName,
        },
      });

      AppLogger.log('Passed to WebSocket service');

      // Send FCM notification to driver
      AppLogger.log('Sending FCM notification to driver...');
      try {
        await UnifiedNotificationService.sendChatNotification(
          receiverId: widget.driverId,
          senderName: userName,
          messageText: text,
          chatRoomId: widget.rideId.toString(),
        );

        AppLogger.log('FCM: Driver ID needed to send notification');
      } catch (e) {
        AppLogger.log('FCM notification error: $e');
      }

      AppLogger.log('Waiting for server response...');
    } catch (e, stack) {
      AppLogger.log('Exception: $e');
      AppLogger.log('Stack: $stack');
      CustomFlushbar.showError(
        context: context,
        message: 'Failed to send message',
      );
    } finally {
      // Reset the flag after sending (or if error occurred)
      if (mounted) {
        setState(() {
          _isSendingMessage = false;
        });
      }
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
    final uri = Uri.parse('tel:${widget.driverPhone}');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        CustomFlushbar.showError(
          context: context,
          message: 'Cannot make phone calls on this device',
        );
      }
    } catch (e) {
      AppLogger.log('Call error: $e');
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
                    onTap: _showCallDialog,
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

            if (!isConnected && !isLoading)
              Container(
                color: Colors.orange.shade100,
                padding: EdgeInsets.all(8.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sync_problem, color: Colors.orange, size: 16.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'Reconnecting...',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),

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
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight: 50.h,
                        maxHeight: 120.h,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 15.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFFB1B1B1).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15.r),
                      ),
                      child: TextField(
                        controller: _messageController,
                        maxLines: null,
                        minLines: 1,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
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
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  GestureDetector(
                    onTap: isConnected && _userIdLoaded ? _sendMessage : null,
                    child: Opacity(
                      opacity: isConnected && _userIdLoaded ? 1.0 : 0.4,
                      child: Container(
                        width: 21.w,
                        height: 21.h,
                        margin: EdgeInsets.only(bottom: 15.h),
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
