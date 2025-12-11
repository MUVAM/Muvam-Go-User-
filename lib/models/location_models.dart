class FavouriteLocation {
  final int id;
  final String name;
  final String destAddress;
  final String destLocation;
  final int userID;
  final String createdAt;
  final String updatedAt;

  FavouriteLocation({
    required this.id,
    required this.name,
    required this.destAddress,
    required this.destLocation,
    required this.userID,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FavouriteLocation.fromJson(Map<String, dynamic> json) => 
      FavouriteLocation(
        id: json['id'],
        name: json['name'],
        destAddress: json['destAddress'],
        destLocation: json['destLocation'],
        userID: json['userID'],
        createdAt: json['createdAt'],
        updatedAt: json['updatedAt'],
      );
}

class AddFavouriteRequest {
  final String name;
  final String destAddress;
  final String destLocation;

  AddFavouriteRequest({
    required this.name,
    required this.destAddress,
    required this.destLocation,
  });

  Map<String, dynamic> toJson() => {
    "name": name,
    "dest_address": destAddress,
    "dest_location": destLocation,
  };
}

class RecentLocation {
  final String name;
  final String address;
  final bool isFavourite;

  RecentLocation({
    required this.name,
    required this.address,
    this.isFavourite = false,
  });
}