class PromoCodeValidation {
  final double discountAmount;
  final double finalAmount;
  final PromoCodeDetails promoCode;

  PromoCodeValidation({
    required this.discountAmount,
    required this.finalAmount,
    required this.promoCode,
  });

  factory PromoCodeValidation.fromJson(Map<String, dynamic> json) {
    return PromoCodeValidation(
      discountAmount: (json['discount_amount'] ?? 0).toDouble(),
      finalAmount: (json['final_amount'] ?? 0).toDouble(),
      promoCode: PromoCodeDetails.fromJson(json['promo_code'] ?? {}),
    );
  }
}

class PromoCodeDetails {
  final int id;
  final String code;
  final String discountType;
  final double discountValue;
  final double? maxDiscount;
  final double? minRideAmount;
  final String? expiresAt;
  final int? usageLimit;
  final int usageCount;
  final bool isActive;

  PromoCodeDetails({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.maxDiscount,
    this.minRideAmount,
    this.expiresAt,
    this.usageLimit,
    required this.usageCount,
    required this.isActive,
  });

  factory PromoCodeDetails.fromJson(Map<String, dynamic> json) {
    return PromoCodeDetails(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      discountType: json['discount_type'] ?? '',
      discountValue: (json['discount_value'] ?? 0).toDouble(),
      maxDiscount: json['max_discount'] != null
          ? (json['max_discount'] as num).toDouble()
          : null,
      minRideAmount: json['min_ride_amount'] != null
          ? (json['min_ride_amount'] as num).toDouble()
          : null,
      expiresAt: json['expires_at'],
      usageLimit: json['usage_limit'],
      usageCount: json['usage_count'] ?? 0,
      isActive: json['is_active'] ?? false,
    );
  }

  int? getDaysLeft() {
    if (expiresAt == null) return null;
    try {
      final expiry = DateTime.parse(expiresAt!);
      final now = DateTime.now();
      if (expiry.isBefore(now)) return 0;
      return expiry.difference(now).inDays;
    } catch (e) {
      return null;
    }
  }

  String getDiscountDescription() {
    if (discountType == 'percentage') {
      final percentage = discountValue.toInt();
      final maxText = maxDiscount != null
          ? ' (max ₦${maxDiscount!.toInt()})'
          : '';
      return '$percentage% off$maxText';
    } else {
      return '₦${discountValue.toInt()} off';
    }
  }
}
