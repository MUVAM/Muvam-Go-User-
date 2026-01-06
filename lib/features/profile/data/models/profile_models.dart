class ProfileResponse {
  final Vehicle? defaultVehicle;
  final UserProfile user;

  ProfileResponse({this.defaultVehicle, required this.user});

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      defaultVehicle: json['default_vehicle'] != null
          ? Vehicle.fromJson(json['default_vehicle'])
          : null,
      user: UserProfile.fromJson(json['user']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'default_vehicle': defaultVehicle?.toJson(), 'user': user.toJson()};
  }
}

class UserProfile {
  final int id;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String firstName;
  final String middleName;
  final String lastName;
  final String dateOfBirth;
  final String email;
  final String phone;
  final int defaultTip;
  final String role;
  final String profilePhoto;
  final bool profileComplete;
  final String location;
  final String city;
  final String serviceType;
  final double averageRating;
  final int ratingCount;
  final List<Vehicle> vehicles;

  UserProfile({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.dateOfBirth,
    required this.email,
    required this.phone,
    required this.defaultTip,
    required this.role,
    required this.profilePhoto,
    required this.profileComplete,
    required this.location,
    required this.city,
    required this.serviceType,
    required this.averageRating,
    required this.ratingCount,
    required this.vehicles,
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
      createdAt: json['CreatedAt'] ?? '',
      updatedAt: json['UpdatedAt'] ?? '',
      deletedAt: json['DeletedAt'],
      firstName: json['first_name'] ?? '',
      middleName: json['middle_name'] ?? '',
      lastName: json['last_name'] ?? '',
      dateOfBirth: json['date_of_birth'] ?? '',
      email: json['Email'] ?? '',
      phone: json['phone'] ?? '',
      defaultTip: json['default_tip'] ?? 0,
      role: json['Role'] ?? '',
      profilePhoto: json['profile_photo'] ?? '',
      profileComplete: json['profile_complete'] ?? false,
      location: json['Location'] ?? '',
      city: json['city'] ?? '',
      serviceType: json['service_type'] ?? '',
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      ratingCount: json['rating_count'] ?? 0,
      vehicles:
          (json['Vehicles'] as List<dynamic>?)
              ?.map((v) => Vehicle.fromJson(v))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'CreatedAt': createdAt,
      'UpdatedAt': updatedAt,
      'DeletedAt': deletedAt,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'date_of_birth': dateOfBirth,
      'Email': email,
      'phone': phone,
      'default_tip': defaultTip,
      'Role': role,
      'profile_photo': profilePhoto,
      'profile_complete': profileComplete,
      'Location': location,
      'city': city,
      'service_type': serviceType,
      'average_rating': averageRating,
      'rating_count': ratingCount,
      'Vehicles': vehicles.map((v) => v.toJson()).toList(),
    };
  }
}

class Vehicle {
  final int? id;
  final String? make;
  final String? model;
  final String? year;
  final String? color;
  final String? plateNumber;
  final String? vehicleType;

  Vehicle({
    this.id,
    this.make,
    this.model,
    this.year,
    this.color,
    this.plateNumber,
    this.vehicleType,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      make: json['make'],
      model: json['model'],
      year: json['year'],
      color: json['color'],
      plateNumber: json['plate_number'],
      vehicleType: json['vehicle_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'make': make,
      'model': model,
      'year': year,
      'color': color,
      'plate_number': plateNumber,
      'vehicle_type': vehicleType,
    };
  }
}
