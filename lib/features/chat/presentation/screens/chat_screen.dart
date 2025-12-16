import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/services/websocket_service.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/chat/data/models/chat_model.dart';
import 'package:muvam/features/chat/data/providers/chat_provider.dart';
import 'package:muvam/features/home/data/models/ride_models.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/chat_bubble.dart';
import 'call_screen.dart';

// //FOR PASSENGER

// class ChatScreen extends StatefulWidget {
//   final int rideId;
//   final String driverName;
//   final String? driverImage;

//   const ChatScreen({
//     super.key,
//     required this.rideId,
//     required this.driverName,
//     this.driverImage,
//   });

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   late final WebSocketService _webSocketService;
//   bool isLoading = true;
//   bool isConnected = false;
//   String? currentUserId;
//   final ScrollController _scrollController = ScrollController();
//   final TextEditingController _messageController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _initializeWebSocket();
//   }

//   @override
//   void dispose() {
//     _webSocketService.onChatMessage = null;
//     _messageController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   void _initializeWebSocket() async {
//     try {
//       AppLogger.log('🔧 Initializing WebSocket for ChatScreen');
      
//       _webSocketService = WebSocketService.instance;
      
//       if (!_webSocketService.isConnected) {
//         AppLogger.log('📡 WebSocket not connected, connecting...');
//         await _webSocketService.connect();
//       } else {
//         AppLogger.log('✅ WebSocket already connected');
//       }

//       setState(() {
//         isConnected = _webSocketService.isConnected;
//         isLoading = false;
//       });

//       _webSocketService.onChatMessage = _handleIncomingMessage;

//       AppLogger.log('✅ ChatScreen WebSocket initialized for ride: ${widget.rideId}');
//     } catch (e) {
//       AppLogger.log('❌ ChatScreen WebSocket initialization error: $e');
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//           isConnected = false;
//         });
//         CustomFlushbar.showError(
//           context: context,
//           message: 'Failed to connect to chat',
//         );
//       }
//     }
//   }

//   void _handleIncomingMessage(ChatMessage chatMessage) {
//     try {
//       AppLogger.log('📨 ChatScreen received message: ${chatMessage.message}');

//       if (mounted) {
//         final message = ChatMessageModel(
          
//           message: chatMessage.message,
//           timestamp: chatMessage.timestamp.toString(),
//           rideId: widget.rideId,
//           userId: chatMessage.senderId,
          
//         );

//         context.read<ChatProvider>().addMessage(widget.rideId, message);
        
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (_scrollController.hasClients) {
//             _scrollController.animateTo(
//               0,
//               duration: Duration(milliseconds: 300),
//               curve: Curves.easeOut,
//             );
//           }
//         });
//       }
//     } catch (e) {
//       AppLogger.log('❌ Error processing message in ChatScreen: $e');
//     }
//   }

//   void _sendMessage() {
//     if (!isConnected) {
//       CustomFlushbar.showError(
//         context: context,
//         message: 'Not connected to chat',
//       );
//       return;
//     }

//     final text = _messageController.text.trim();
//     if (text.isEmpty) return;

//     try {
//       AppLogger.log('📤 Sending message: "$text" for ride: ${widget.rideId}');
      
//       _webSocketService.sendChatMessage(text, widget.rideId.toString());

//       final message = ChatMessageModel(
//         message: text,
//         timestamp: DateTime.now().toIso8601String(),
//         rideId: widget.rideId,
//         userId: currentUserId,
//       );

//       context.read<ChatProvider>().addMessage(widget.rideId, message);
//       _messageController.clear();
      
//       AppLogger.log('✅ Message sent and added to UI');
//     } catch (e) {
//       AppLogger.log('❌ Error sending message: $e');
//       CustomFlushbar.showError(
//         context: context,
//         message: 'Failed to send message',
//       );
//     }
//   }

//   String _extractTime(String timestamp) {
//     try {
//       final dt = DateTime.parse(timestamp);
//       return DateFormat('hh:mm a').format(dt);
//     } catch (e) {
//       return '';
//     }
//   }

//   void _showCallDialog() {
//     showModalBottomSheet(
//       context: context,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
//       ),
//       builder: (context) => Container(
//         padding: EdgeInsets.all(20.w),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 69.w,
//               height: 5.h,
//               margin: EdgeInsets.only(bottom: 20.h),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade300,
//                 borderRadius: BorderRadius.circular(2.5.r),
//               ),
//             ),
//             Text(
//               'Call ${widget.driverName}',
//               style: TextStyle(
//                 fontFamily: 'Inter',
//                 fontSize: 18.sp,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black,
//               ),
//             ),
//             SizedBox(height: 30.h),
//             GestureDetector(
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => CallScreen(
//                       driverName: widget.driverName,
//                       rideId: widget.rideId,
//                     ),
//                   ),
//                 );
//               },
//               child: Container(
//                 width: double.infinity,
//                 padding: EdgeInsets.symmetric(vertical: 15.h),
//                 child: Row(
//                   children: [
//                     Icon(Icons.phone_android, size: 24.sp),
//                     SizedBox(width: 15.w),
//                     Text(
//                       'Call via app',
//                       style: TextStyle(
//                         fontFamily: 'Inter',
//                         fontSize: 16.sp,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             SizedBox(height: 10.h),
//             GestureDetector(
//               onTap: () {
//                 Navigator.pop(context);
//                 _makeCall();
//               },
//               child: Container(
//                 width: double.infinity,
//                 padding: EdgeInsets.symmetric(vertical: 15.h),
//                 child: Row(
//                   children: [
//                     Icon(Icons.phone, size: 24.sp),
//                     SizedBox(width: 15.w),
//                     Text(
//                       'Call via phone',
//                       style: TextStyle(
//                         fontFamily: 'Inter',
//                         fontSize: 16.sp,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             SizedBox(height: 20.h),
//           ],
//         ),
//       ),
//     );
//   }

//   void _makeCall() async {
//     const phoneNumber = '+1234567890';
//     final uri = Uri.parse('tel:$phoneNumber');
    
//     try {
//       if (await canLaunchUrl(uri)) {
//         await launchUrl(uri);
//         AppLogger.log('📞 Call initiated to: $phoneNumber', tag: 'CHAT');
//       } else {
//         CustomFlushbar.showError(
//           context: context,
//           message: 'Cannot make phone calls on this device',
//         );
//       }
//     } catch (e) {
//       AppLogger.error('Failed to make call', error: e, tag: 'CHAT');
//       CustomFlushbar.showError(
//         context: context,
//         message: 'Failed to make call',
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Column(
//           children: [
//             Container(
//               width: 353.w,
//               height: 30.h,
//               margin: EdgeInsets.only(top: 20.h, left: 20.w, right: 20.w),
//               child: Row(
//                 children: [
//                   GestureDetector(
//                     onTap: () => Navigator.pop(context),
//                     child: Icon(
//                       Icons.arrow_back,
//                       size: 24.sp,
//                       color: Colors.black,
//                     ),
//                   ),
//                   SizedBox(width: 15.w),
//                   CircleAvatar(
//                     radius: 15.r,
//                     backgroundImage:
//                         widget.driverImage != null &&
//                             widget.driverImage!.isNotEmpty
//                         ? NetworkImage(widget.driverImage!)
//                         : AssetImage(ConstImages.avatar) as ImageProvider,
//                   ),
//                   SizedBox(width: 10.w),
//                   Expanded(
//                     child: Text(
//                       widget.driverName,
//                       style: TextStyle(
//                         fontFamily: 'Inter',
//                         fontSize: 18.sp,
//                         fontWeight: FontWeight.w500,
//                         height: 21 / 18,
//                         letterSpacing: -0.32,
//                         color: Colors.black,
//                       ),
//                     ),
//                   ),
                  
//                   GestureDetector(
//                     onTap: () {
//                       AppLogger.log('📞 Call button tapped for driver: ${widget.driverName}', tag: 'CHAT');
//                       _showCallDialog();
//                     },
//                     child: Container(
//                       padding: EdgeInsets.all(4.w),
//                       child: Icon(
//                         Icons.phone,
//                         size: 24.sp,
//                         color: Colors.black,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 10.h),
//             Divider(thickness: 1, color: Colors.grey.shade300),
//             Expanded(
//               child: isLoading
//                   ? Center(
//                       child: CircularProgressIndicator(
//                         color: Color(ConstColors.mainColor),
//                       ),
//                     )
//                   : Consumer<ChatProvider>(
//                       builder: (context, provider, child) {
//                         final messages = provider.getMessagesForRide(
//                           widget.rideId,
//                         );

//                         if (messages.isEmpty) {
//                           return Center(
//                             child: Padding(
//                               padding: EdgeInsets.all(20.w),
//                               child: Text(
//                                 "No messages yet. Start the conversation!",
//                                 style: TextStyle(
//                                   fontFamily: 'Inter',
//                                   fontSize: 14.sp,
//                                   color: Colors.grey,
//                                 ),
//                                 textAlign: TextAlign.center,
//                               ),
//                             ),
//                           );
//                         }

//                         return ListView.builder(
//                           padding: EdgeInsets.all(20.w),
//                           reverse: true,
//                           itemCount: messages.length,
//                           controller: _scrollController,
//                           itemBuilder: (context, index) {
//                             final message = messages[index];
//                             final isMe =
//                                 message.userId == currentUserId ||
//                                 message.userId == null;
//                             final time = _extractTime(message.timestamp);

//                             return ChatBubble(
//                               text: message.message,
//                               isMe: isMe,
//                               time: time,
//                             );
//                           },
//                         );
//                       },
//                     ),
//             ),
//             Container(
//               margin: EdgeInsets.all(20.w),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Container(
//                       width: 324.w,
//                       height: 50.h,
//                       padding: EdgeInsets.all(10.w),
//                       decoration: BoxDecoration(
//                         color: Color(0xFFB1B1B1).withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(15.r),
//                       ),
//                       child: TextField(
//                         controller: _messageController,
//                         decoration: InputDecoration(
//                           hintText: 'Send message',
//                           hintStyle: TextStyle(
//                             fontFamily: 'Inter',
//                             fontSize: 12.sp,
//                             fontWeight: FontWeight.w500,
//                             height: 1.0,
//                             letterSpacing: -0.32,
//                             color: Color(0xFFB1B1B1),
//                           ),
//                           border: InputBorder.none,
//                           contentPadding: EdgeInsets.symmetric(vertical: 15.h),
//                         ),
//                         onSubmitted: (_) => _sendMessage(),
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: 10.w),
//                   GestureDetector(
//                     onTap: isConnected ? _sendMessage : null,
//                     child: Opacity(
//                       opacity: isConnected ? 1.0 : 0.4,
//                       child: Container(
//                         width: 21.w,
//                         height: 21.h,
//                         child: Icon(
//                           Icons.send,
//                           size: 21.sp,
//                           color: Colors.black,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }










// FOR PASSENGER - FIXED VERSION
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
  late final WebSocketService _webSocketService;
  bool isLoading = true;
  bool isConnected = false;
  String? currentUserId;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserId(); // ADDED: Load user ID first
    _initializeWebSocket();
  }

  @override
  void dispose() {
    _webSocketService.onChatMessage = null;
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ADDED: Load current user ID
  void _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getString('user_id');
    });
    AppLogger.log('📱 Current User ID: $currentUserId');
  }

  void _initializeWebSocket() async {
    try {
      AppLogger.log('🔧 Initializing WebSocket for ChatScreen');
      
      _webSocketService = WebSocketService.instance;
      
      if (!_webSocketService.isConnected) {
        AppLogger.log('📡 WebSocket not connected, connecting...');
        await _webSocketService.connect();
      } else {
        AppLogger.log('✅ WebSocket already connected');
      }

      setState(() {
        isConnected = _webSocketService.isConnected;
        isLoading = false;
      });

      // FIXED: Register handler that accepts Map<String, dynamic>
      _webSocketService.onChatMessage = _handleIncomingMessage;

      AppLogger.log('✅ ChatScreen WebSocket initialized for ride: ${widget.rideId}');
    } catch (e) {
      AppLogger.log('❌ ChatScreen WebSocket initialization error: $e');
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

  // FIXED: Accept Map<String, dynamic> instead of ChatMessage
  void _handleIncomingMessage(Map<String, dynamic> data) {
    try {
      AppLogger.log('📨 ChatScreen received message: $data');

      // Extract message data from the nested structure
      final messageData = data['data'] as Map<String, dynamic>?;
      if (messageData == null) {
        AppLogger.log('⚠️ No data field in message');
        return;
      }

      final rideId = messageData['ride_id'];
      
      // Only process messages for current ride
      if (rideId != widget.rideId) {
        AppLogger.log('⚠️ Message for different ride ($rideId vs ${widget.rideId})');
        return;
      }

      if (mounted) {
        final message = ChatMessageModel(
          message: messageData['message'] ?? '',
          timestamp: data['timestamp'] ?? DateTime.now().toIso8601String(),
          rideId: widget.rideId,
          userId: messageData['sender_id']?.toString() ?? messageData['user_id']?.toString(),
        );

        AppLogger.log('✅ Adding message to provider: "${message.message}"');
        context.read<ChatProvider>().addMessage(widget.rideId, message);
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      AppLogger.log('❌ Error processing message in ChatScreen: $e');
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
      AppLogger.log('📤 Sending message: "$text" for ride: ${widget.rideId}');
      
      // FIXED: Use correct format with nested data object
      _webSocketService.sendMessage({
        'type': 'chat',
        'data': {
          'ride_id': widget.rideId,
          'message': text,
        },
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Add message locally for immediate UI update
      final message = ChatMessageModel(
        message: text,
        timestamp: DateTime.now().toIso8601String(),
        rideId: widget.rideId,
        userId: currentUserId,
      );

      context.read<ChatProvider>().addMessage(widget.rideId, message);
      _messageController.clear();
      
      AppLogger.log('✅ Message sent and added to UI');
    } catch (e) {
      AppLogger.log('❌ Error sending message: $e');
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
    const phoneNumber = '+1234567890';
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



