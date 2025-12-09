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
<<<<<<< HEAD
=======
  final String? location;
>>>>>>> master

  RegisterUserRequest({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.role,
<<<<<<< HEAD
  });

  Map<String, dynamic> toJson() => {
    "email": email,
    "first_name": firstName,
    "last_name": lastName,
    "phone": phone,
    "role": role,
  };
=======
    this.location,
  });

  Map<String, dynamic> toJson() {
    final json = {
      "email": email,
      "first_name": firstName,
      "last_name": lastName,
      "phone": phone,
      "role": role,
      "service_type": "taxi",
    };
    if (location != null) {
      json["location"] = location!;
    }
    return json;
  }
>>>>>>> master
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
<<<<<<< HEAD
  final String token;
  final Map<String, dynamic> user;
=======
  final String? token;
  final Map<String, dynamic>? user;
>>>>>>> master

  VerifyOtpResponse({
    required this.isNew,
    required this.message,
<<<<<<< HEAD
    required this.token,
    required this.user,
=======
    this.token,
    this.user,
>>>>>>> master
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
<<<<<<< HEAD
  final Map<String, dynamic> user;

  RegisterUserResponse({required this.message, required this.user});
=======
  final String token;
  final Map<String, dynamic> user;

  RegisterUserResponse({required this.message, required this.token, required this.user});
>>>>>>> master

  factory RegisterUserResponse.fromJson(Map<String, dynamic> json) => 
      RegisterUserResponse(
        message: json['message'],
<<<<<<< HEAD
=======
        token: json['token'],
>>>>>>> master
        user: json['user'],
      );
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