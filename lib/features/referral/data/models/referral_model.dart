class ReferralData {
  final String code;
  final String shareUrl;
  final int totalUses;

  ReferralData({
    required this.code,
    required this.shareUrl,
    required this.totalUses,
  });

  factory ReferralData.fromJson(Map<String, dynamic> json) {
    return ReferralData(
      code: json['code'] ?? '',
      shareUrl: json['share_url'] ?? '',
      totalUses: json['total_uses'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'code': code, 'share_url': shareUrl, 'total_uses': totalUses};
  }
}
