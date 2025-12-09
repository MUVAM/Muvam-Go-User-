class FavouriteLocationRequest {
  final String destAddress;
  final String destLocation;
  final String name;

  FavouriteLocationRequest({
    required this.destAddress,
    required this.destLocation,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
    "dest_address": destAddress,
    "dest_location": destLocation,
    "name": name,
  };
}

class FavouriteLocation {
  final int id;
  final String destAddress;
  final String destLocation;
  final String name;
  final String createdAt;
  final String updatedAt;
  final int userID;

  FavouriteLocation({
    required this.id,
    required this.destAddress,
    required this.destLocation,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.userID,
  });

  factory FavouriteLocation.fromJson(Map<String, dynamic> json) => FavouriteLocation(
    id: json['ID'] ?? 0,
    destAddress: json['DestAddress'] ?? '',
    destLocation: json['DestLocation'] ?? '',
    name: json['Name'] ?? '',
    createdAt: json['CreatedAt'] ?? '',
    updatedAt: json['UpdatedAt'] ?? '',
    userID: json['UserID'] ?? 0,
  );
}