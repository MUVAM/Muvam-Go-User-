class RideUser {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String phone;
  final bool phoneVerified;
  final bool profileComplete;
  final String? profilePhoto;
  final String? location;
  final String role;
  final double averageRating;
  final int ratingCount;

  RideUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.phone,
    required this.phoneVerified,
    required this.profileComplete,
    this.profilePhoto,
    this.location,
    required this.role,
    required this.averageRating,
    required this.ratingCount,
  });

  factory RideUser.fromJson(Map<String, dynamic> json) => RideUser(
    id: json['id'] ?? 0,
    email: json['email'] ?? '',
    firstName: json['first_name'] ?? '',
    lastName: json['last_name'] ?? '',
    middleName: json['middle_name'],
    phone: json['phone'] ?? '',
    phoneVerified: json['phone_verified'] ?? false,
    profileComplete: json['profile_complete'] ?? false,
    profilePhoto: json['profile_photo'],
    location: json['location'],
    role: json['role'] ?? 'passenger',
    averageRating: (json['average_rating'] ?? 0).toDouble(),
    ratingCount: json['rating_count'] ?? 0,
  );
}

class Ride {
  final int id;
  final String pickupAddress;
  final String pickupLocation;
  final String destAddress;
  final String destLocation;
  final String? stopAddress;
  final String? endLocation;
  final double price;
  final String status;
  final String paymentMethod;
  final bool paymentConfirmed;
  final String serviceType;
  final String vehicleType;
  final bool scheduled;
  final String? scheduledAt;
  final String? note;
  final String? cancellationReason;
  final int? cancelledBy;
  final bool driverRatedPassenger;
  final bool passengerRatedDriver;
  final String createdAt;
  final String updatedAt;
  final int passengerID;
  final int? driverID;
  final RideUser? passenger;
  final RideUser? driver;

  Ride({
    required this.id,
    required this.pickupAddress,
    required this.pickupLocation,
    required this.destAddress,
    required this.destLocation,
    this.stopAddress,
    this.endLocation,
    required this.price,
    required this.status,
    required this.paymentMethod,
    required this.paymentConfirmed,
    required this.serviceType,
    required this.vehicleType,
    required this.scheduled,
    this.scheduledAt,
    this.note,
    this.cancellationReason,
    this.cancelledBy,
    required this.driverRatedPassenger,
    required this.passengerRatedDriver,
    required this.createdAt,
    required this.updatedAt,
    required this.passengerID,
    this.driverID,
    this.passenger,
    this.driver,
  });

  factory Ride.fromJson(Map<String, dynamic> json) => Ride(
    id: json['id'] ?? 0,
    pickupAddress: json['pickupAddress'] ?? '',
    pickupLocation: json['pickupLocation'] ?? '',
    destAddress: json['destAddress'] ?? '',
    destLocation: json['destLocation'] ?? '',
    stopAddress: json['stopAddress'],
    endLocation: json['endLocation'],
    price: (json['price'] ?? 0).toDouble(),
    status: json['status'] ?? 'requested',
    paymentMethod: json['paymentMethod'] ?? 'gateway',
    paymentConfirmed: json['paymentConfirmed'] ?? false,
    serviceType: json['serviceType'] ?? 'taxi',
    vehicleType: json['vehicleType'] ?? 'regular',
    scheduled: json['scheduled'] ?? false,
    scheduledAt: json['scheduledAt'],
    note: json['note'],
    cancellationReason: json['cancellation_reason'],
    cancelledBy: json['cancelled_by'],
    driverRatedPassenger: json['driver_rated_passenger'] ?? false,
    passengerRatedDriver: json['passenger_rated_driver'] ?? false,
    createdAt: json['createdAt'] ?? '',
    updatedAt: json['updatedAt'] ?? '',
    passengerID: json['passengerID'] ?? 0,
    driverID: json['driverID'],
    passenger: json['passenger'] != null
        ? RideUser.fromJson(json['passenger'])
        : null,
    driver: json['driver'] != null ? RideUser.fromJson(json['driver']) : null,
  );

  bool get isPrebooked => scheduled && status == 'requested';
  bool get isActive =>
      status == 'accepted' || status == 'arrived' || status == 'in_progress';
  bool get isHistory => status == 'completed' || status == 'cancelled';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';

  String getPaymentMethodDisplay() {
    switch (paymentMethod) {
      case 'gateway':
        return 'Pay with Card';
      case 'cash':
        return 'Pay in car';
      case 'wallet':
        return 'Wallet';
      default:
        return paymentMethod;
    }
  }

  String getVehicleTypeDisplay() {
    switch (vehicleType) {
      case 'regular':
        return 'Regular vehicle';
      case 'premium':
        return 'Premium vehicle';
      case 'luxury':
        return 'Luxury vehicle';
      default:
        return vehicleType;
    }
  }

  String getServiceTypeDisplay() {
    switch (serviceType) {
      case 'taxi':
        return 'Ride hailing';
      case 'delivery':
        return 'Delivery';
      case 'rental':
        return 'Car rental';
      default:
        return serviceType;
    }
  }
}
