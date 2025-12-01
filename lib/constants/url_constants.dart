class UrlConstants {
  static const String baseUrl = "http://44.222.121.219/api/v1";
  
  // Authentication endpoints
  static const String sendOtp = "/otp/send";
  static const String resendOtp = "/otp/resend";
  static const String verifyOtp = "/otp/verify";
  static const String registerUser = "/users/register";
  static const String completeProfile = "/api/v1/users/profile/complete";
  static const String favouriteLocation = "/api/v1/users/favouriteLocation";
  static const String rideEstimate = "/rides/estimate";
  static const String rideRequest = "/rides/request";
}