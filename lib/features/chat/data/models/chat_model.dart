class ChatMessageModel {
  final String message;
  final String timestamp;
  final int? rideId;
  final String? userId;

  ChatMessageModel({
    required this.message,
    required this.timestamp,
    this.rideId,
    this.userId,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      message: json['message'] ?? '',
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
      rideId: json['ride_id'],
      userId: json['user_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'timestamp': timestamp,
      if (rideId != null) 'ride_id': rideId,
    };
  }
}

class ChatModel {
  final int rideId;
  final String driverName;
  final String? driverImage;
  final String? lastMessage;
  final String? lastMessageTime;

  ChatModel({
    required this.rideId,
    required this.driverName,
    this.driverImage,
    this.lastMessage,
    this.lastMessageTime,
  });

  ChatModel copyWith({
    int? rideId,
    String? driverName,
    String? driverImage,
    String? lastMessage,
    String? lastMessageTime,
  }) {
    return ChatModel(
      rideId: rideId ?? this.rideId,
      driverName: driverName ?? this.driverName,
      driverImage: driverImage ?? this.driverImage,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
    );
  }
}
