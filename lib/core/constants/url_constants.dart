class UrlConstants {
  static const String baseUrl = "http://localhost:3000/api/v1";
  
  // Authentication endpoints
  static const String sendOtp = "/otp/send";
  static const String resendOtp = "/otp/resend";
  static const String verifyOtp = "/otp/verify";
  static const String registerUser = "/users/register";
  static const String completeProfile = "/api/v1/users/profile/complete";
  static const String favouriteLocation = "/api/v1/users/favouriteLocation";
}