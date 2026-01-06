import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:audioplayers/audioplayers.dart';

class ChatNotificationService {
  static OverlayEntry? _currentOverlay;
  static bool _isShowing = false;
  static final AudioPlayer _audioPlayer = AudioPlayer();

  // Show a chat message notification
  static void showChatNotification(
    BuildContext context, {
    required String senderName,
    required String message,
    String? senderImage,
    required VoidCallback onTap,
    Duration duration = const Duration(seconds: 4),
    bool playSound = true,
  }) {
    // Don't show if already showing
    if (_isShowing) {
      hide();
    }

    _isShowing = true;

    // Play notification sound
    if (playSound) {
      _playNotificationSound();
    }

    final overlay = Overlay.of(context);
    _currentOverlay = OverlayEntry(
      builder: (context) => _ChatNotificationWidget(
        senderName: senderName,
        message: message,
        senderImage: senderImage,
        onTap: () {
          hide();
          onTap();
        },
        onDismiss: hide,
      ),
    );

    overlay.insert(_currentOverlay!);

    // Auto-dismiss after duration
    Future.delayed(duration, () {
      hide();
    });
  }

  // Play notification sound
  static Future<void> _playNotificationSound() async {
    try {
      await _audioPlayer.stop(); // Stop any playing sound
      await _audioPlayer.play(AssetSource('sounds/messageAlert.mp3'));
    } catch (e) {
      print('Error playing notification sound: $e');
    }
  }

  // Hide the current notification
  static void hide() {
    if (_currentOverlay != null) {
      _currentOverlay?.remove();
      _currentOverlay = null;
      _isShowing = false;
    }
  }
}

// Extension to add message to ChatProvider from notification
extension ChatNotificationHelper on BuildContext {
  void addMessageFromNotification(Map<String, dynamic> messageData) {
    // This will be called when notification arrives to ensure message is in provider
    // Implementation will be in the HomeScreen
  }
}

class _ChatNotificationWidget extends StatefulWidget {
  final String senderName;
  final String message;
  final String? senderImage;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _ChatNotificationWidget({
    required this.senderName,
    required this.message,
    required this.onTap,
    required this.onDismiss,
    this.senderImage,
  });

  @override
  State<_ChatNotificationWidget> createState() =>
      __ChatNotificationWidgetState();
}

class __ChatNotificationWidgetState extends State<_ChatNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: widget.onTap,
                  onVerticalDragEnd: (details) {
                    if (details.primaryVelocity! < 0) {
                      _dismiss();
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(12.w),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20.r,
                                backgroundColor: Color(ConstColors.mainColor),
                                backgroundImage: widget.senderImage != null
                                    ? NetworkImage(widget.senderImage!)
                                    : null,
                                child: widget.senderImage == null
                                    ? Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 20.sp,
                                      )
                                    : null,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            widget.senderName,
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(width: 4.w),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6.w,
                                            vertical: 2.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Color(ConstColors.mainColor),
                                            borderRadius: BorderRadius.circular(
                                              8.r,
                                            ),
                                          ),
                                          child: Text(
                                            'New',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      widget.message,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.grey[700],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Icon(
                                Icons.chat_bubble,
                                color: Color(ConstColors.mainColor),
                                size: 20.sp,
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 4.h,
                          right: 4.w,
                          child: GestureDetector(
                            onTap: _dismiss,
                            child: Container(
                              padding: EdgeInsets.all(4.w),
                              child: Icon(
                                Icons.close,
                                size: 16.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
