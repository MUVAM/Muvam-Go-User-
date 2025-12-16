class UrlConstants {
  static const String baseUrl = "http://44.222.121.219/api/v1";
  static const String wsUrl = "ws://44.222.121.219/api/v1/ws";
static const String webSocketUrl="ws://44.222.121.219/api/v1/ws";
  // Authentication
  static const String sendOtp = "/otp/send";
  static const String resendOtp = "/otp/resend";
  static const String verifyOtp = "/otp/verify";
  static const String registerUser = "/users/register";
  static const String completeProfile = "/users/profile/complete";
  static const String userProfile = "/users/profile";
  static const String userTip = "/users/tip";
  static const String favouriteLocation = "/users/favouriteLocation";

  // Wallet
  static const String walletSummary = "/wallet/summary";
  static const String getVirtualAccount = "/wallet/virtual-account";
  static const String createVirtualAccount = "/wallet/virtual-account/create";

  // Rides
  static const String rides = "/rides";
  static const String rideEstimate = "/rides/estimate";
  static const String rideRequest = "/rides/request";
  static const String nearbyRides = "/rides/nearby";
  static const String activeRides = "/rides";

  // Payment
  static const String paymentInitialize = "/payment/initialize";
}
