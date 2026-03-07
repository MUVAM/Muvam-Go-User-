enum AppRoutes {
  // ── Core ──────────────────────────────────────────────
  splash('/'),
  onboarding('/onboarding'),

  // ── Auth ──────────────────────────────────────────────
  otp('/otp'),
  createAccount('/create-account'),
  deleteAccount('/delete-account'),
  stateSelection('/state-selection'),
  lgaSelection('/lga-selection'),

  // ── Main ──────────────────────────────────────────────
  home('/home'),

  // ── Trips / Activities ────────────────────────────────
  activeTrip('/active-trip'),
  historyCompleted('/history-completed'),
  historyCancelled('/history-cancelled'),
  tripDetails('/trip-details'),
  editPrebooking('/edit-prebooking'),
  tip('/tip'),
  customTip('/custom-tip'),

  // ── Chat / Call ───────────────────────────────────────
  chat('/chat'),
  call('/call'),

  // ── Profile ───────────────────────────────────────────
  profile('/profile'),
  editProfile('/edit-profile'),
  editFullName('/edit-full-name'),
  biometricLock('/biometric-lock'),
  appLockSettings('/app-lock-settings'),

  // ── Home / Map ────────────────────────────────────────
  addFavourite('/add-favourite'),
  addHome('/add-home'),
  mapPicker('/map-picker'),
  mapSelection('/map-selection'),
  services('/services'),
  comingSoon('/coming-soon'),
  paymentWebView('/payment-webview'),

  // ── Wallet ────────────────────────────────────────────
  wallet('/wallet'),
  walletEmpty('/wallet-empty'),
  accountCreated('/account-created'),
  getAccount('/get-account'),
  howToFund('/how-to-fund'),
  buyGiftCard('/buy-gift-card'),

  // ── Support / Info ────────────────────────────────────
  referral('/referral'),
  referralRules('/referral-rules'),
  promoCode('/promo-code'),
  aboutUs('/about-us'),
  faq('/faq');

  const AppRoutes(this.urlPath);
  final String urlPath;
}
