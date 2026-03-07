import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/app_routes.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/core/services/firebase_config_service.dart';
import 'package:muvam/core/services/unified_notification_service.dart';
import 'package:muvam/core/services/websocket_service.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/chat/data/providers/chat_provider.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/chat_bubble.dart';

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
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _loadUserId();
    await _initializeWebSocket();
  }

  Future<void> _loadUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (mounted) {
        setState(() {
          currentUserId = userId;
          _userIdLoaded = true;
        });
      }
    } catch (e) {
      AppLogger.log('Error loading user ID: $e');
      if (mounted) setState(() => _userIdLoaded = true);
    }
  }

  Future<void> _initializeWebSocket() async {
    try {
      _webSocketService = WebSocketService.instance;
      if (!_webSocketService.isConnected) {
        await _webSocketService.connect();
      }
      if (mounted) {
        setState(() {
          isConnected = _webSocketService.isConnected;
          isLoading = false;
        });
      }
      context.read<ChatProvider>().setActiveRide(widget.rideId);
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
    context.read<ChatProvider>().setActiveRide(null);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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
    auth.AccessCredentials credentials = await auth
        .obtainAccessCredentialsViaServiceAccount(
          auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
          scopes,
          client,
        );
    client.close();
    return credentials.accessToken.data;
  }

  void _sendMessage() async {
    if (_isSendingMessage) return;
    if (!_userIdLoaded) return;
    if (!isConnected) {
      CustomFlushbar.showError(
        context: context,
        message: 'Not connected to chat',
      );
      return;
    }

    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    setState(() => _isSendingMessage = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userName =
          prefs.getString('user_name') ??
          prefs.getString('name') ??
          'Unknown User';

      _webSocketService.sendMessage({
        "type": 'chat',
        'data': {
          'ride_id': widget.rideId,
          'message': text,
          'sender_id': currentUserId,
          'sender_name': userName,
        },
      });

      try {
        await UnifiedNotificationService.sendChatNotification(
          receiverId: widget.driverId,
          senderName: userName,
          messageText: text,
          chatRoomId: widget.rideId.toString(),
        );
      } catch (e) {
        AppLogger.log('FCM notification error: $e');
      }
    } catch (e) {
      CustomFlushbar.showError(
        context: context,
        message: 'Failed to send message',
      );
    } finally {
      if (mounted) setState(() => _isSendingMessage = false);
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
            MuvamTexts.titleMedium18(
              context,
              text: 'Call ${widget.driverName}',
              isTextWidget: true,
              fontWeight: FontWeight.w600,
            ),
            SizedBox(height: 30.h),
            GestureDetector(
              onTap: () {
                context.pop();
                context.pushNamed(
                  AppRoutes.call.name,
                  extra: {
                    'driverName': widget.driverName,
                    'rideId': widget.rideId,
                    'sessionId': null,
                  },
                );
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 15.h),
                child: Row(
                  children: [
                    Icon(Icons.phone_android, size: 24.sp),
                    SizedBox(width: 15.w),
                    MuvamTexts.bodyLarge16(
                      context,
                      text: 'Call via app',
                      isTextWidget: true,
                      fontWeight: FontWeight.w500,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10.h),
            GestureDetector(
              onTap: () {
                context.pop();
                _makeCall();
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 15.h),
                child: Row(
                  children: [
                    Icon(Icons.phone, size: 24.sp),
                    SizedBox(width: 15.w),
                    MuvamTexts.bodyLarge16(
                      context,
                      text: 'Call via phone',
                      isTextWidget: true,
                      fontWeight: FontWeight.w500,
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
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
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
                    onTap: () => context.pop(),
                    child: Icon(
                      Icons.arrow_back,
                      size: 24.sp,
                      color: AppColors.kBlackColor,
                    ),
                  ),
                  SizedBox(width: 15.w),
                  CircleAvatar(
                    radius: 15.r,
                    backgroundImage:
                        widget.driverImage != null &&
                            widget.driverImage!.isNotEmpty
                        ? NetworkImage(widget.driverImage!) as ImageProvider
                        : AssetImage(ConstImages.avatar),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: MuvamTexts.titleMedium18(
                      context,
                      text: widget.driverName,
                      isTextWidget: true,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: _showCallDialog,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      child: Icon(
                        Icons.phone,
                        size: 24.sp,
                        color: AppColors.kBlackColor,
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
                    MuvamTexts.bodySmall12(
                      context,
                      text: 'Reconnecting...',
                      isTextWidget: true,
                      color: Colors.orange.shade900,
                    ),
                  ],
                ),
              ),
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.kMainColor,
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
                              child: MuvamTexts.bodyMedium14(
                                context,
                                text:
                                    "No messages yet. Start the conversation!",
                                isTextWidget: true,
                                color: Colors.grey,
                                center: true,
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
                        color: const Color(0xFFB1B1B1).withOpacity(0.2),
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
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: const Color(0xFFB1B1B1),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          color: AppColors.kBlackColor,
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
                          color: AppColors.kBlackColor,
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
