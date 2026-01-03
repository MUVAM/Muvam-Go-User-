class FavoriteLocation {
  final int? id;
  final String name;
  final String destLocation;
  final String destAddress;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FavoriteLocation({
    this.id,
    required this.name,
    required this.destLocation,
    required this.destAddress,
    this.createdAt,
    this.updatedAt,
  });

  factory FavoriteLocation.fromJson(Map<String, dynamic> json) {
    return FavoriteLocation(
      id: json['id'],
      name: json['name'] ?? '',
      destLocation: json['dest_location'] ?? '',
      destAddress: json['dest_address'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dest_location': destLocation,
      'dest_address': destAddress,
    };
  }

  // Helper to check location type
  bool get isHome => name.toLowerCase() == 'home';
  bool get isWork => name.toLowerCase() == 'work';
  bool get isFavourite => name.toLowerCase() == 'favourite';
}

class FavoriteLocationResponse {
  final bool success;
  final String message;
  final FavoriteLocation? data;

  FavoriteLocationResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory FavoriteLocationResponse.fromJson(Map<String, dynamic> json) {
    return FavoriteLocationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? FavoriteLocation.fromJson(json['data'])
          : null,
    );
  }
}

class FavoriteLocationsListResponse {
  final bool success;
  final List<FavoriteLocation> data;

  FavoriteLocationsListResponse({required this.success, required this.data});

  factory FavoriteLocationsListResponse.fromJson(Map<String, dynamic> json) {
    return FavoriteLocationsListResponse(
      success: json['success'] ?? false,
      data: json['data'] != null
          ? (json['data'] as List)
                .map((item) => FavoriteLocation.fromJson(item))
                .toList()
          : [],
    );
  }
}
