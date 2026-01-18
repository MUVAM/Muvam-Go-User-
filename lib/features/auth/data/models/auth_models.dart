class SendOtpRequest {
  final String phone;

  SendOtpRequest({required this.phone});

  Map<String, dynamic> toJson() => {"phone": phone};
}

class VerifyOtpRequest {
  final String code;
  final String phone;

  VerifyOtpRequest({required this.code, required this.phone});

  Map<String, dynamic> toJson() => {"code": code, "phone": phone};
}

class RegisterUserRequest {
  final String email;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String phone;
  final String dateOfBirth;
  final String role;
  final String location;
  final String city;
  final String? referralCode;
  final String serviceType;

  RegisterUserRequest({
    required this.email,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.phone,
    required this.dateOfBirth,
    required this.role,
    required this.location,
    required this.city,
    this.referralCode,
    required this.serviceType,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      "first_name": firstName,
      "last_name": lastName,
      "email": email,
      "phone": phone,
      "date_of_birth": dateOfBirth,
      "city": city.toLowerCase(),
      "role": role,
      "service_type": serviceType,
      "location": location,
    };

    // Only add optional fields if they have values
    if (middleName != null && middleName!.isNotEmpty) {
      json["middle_name"] = middleName!;
    }

    if (referralCode != null && referralCode!.isNotEmpty) {
      json["referral_code"] = referralCode!;
    }

    return json;
  }
}

class ApiResponse {
  final String message;

  ApiResponse({required this.message});

  factory ApiResponse.fromJson(Map<String, dynamic> json) =>
      ApiResponse(message: json['message']);
}

class TokenData {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  TokenData({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory TokenData.fromJson(Map<String, dynamic> json) => TokenData(
    accessToken: json['access_token'],
    refreshToken: json['refresh_token'],
    expiresIn: json['expires_in'],
  );
}

class VerifyOtpResponse {
  final bool isNew;
  final String message;
  final TokenData? token;
  final Map<String, dynamic>? user;

  VerifyOtpResponse({
    required this.isNew,
    required this.message,
    this.token,
    this.user,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) =>
      VerifyOtpResponse(
        isNew: json['isNew'],
        message: json['message'],
        token: json['token'] != null ? TokenData.fromJson(json['token']) : null,
        user: json['user'],
      );
}

// FIXED: RegisterUserResponse now expects nested token object like the API returns
class RegisterUserResponse {
  final String message;
  final TokenData token; // Changed from String to TokenData
  final Map<String, dynamic> user;

  RegisterUserResponse({
    required this.message,
    required this.token,
    required this.user,
  });

  factory RegisterUserResponse.fromJson(Map<String, dynamic> json) {
    return RegisterUserResponse(
      message: json['message'],
      token: TokenData.fromJson(json['token']), // Parse nested token object
      user: json['user'],
    );
  }
}

class CompleteProfileRequest {
  final String firstName;
  final String? middleName;
  final String lastName;
  final String email;
  final String? profilePhotoPath;

  CompleteProfileRequest({
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.email,
    this.profilePhotoPath,
  });
}
