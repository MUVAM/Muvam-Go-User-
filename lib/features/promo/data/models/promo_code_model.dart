class PromoCodeValidation {
  final String message;

  PromoCodeValidation({required this.message});

  factory PromoCodeValidation.fromJson(Map<String, dynamic> json) {
    return PromoCodeValidation(
      message: json['message'] ?? 'Promo code applied successfully',
    );
  }
}
