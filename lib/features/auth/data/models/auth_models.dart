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
  final String lastName;
  final String phone;
  final String role;

  RegisterUserRequest({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
    "email": email,
    "first_name": firstName,
    "last_name": lastName,
    "phone": phone,
    "role": role,
  };
}

class ApiResponse {
  final String message;

  ApiResponse({required this.message});

  factory ApiResponse.fromJson(Map<String, dynamic> json) =>
      ApiResponse(message: json['message']);
}

class VerifyOtpResponse {
  final bool isNew;
  final String message;
  final String token;
  final Map<String, dynamic> user;

  VerifyOtpResponse({
    required this.isNew,
    required this.message,
    required this.token,
    required this.user,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) =>
      VerifyOtpResponse(
        isNew: json['isNew'],
        message: json['message'],
        token: json['token'],
        user: json['user'],
      );
}

class RegisterUserResponse {
  final String message;
  final Map<String, dynamic> user;

  RegisterUserResponse({required this.message, required this.user});

  factory RegisterUserResponse.fromJson(Map<String, dynamic> json) =>
      RegisterUserResponse(message: json['message'], user: json['user']);
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
