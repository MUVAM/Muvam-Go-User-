// class RideData {
//   final int id;
//   final String createdAt;
//   final String updatedAt;
//   final int passengerId;
//   final int? driverId;
//   final String pickupAddress;
//   final String destAddress;
//   final String? stopAddress;
//   final double price;
//   final String status;
//   final String? scheduledAt;
//   final bool scheduled;
//   final String serviceType;
//   final String vehicleType;
//   final String paymentMethod;
//   final String? note;
//   final UserProfile? passenger;
//   final UserProfile? driver;

//   RideData({
//     required this.id,
//     required this.createdAt,
//     required this.updatedAt,
//     required this.passengerId,
//     this.driverId,
//     required this.pickupAddress,
//     required this.destAddress,
//     this.stopAddress,
//     required this.price,
//     required this.status,
//     this.scheduledAt,
//     required this.scheduled,
//     required this.serviceType,
//     required this.vehicleType,
//     required this.paymentMethod,
//     this.note,
//     this.passenger,
//     this.driver,
//   });

//   // CRITICAL: Check if ScheduledAt is a valid future date
//   bool _hasValidScheduledTime() {
//     if (scheduledAt == null || scheduledAt!.isEmpty) return false;

//     try {
//       final scheduledTime = DateTime.parse(scheduledAt!);

//       // Check if it's not the zero/null date (0001-01-01)
//       if (scheduledTime.year == 1) return false;

//       final now = DateTime.now();
//       return scheduledTime.isAfter(now);
//     } catch (e) {
//       return false;
//     }
//   }

//   // FIXED: Prebooked rides are those with Scheduled=true OR valid future ScheduledAt
//   bool get isPrebooked {
//     // If the API explicitly marks it as scheduled
//     if (scheduled) return true;

//     // Or if it has a valid future scheduled time
//     if (_hasValidScheduledTime()) return true;

//     return false;
//   }

//   // FIXED: Active rides are "requested" status without future scheduling
//   bool get isActive {
//     // If it's prebooked, it's not active yet
//     if (isPrebooked) return false;

//     // Active statuses
//     final activeStatuses = [
//       'requested', // Just requested, waiting for driver
//       'accepted', // Driver accepted
//       'arrived', // Driver arrived at pickup
//       'started', // Trip started
//       'picking_up', // Picking up passenger
//       'in_progress', // Currently in transit
//     ];

//     return activeStatuses.contains(status.toLowerCase());
//   }

//   // History rides are completed or cancelled
//   bool get isHistory {
//     final historyStatuses = [
//       'completed',
//       'cancelled',
//       'canceled', // Handle both spellings
//     ];

//     return historyStatuses.contains(status.toLowerCase());
//   }

//   bool get isCompleted {
//     return status.toLowerCase() == 'completed';
//   }

//   bool get isCancelled {
//     return status.toLowerCase() == 'cancelled' ||
//         status.toLowerCase() == 'canceled';
//   }

//   factory RideData.fromJson(Map<String, dynamic> json) {
//     return RideData(
//       id: json['ID'] ?? 0,
//       createdAt: json['CreatedAt'] ?? '',
//       updatedAt: json['UpdatedAt'] ?? '',
//       passengerId: json['PassengerID'] ?? 0,
//       driverId: json['DriverID'],
//       pickupAddress: json['PickupAddress'] ?? '',
//       destAddress: json['DestAddress'] ?? '',
//       stopAddress: json['StopAddress'],
//       price: (json['Price'] ?? 0).toDouble(),
//       status: json['Status'] ?? 'unknown',
//       scheduledAt: json['ScheduledAt'],
//       scheduled: json['Scheduled'] ?? false,
//       serviceType: json['ServiceType'] ?? 'taxi',
//       vehicleType: json['VehicleType'] ?? 'regular',
//       paymentMethod: json['PaymentMethod'] ?? 'in_car',
//       note: json['Note'],
//       passenger: json['Passenger'] != null
//           ? UserProfile.fromJson(json['Passenger'])
//           : null,
//       driver: json['Driver'] != null
//           ? UserProfile.fromJson(json['Driver'])
//           : null,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'ID': id,
//       'CreatedAt': createdAt,
//       'UpdatedAt': updatedAt,
//       'PassengerID': passengerId,
//       'DriverID': driverId,
//       'PickupAddress': pickupAddress,
//       'DestAddress': destAddress,
//       'StopAddress': stopAddress,
//       'Price': price,
//       'Status': status,
//       'ScheduledAt': scheduledAt,
//       'Scheduled': scheduled,
//       'ServiceType': serviceType,
//       'VehicleType': vehicleType,
//       'PaymentMethod': paymentMethod,
//       'Note': note,
//       'Passenger': passenger?.toJson(),
//       'Driver': driver?.toJson(),
//     };
//   }
// }

// class UserProfile {
//   final int id;
//   final String firstName;
//   final String middleName;
//   final String lastName;
//   final String email;
//   final String phone;
//   final String profilePhoto;
//   final double averageRating;
//   final int ratingCount;

//   UserProfile({
//     required this.id,
//     required this.firstName,
//     required this.middleName,
//     required this.lastName,
//     required this.email,
//     required this.phone,
//     required this.profilePhoto,
//     required this.averageRating,
//     required this.ratingCount,
//   });

//   String get fullName {
//     final parts = [
//       firstName,
//       middleName,
//       lastName,
//     ].where((part) => part.isNotEmpty).join(' ');
//     return parts.isEmpty ? 'User' : parts;
//   }

//   String get shortName {
//     final parts = [
//       firstName,
//       lastName,
//     ].where((part) => part.isNotEmpty).join(' ');
//     return parts.isEmpty ? 'User' : parts;
//   }

//   factory UserProfile.fromJson(Map<String, dynamic> json) {
//     return UserProfile(
//       id: json['ID'] ?? 0,
//       firstName: json['first_name'] ?? '',
//       middleName: json['middle_name'] ?? '',
//       lastName: json['last_name'] ?? '',
//       email: json['Email'] ?? '',
//       phone: json['phone'] ?? '',
//       profilePhoto: json['profile_photo'] ?? '',
//       averageRating: (json['average_rating'] ?? 0).toDouble(),
//       ratingCount: json['rating_count'] ?? 0,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'ID': id,
//       'first_name': firstName,
//       'middle_name': middleName,
//       'last_name': lastName,
//       'Email': email,
//       'phone': phone,
//       'profile_photo': profilePhoto,
//       'average_rating': averageRating,
//       'rating_count': ratingCount,
//     };
//   }
// }

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

  // CRITICAL: Check if ScheduledAt is a valid future date
  bool _hasValidScheduledTime() {
    if (scheduledAt == null || scheduledAt!.isEmpty) return false;

    try {
      final scheduledTime = DateTime.parse(scheduledAt!);

      // Check if it's not the zero/null date (0001-01-01)
      if (scheduledTime.year == 1) return false;

      final now = DateTime.now();
      return scheduledTime.isAfter(now);
    } catch (e) {
      return false;
    }
  }

  // FIXED: Prebooked rides are those with Scheduled=true OR valid future ScheduledAt
  bool get isPrebooked {
    // If the API explicitly marks it as scheduled
    if (scheduled) return true;

    // Or if it has a valid future scheduled time
    if (_hasValidScheduledTime()) return true;

    return false;
  }

  // FIXED: Active rides are "requested" status without future scheduling
  bool get isActive {
    // If it's prebooked, it's not active yet
    if (isPrebooked) return false;

    // Active statuses
    final activeStatuses = [
      'requested', // Just requested, waiting for driver
      'accepted', // Driver accepted
      'arrived', // Driver arrived at pickup
      'started', // Trip started
      'picking_up', // Picking up passenger
      'in_progress', // Currently in transit
    ];

    return activeStatuses.contains(status.toLowerCase());
  }

  // History rides are completed or cancelled
  bool get isHistory {
    final historyStatuses = [
      'completed',
      'cancelled',
      'canceled', // Handle both spellings
    ];

    return historyStatuses.contains(status.toLowerCase());
  }

  bool get isCompleted {
    return status.toLowerCase() == 'completed';
  }

  bool get isCancelled {
    return status.toLowerCase() == 'cancelled' ||
        status.toLowerCase() == 'canceled';
  }

  // Helper to check if ride was cancelled by passenger
  bool get wasCancelledByPassenger {
    return isCancelled && cancelledBy == passengerId;
  }

  // Helper to check if ride was cancelled by driver
  bool get wasCancelledByDriver {
    return isCancelled && cancelledBy == driverId;
  }

  // Helper to get display-friendly payment method
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

  // Helper to get display-friendly vehicle type
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
