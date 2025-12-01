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
  final int durationMin;
  final double price;
  final String serviceType;
  final String vehicleType;

  RideEstimateResponse({
    required this.currency,
    required this.distanceKm,
    required this.durationMin,
    required this.price,
    required this.serviceType,
    required this.vehicleType,
  });

  factory RideEstimateResponse.fromJson(Map<String, dynamic> json) => 
      RideEstimateResponse(
        currency: json['currency'],
        distanceKm: json['distance_km'].toDouble(),
        durationMin: json['duration_min'],
        price: json['price'].toDouble(),
        serviceType: json['service_type'],
        vehicleType: json['vehicle_type'],
      );
}

class RideRequest {
  final String dest;
  final String destAddress;
  final String paymentMethod;
  final String pickup;
  final String pickupAddress;
  final String serviceType;
  final String vehicleType;

  RideRequest({
    required this.dest,
    required this.destAddress,
    required this.paymentMethod,
    required this.pickup,
    required this.pickupAddress,
    required this.serviceType,
    required this.vehicleType,
  });

  Map<String, dynamic> toJson() => {
    "dest": dest,
    "dest_address": destAddress,
    "payment_method": paymentMethod,
    "pickup": pickup,
    "pickup_address": pickupAddress,
    "service_type": serviceType,
    "vehicle_type": vehicleType,
  };
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

  factory RideResponse.fromJson(Map<String, dynamic> json) => 
      RideResponse(
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