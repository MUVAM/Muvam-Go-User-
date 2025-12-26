class RideEstimateRequest {
  final String pickup;
  final String dest;
  final String destAddress;
  final String serviceType;
  final String vehicleType;

  RideEstimateRequest({
    required this.pickup,
    required this.dest,
    required this.destAddress,
    required this.serviceType,
    required this.vehicleType,
  });

  Map<String, dynamic> toJson() => {
    "pickup": pickup,
    "dest": dest,
    "dest_address": destAddress,
    "service_type": serviceType,
    "vehicle_type": vehicleType,
  };
}

class RideEstimateResponse {
  final String currency;
  final double distanceKm;
  final double durationMin;
  final String serviceType;
  final List<Map<String, dynamic>> priceList;

  RideEstimateResponse({
    required this.currency,
    required this.distanceKm,
    required this.durationMin,
    required this.serviceType,
    required this.priceList,
  });

  factory RideEstimateResponse.fromJson(Map<String, dynamic> json) {
    return RideEstimateResponse(
      currency: json['currency'],
      distanceKm: json['distance_km'].toDouble(),
      durationMin: json['duration_min'].toDouble(),
      serviceType: json['service_type'],
      priceList: List<Map<String, dynamic>>.from(json['price']),
    );
  }
}

class RideRequest {
  final String dest;
  final String destAddress;
  final String paymentMethod;
  final String pickup;
  final String pickupAddress;
  final String serviceType;
  final String vehicleType;
  final bool? scheduled;
  final String? scheduledAt;

  RideRequest({
    required this.dest,
    required this.destAddress,
    required this.paymentMethod,
    required this.pickup,
    required this.pickupAddress,
    required this.serviceType,
    required this.vehicleType,
    this.scheduled,
    this.scheduledAt,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      "pickup": pickup,
      "dest": dest,
      "pickup_address": pickupAddress,
      "dest_address": destAddress,
      "service_type": serviceType,
      "vehicle_type": vehicleType,
      "payment_method": _getPaymentMethodKey(paymentMethod),
    };

    if (scheduled == true && scheduledAt != null) {
      json["scheduled"] = scheduled;
      json["scheduled_at"] = scheduledAt;
    }

    return json;
  }

  String _getPaymentMethodKey(String displayMethod) {
    switch (displayMethod.toLowerCase()) {
      case 'pay with card':
        return 'gateway';
      case 'pay with wallet':
        return 'wallet';
      case 'pay in car':
        return 'in_car';
      case 'pay4me':
        return 'pay_4_me';
      default:
        return displayMethod;
    }
  }
}

class RideResponse {
  final int id;
  final String status;
  final String pickupAddress;
  final String destAddress;
  final double price;
  final String serviceType;
  final String vehicleType;
  final String paymentMethod;

  RideResponse({
    required this.id,
    required this.status,
    required this.pickupAddress,
    required this.destAddress,
    required this.price,
    required this.serviceType,
    required this.vehicleType,
    required this.paymentMethod,
  });

  factory RideResponse.fromJson(Map<String, dynamic> json) => RideResponse(
    id: json['ID'],
    status: json['Status'],
    pickupAddress: json['PickupAddress'],
    destAddress: json['DestAddress'],
    price: json['Price'].toDouble(),
    serviceType: json['ServiceType'],
    vehicleType: json['VehicleType'],
    paymentMethod: json['PaymentMethod'],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "status": status,
    "pickupAddress": pickupAddress,
    "destAddress": destAddress,
    "price": price,
    "serviceType": serviceType,
    "vehicleType": vehicleType,
    "paymentMethod": paymentMethod,
  };
}

class Driver {
  final String id;
  final String name;
  final String profilePicture;
  final String phoneNumber;
  final double rating;
  final String vehicleModel;
  final String plateNumber;

  Driver({
    required this.id,
    required this.name,
    required this.profilePicture,
    required this.phoneNumber,
    required this.rating,
    required this.vehicleModel,
    required this.plateNumber,
  });

  factory Driver.fromJson(Map<String, dynamic> json) => Driver(
    id: json['id'].toString(),
    name: json['name'] ?? 'Driver',
    profilePicture: json['profile_picture'] ?? '',
    phoneNumber: json['phone_number'] ?? '',
    rating: (json['rating'] ?? 0.0).toDouble(),
    vehicleModel: json['vehicle_model'] ?? '',
    plateNumber: json['plate_number'] ?? '',
  );
}

class ChatMessage {
  final String id;
  final String message;
  final String senderId;
  final String senderType; // 'user' or 'driver'
  final DateTime timestamp;
  final bool isMe;

  ChatMessage({
    required this.id,
    required this.message,
    required this.senderId,
    required this.senderType,
    required this.timestamp,
    required this.isMe,
  });

  factory ChatMessage.fromJson(
    Map<String, dynamic> json,
    String currentUserId,
  ) => ChatMessage(
    id: json['id'].toString(),
    message: json['message'] ?? '',
    senderId: json['sender_id'].toString(),
    senderType: json['sender_type'] ?? 'user',
    timestamp: DateTime.parse(json['timestamp']),
    isMe: json['sender_id'].toString() == currentUserId,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'message': message,
    'sender_id': senderId,
    'sender_type': senderType,
    'timestamp': timestamp.toIso8601String(),
  };
}
