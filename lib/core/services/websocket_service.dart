import 'dart:convert';
import 'dart:io';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/url_constants.dart';

class WebSocketService {
  static WebSocketService? _instance;
  WebSocket? _socket;
  final String? token;
  bool _isConnected = false;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  // Callbacks for different message types
  Function(dynamic)? onMessageReceived;
  Function(Map<String, dynamic>)? onRideAccepted;
  Function(Map<String, dynamic>)? onRideUpdate;
  Function(Map<String, dynamic>)? onChatMessage;
  Function(Map<String, dynamic>)? onDriverLocation;

  // List of listeners for incoming calls instead of single callback
  final List<Function(Map<String, dynamic>)> _incomingCallListeners = [];

  // Deprecated: use addIncomingCallListener
  set onIncomingCall(Function(Map<String, dynamic>)? callback) {
    if (callback != null) {
      addIncomingCallListener(callback);
    }
  }

  // Helper to maintain compatibility but it's not a true getter anymore
  Function(Map<String, dynamic>)? get onIncomingCall =>
      _incomingCallListeners.isNotEmpty ? _incomingCallListeners.last : null;

  void addIncomingCallListener(Function(Map<String, dynamic>) listener) {
    if (!_incomingCallListeners.contains(listener)) {
      _incomingCallListeners.add(listener);
      AppLogger.log(
        'Added incoming call listener. Total listeners: ${_incomingCallListeners.length}',
      );
    }
  }

  void removeIncomingCallListener(Function(Map<String, dynamic>) listener) {
    _incomingCallListeners.remove(listener);
    AppLogger.log(
      'Removed incoming call listener. Remaining listeners: ${_incomingCallListeners.length}',
    );
  }

  Function(Map<String, dynamic>)?
  onRideCompleted; // Callback for ride completion
  Function(Map<String, dynamic>)? onRideRequest;

  bool get isConnected => _isConnected;

  // Singleton pattern
  static WebSocketService get instance {
    _instance ??= WebSocketService._internal();
    return _instance!;
  }

  WebSocketService._internal() : token = null;
  Function(Map<String, dynamic>)? onChatNotification;

  Future<void> connect() async {
    AppLogger.log('NATIVE WEBSOCKET CONNECT');

    if (_isConnected) {
      AppLogger.log('Already connected');
      return;
    }

    if (_isConnecting) {
      AppLogger.log('Connection in progress');
      return;
    }

    _isConnecting = true;

    try {
      // Get token from storage
      final authToken = await _getToken();
      if (authToken == null) {
        AppLogger.log('No auth token found');
        _isConnecting = false;
        return;
      }

      AppLogger.log('NATIVE WEBSOCKET CONNECTION');
      AppLogger.log('URL: ${UrlConstants.wsUrl}');
      AppLogger.log('Token: ${authToken.substring(0, 20)}...');
      AppLogger.log('Time: ${DateTime.now()}');

      // Parse URL
      final uri = Uri.parse(UrlConstants.wsUrl);

      // Headers - Try lowercase 'authorization' to match Postman exactly
      final headers = {'authorization': 'Bearer $authToken'};

      AppLogger.log('Headers:');
      headers.forEach((key, value) {
        AppLogger.log(
          ' headerss  $key: ${value.length > 50 ? "${value.substring(0, 50)}..." : value}',
        );
      });

      // Connect using native WebSocket
      AppLogger.log('Connecting...');
      _socket = await WebSocket.connect(uri.toString(), headers: headers);

      AppLogger.log('WebSocket connected!');
      AppLogger.log('ReadyState: ${_socket!.readyState}');

      // CRITICAL: Setup listeners IMMEDIATELY and SYNCHRONOUSLY
      AppLogger.log('Setting up listeners NOW...');
      _setupListenersSync();
      AppLogger.log('Listeners attached');

      // Small delay to let the connection stabilize
      AppLogger.log('Stabilizing connection...');
      await Future.delayed(Duration(milliseconds: 200));
      AppLogger.log('Connection stabilized');

      // NOW it's safe to mark as connected
      _reconnectAttempts = 0;
      _isConnecting = false;
      _isConnected = true;

      AppLogger.log('Native WebSocket FULLY ready');
    } catch (e, stack) {
      AppLogger.log('Connection error: $e');
      AppLogger.log('Stack: $stack');
      _isConnected = false;
      _isConnecting = false;
      _socket = null;
      _reconnectAttempts++;

      if (_reconnectAttempts <= _maxReconnectAttempts) {
        _reconnect();
      }
    }
  }

  // CRITICAL: Synchronous listener setup - no async gaps
  void _setupListenersSync() {
    if (_socket == null) {
      AppLogger.log('Cannot setup listeners - socket is null');
      return;
    }

    AppLogger.log('   Attaching onData handler...');
    AppLogger.log('   Attaching onDone handler...');
    AppLogger.log('   Attaching onError handler...');

    _socket!.listen(
      (event) {
        AppLogger.log('');
        AppLogger.log('MESSAGE RECEIVED');
        AppLogger.log('Time: ${DateTime.now()}');
        AppLogger.log('Event type: ${event.runtimeType}');
        AppLogger.log('Raw event: $event');

        try {
          // Handle both String and List<int> responses
          String messageStr;
          if (event is String) {
            messageStr = event;
          } else if (event is List<int>) {
            messageStr = utf8.decode(event);
          } else {
            messageStr = event.toString();
          }

          AppLogger.log('Decoded message: $messageStr');

          final data = jsonDecode(messageStr);
          AppLogger.log('Parsed JSON: $data');
          AppLogger.log('Message type: ${data['type']}');

          // Call general message callback
          if (onMessageReceived != null) {
            onMessageReceived!(data);
          }

          // Route to specific handlers
          _handleMessage(data);
        } catch (e, stack) {
          AppLogger.log('Message parse error: $e');
          AppLogger.log('Stack: $stack');
        }
      },
      onDone: () {
        AppLogger.log('');
        AppLogger.log('WebSocket connection CLOSED');
        AppLogger.log('Time: ${DateTime.now()}');
        AppLogger.log('Close code: ${_socket?.closeCode}');
        AppLogger.log('Close reason: ${_socket?.closeReason}');
        AppLogger.log('Was Connected: $_isConnected');
        AppLogger.log('Is Connecting: $_isConnecting');

        bool wasConnected = _isConnected;
        _isConnected = false;
        _isConnecting = false;

        // Only reconnect if we were actually connected (not during initial setup)
        if (wasConnected) {
          _reconnectAttempts++;
          if (_reconnectAttempts <= _maxReconnectAttempts) {
            _reconnect();
          }
        }
      },
      onError: (error) {
        AppLogger.log('');
        AppLogger.log('WebSocket ERROR');
        AppLogger.log('Time: ${DateTime.now()}');
        AppLogger.log('Error: $error');
        AppLogger.log('Error type: ${error.runtimeType}');

        _isConnected = false;
        _isConnecting = false;
      },
      cancelOnError: false,
    );

    AppLogger.log('   All handlers attached successfully');
  }

  void _handleMessage(Map<String, dynamic> data) async {
    final type = data['type'];
    AppLogger.log('Routing message type: $type');

    switch (type) {
      case 'ride_accepted':
        AppLogger.log('ride_accepted handler');
        if (onRideAccepted != null) onRideAccepted!(data);
        break;
      case 'ride_update':
        AppLogger.log('ride_update handler');
        if (onRideUpdate != null) onRideUpdate!(data);
        break;
      case 'chat':
      case 'chat_message':
        AppLogger.log('chat handler');
        if (onChatMessage != null) {
          onChatMessage!(data);
        } else {
          AppLogger.log('No chat handler registered!');
        }
        break;
      case 'driver_location':
        AppLogger.log('driver_location handler');
        if (onDriverLocation != null) onDriverLocation!(data);
        break;
      case 'call_initiate':
      case 'call_answer':
      case 'call_reject':
      case 'call_end':
      case 'call_offer':
      case 'call_answer_sdp':
      case 'call_ice_candidate':
        AppLogger.log('call handler');
        // CRITICAL FIX: Filter call messages based on recipient
        await _handleCallMessage(data, type);
        break;
      case 'ride_completed':
        AppLogger.log('Ride completed message received: $data');
        if (onRideCompleted != null) {
          onRideCompleted!(data);
        } else {
          AppLogger.log('No ride completed handler registered!');
        }
        break;
      case 'ride_request':
      case 'new_ride':
        AppLogger.log('ride_request handler');
        if (onRideRequest != null) onRideRequest!(data);
        break;
      default:
        AppLogger.log('Unknown message type: $type');
    }
  }

  // CRITICAL FIX: Filter call messages to ensure they go to the right recipient
  Future<void> _handleCallMessage(
    Map<String, dynamic> data,
    String type,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('user_id');

      AppLogger.log('CALL MESSAGE FILTERING');
      AppLogger.log('Message type: $type');
      AppLogger.log('Current user ID: $currentUserId');

      final messageData = data['data'];
      if (messageData != null) {
        final callerId = messageData['caller_id']?.toString();
        final recipientId = messageData['recipient_id']?.toString();

        AppLogger.log('Caller ID: $callerId');
        AppLogger.log('Recipient ID: $recipientId');

        // For call_initiate: only show to recipient (not the caller)
        if (type == 'call_initiate') {
          if (recipientId != null && recipientId == currentUserId) {
            AppLogger.log('This user IS the recipient - showing incoming call');
            AppLogger.log(
              'onIncomingCall listeners count: ${_incomingCallListeners.length}',
            );
            if (_incomingCallListeners.isNotEmpty) {
              AppLogger.log(
                'Notify all ${_incomingCallListeners.length} incoming call listeners...',
              );
              try {
                for (var listener in List.from(_incomingCallListeners)) {
                  try {
                    listener(data);
                  } catch (e) {
                    AppLogger.log('Error in listener: $e');
                  }
                }
                AppLogger.log('All listeners notified successfully');
              } catch (e, stack) {
                AppLogger.log('Error calling listeners: $e');
                AppLogger.log('Stack: $stack');
              }
            } else {
              AppLogger.log('No incoming call listeners registered!');
            }
          } else if (callerId == currentUserId) {
            AppLogger.log('This user is the CALLER - ignoring call_initiate');
          } else {
            AppLogger.log('This call is for someone else - ignoring');
          }
        }
        // For other call messages: route to the appropriate party
        else {
          // call_answer, call_reject, call_end should go to the caller
          if (type == 'call_answer' ||
              type == 'call_reject' ||
              type == 'call_end') {
            if (callerId == currentUserId) {
              AppLogger.log('Routing $type to caller');
              for (var listener in List.from(_incomingCallListeners)) {
                try {
                  listener(data);
                } catch (e) {
                  AppLogger.log('Error in listener: $e');
                }
              }
            } else {
              AppLogger.log('This message is not for this user');
            }
          }
          // WebRTC signaling messages (offer, answer, ICE) should go to both parties
          else if (type == 'call_offer' ||
              type == 'call_answer_sdp' ||
              type == 'call_ice_candidate') {
            if (recipientId == currentUserId) {
              AppLogger.log('Routing WebRTC message to recipient');
              for (var listener in List.from(_incomingCallListeners)) {
                try {
                  listener(data);
                } catch (e) {
                  AppLogger.log('Error in listener: $e');
                }
              }
            } else {
              AppLogger.log('WebRTC message not for this user');
            }
          }
        }
      } else {
        AppLogger.log('No data field in call message');
        // Fallback: route to listeners anyway
        for (var listener in List.from(_incomingCallListeners)) {
          try {
            listener(data);
          } catch (e) {
            AppLogger.log('Error in listener: $e');
          }
        }
      }
    } catch (e) {
      AppLogger.log('Error filtering call message: $e');
      // Fallback: route to listeners anyway
      for (var listener in List.from(_incomingCallListeners)) {
        listener(data);
      }
    }
  }

  void _reconnect() async {
    final delay = _getReconnectDelay();
    AppLogger.log(
      'Reconnecting in ${delay}s... (attempt $_reconnectAttempts/$_maxReconnectAttempts)',
    );
    await Future.delayed(Duration(seconds: delay));

    if (!_isConnected && !_isConnecting) {
      connect();
    }
  }

  int _getReconnectDelay() {
    switch (_reconnectAttempts) {
      case 1:
        return 2;
      case 2:
        return 4;
      case 3:
        return 8;
      default:
        return 15;
    }
  }

  // Send JSON with extensive logging
  void _sendJson(Map<String, dynamic> message) {
    AppLogger.log('');
    AppLogger.log('ATTEMPTING TO SEND MESSAGE');
    AppLogger.log('Time: ${DateTime.now()}');

    // Pre-flight checks
    AppLogger.log('PRE-FLIGHT CHECKS:');
    AppLogger.log('   _isConnected: $_isConnected');
    AppLogger.log('   _isConnecting: $_isConnecting');
    AppLogger.log('   _socket != null: ${_socket != null}');

    if (_socket != null) {
      AppLogger.log('   _socket.readyState: ${_socket!.readyState}');
      AppLogger.log('   WebSocket.open: ${WebSocket.open}');
      AppLogger.log(
        '   States match: ${_socket!.readyState == WebSocket.open}',
      );
      AppLogger.log('   _socket.closeCode: ${_socket!.closeCode}');
      AppLogger.log('   _socket.closeReason: ${_socket!.closeReason}');
    }

    AppLogger.log('');
    AppLogger.log('MESSAGE PAYLOAD:');
    AppLogger.log('   $message');

    // Check 1: Socket exists
    if (_socket == null) {
      AppLogger.log('SEND BLOCKED: Socket is null');
      return;
    }

    // Check 2: Marked as connected
    if (!_isConnected) {
      AppLogger.log('SEND BLOCKED: Not marked as connected');
      AppLogger.log('   Hint: Connection may still be initializing');
      return;
    }

    // Check 3: Socket is open
    if (_socket!.readyState != WebSocket.open) {
      AppLogger.log('SEND BLOCKED: Socket not in OPEN state');
      AppLogger.log('   Current state: ${_socket!.readyState}');
      AppLogger.log('   Expected state: ${WebSocket.open}');

      // Try to reconnect if socket is closed
      _isConnected = false;
      _reconnect();
      return;
    }

    // All checks passed, send the message
    try {
      final jsonMessage = jsonEncode(message);
      AppLogger.log('SENDING:');
      AppLogger.log('   JSON string: $jsonMessage');
      AppLogger.log('   Length: ${jsonMessage.length} bytes');

      _socket!.add(jsonMessage);

      AppLogger.log('MESSAGE SENT SUCCESSFULLY');
      AppLogger.log('   Message added to socket send buffer');
      AppLogger.log('   Socket state after send: ${_socket!.readyState}');
      AppLogger.log('   Waiting for server response...');
    } catch (e, stackTrace) {
      AppLogger.log('SEND EXCEPTION: $e');
      AppLogger.log('Stack trace:');
      AppLogger.log('$stackTrace');

      // Mark as disconnected and try to reconnect
      _isConnected = false;
      _reconnect();
    }
  }

  // Public send methods
  void sendMessage(Map<String, dynamic> message) {
    // Add timestamp if not present
    // if (!message.containsKey('timestamp')) {
    //   message['timestamp'] = DateTime.now().toIso8601String();
    // }
    _sendJson(message);
  }

  Future<void> sendChatMessage(int rideId, String message) async {
    AppLogger.log('sendChatMessage called');
    AppLogger.log('   Ride: $rideId');
    AppLogger.log('   Message: "$message"');

    // Get user info from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final userName =
        prefs.getString('user_name') ??
        prefs.getString('name') ??
        'Unknown User';

    AppLogger.log('   User ID: $userId');
    AppLogger.log('   User Name: $userName');

    // Create timestamp with timezone offset (mimicking Postman format)
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    final offsetHours = offset.inHours;
    final offsetMinutes = offset.inMinutes.remainder(60);
    final offsetString =
        '${offsetHours >= 0 ? '+' : ''}${offsetHours.toString().padLeft(2, '0')}:${offsetMinutes.abs().toString().padLeft(2, '0')}';
    final timestamp = '${now.toIso8601String()}$offsetString';

    final payload = {
      "type": "chat",
      "data": {
        "ride_id": rideId, // ← Now uses actual ride ID
        "message": message, // ← Now uses actual message
      },
      "timestamp": timestamp, // ← Proper timezone format
    };

    AppLogger.log('   Full payload: $payload');
    AppLogger.log('   Timestamp format: $timestamp');
    _sendJson(payload);
  }

  void sendRideRequest(Map<String, dynamic> rideData) {
    _sendJson({
      'type': 'ride_request',
      'data': rideData,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Listeners
  void listenToMessages(Function(dynamic) callback) {
    onMessageReceived = callback;
  }

  void disconnect() {
    AppLogger.log('Disconnecting WebSocket');
    _socket?.close();
    _socket = null;
    _isConnected = false;
    _isConnecting = false;
    _reconnectAttempts = 0;
    AppLogger.log('WebSocket disconnected');
  }

  void resetConnection() {
    AppLogger.log('Resetting connection');
    disconnect();
    _reconnectAttempts = 0;
    connect();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  void dispose() {
    disconnect();
  }
}
