class UrlConstants {
  static const String baseUrl = "http://44.222.121.219/api/v1";

  // Authentication endpoints
  static const String sendOtp = "/otp/send";
  static const String resendOtp = "/otp/resend";
  static const String verifyOtp = "/otp/verify";
  static const String registerUser = "/users/register";
  static const String completeProfile = "/users/profile/complete";
  static const String favouriteLocation = "/users/favouriteLocation";

  // Wallet endpoints (removed duplicate /api/v1 from paths)
  static const String walletSummary = "/wallet/summary";
  static const String getVirtualAccount = "/wallet/virtual-account";
  static const String rides = "/rides";
  static const String createVirtualAccount = "/wallet/virtual-account/create";
}
