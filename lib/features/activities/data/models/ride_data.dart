class RideData {
  final int id;
  final String createdAt;
  final String updatedAt;
  final int passengerId;
  final int? driverId;
  final String pickupAddress;
  final String destAddress;
  final String? stopAddress;
  final double price;
  final String status;
  final String? scheduledAt;
  final bool scheduled;
  final String serviceType;
  final String vehicleType;
  final String paymentMethod;
  final String? note;
  final String? cancellationReason;
  final int? cancelledBy;
  final bool passengerRatedDriver;
  final bool driverRatedPassenger;
  final bool paymentConfirmed;
  final UserProfile? passenger;
  final UserProfile? driver;

  RideData({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.passengerId,
    this.driverId,
    required this.pickupAddress,
    required this.destAddress,
    this.stopAddress,
    required this.price,
    required this.status,
    this.scheduledAt,
    required this.scheduled,
    required this.serviceType,
    required this.vehicleType,
    required this.paymentMethod,
    this.note,
    this.cancellationReason,
    this.cancelledBy,
    this.passengerRatedDriver = false,
    this.driverRatedPassenger = false,
    this.paymentConfirmed = false,
    this.passenger,
    this.driver,
  });

  bool _hasValidScheduledTime() {
    if (scheduledAt == null || scheduledAt!.isEmpty) return false;

    try {
      final scheduledTime = DateTime.parse(scheduledAt!);

      if (scheduledTime.year == 1) return false;

      final now = DateTime.now();
      return scheduledTime.isAfter(now);
    } catch (e) {
      return false;
    }
  }

  bool get isPrebooked {
    if (scheduled) return true;

    if (_hasValidScheduledTime()) return true;

    return false;
  }

  bool get isActive {
    if (isPrebooked) return false;

    final activeStatuses = [
      'requested',
      'accepted',
      'arrived',
      'started',
      'picking_up',
      'in_progress',
    ];

    return activeStatuses.contains(status.toLowerCase());
  }

  bool get isHistory {
    final historyStatuses = ['completed', 'cancelled', 'canceled'];

    return historyStatuses.contains(status.toLowerCase());
  }

  bool get isCompleted {
    return status.toLowerCase() == 'completed';
  }

  bool get isCancelled {
    return status.toLowerCase() == 'cancelled' ||
        status.toLowerCase() == 'canceled';
  }

  bool get wasCancelledByPassenger {
    return isCancelled && cancelledBy == passengerId;
  }

  bool get wasCancelledByDriver {
    return isCancelled && cancelledBy == driverId;
  }

  String getPaymentMethodDisplay() {
    switch (paymentMethod.toLowerCase()) {
      case 'in_car':
        return 'Cash';
      case 'wallet':
        return 'Wallet';
      case 'card':
        return 'Card';
      default:
        return paymentMethod;
    }
  }

  String getVehicleTypeDisplay() {
    switch (vehicleType.toLowerCase()) {
      case 'regular':
        return 'Regular';
      case 'premium':
        return 'Premium';
      case 'luxury':
        return 'Luxury';
      case 'suv':
        return 'SUV';
      default:
        return vehicleType;
    }
  }

  factory RideData.fromJson(Map<String, dynamic> json) {
    return RideData(
      id: json['ID'] ?? 0,
      createdAt: json['CreatedAt'] ?? '',
      updatedAt: json['UpdatedAt'] ?? '',
      passengerId: json['PassengerID'] ?? 0,
      driverId: json['DriverID'],
      pickupAddress: json['PickupAddress'] ?? '',
      destAddress: json['DestAddress'] ?? '',
      stopAddress: json['StopAddress'],
      price: (json['Price'] ?? 0).toDouble(),
      status: json['Status'] ?? 'unknown',
      scheduledAt: json['ScheduledAt'],
      scheduled: json['Scheduled'] ?? false,
      serviceType: json['ServiceType'] ?? 'taxi',
      vehicleType: json['VehicleType'] ?? 'regular',
      paymentMethod: json['PaymentMethod'] ?? 'in_car',
      note: json['Note'],
      cancellationReason: json['cancellation_reason'],
      cancelledBy: json['cancelled_by'],
      passengerRatedDriver: json['passenger_rated_driver'] ?? false,
      driverRatedPassenger: json['driver_rated_passenger'] ?? false,
      paymentConfirmed: json['PaymentConfirmed'] ?? false,
      passenger: json['Passenger'] != null
          ? UserProfile.fromJson(json['Passenger'])
          : null,
      driver: json['Driver'] != null
          ? UserProfile.fromJson(json['Driver'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'CreatedAt': createdAt,
      'UpdatedAt': updatedAt,
      'PassengerID': passengerId,
      'DriverID': driverId,
      'PickupAddress': pickupAddress,
      'DestAddress': destAddress,
      'StopAddress': stopAddress,
      'Price': price,
      'Status': status,
      'ScheduledAt': scheduledAt,
      'Scheduled': scheduled,
      'ServiceType': serviceType,
      'VehicleType': vehicleType,
      'PaymentMethod': paymentMethod,
      'Note': note,
      'cancellation_reason': cancellationReason,
      'cancelled_by': cancelledBy,
      'passenger_rated_driver': passengerRatedDriver,
      'driver_rated_passenger': driverRatedPassenger,
      'PaymentConfirmed': paymentConfirmed,
      'Passenger': passenger?.toJson(),
      'Driver': driver?.toJson(),
    };
  }
}

class UserProfile {
  final int id;
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String phone;
  final String profilePhoto;
  final double averageRating;
  final int ratingCount;

  UserProfile({
    required this.id,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.profilePhoto,
    required this.averageRating,
    required this.ratingCount,
  });

  String get fullName {
    final parts = [
      firstName,
      middleName,
      lastName,
    ].where((part) => part.isNotEmpty).join(' ');
    return parts.isEmpty ? 'User' : parts;
  }

  String get shortName {
    final parts = [
      firstName,
      lastName,
    ].where((part) => part.isNotEmpty).join(' ');
    return parts.isEmpty ? 'User' : parts;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['ID'] ?? 0,
      firstName: json['first_name'] ?? '',
      middleName: json['middle_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['Email'] ?? '',
      phone: json['phone'] ?? '',
      profilePhoto: json['profile_photo'] ?? '',
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      ratingCount: json['rating_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'Email': email,
      'phone': phone,
      'profile_photo': profilePhoto,
      'average_rating': averageRating,
      'rating_count': ratingCount,
    };
  }
}
