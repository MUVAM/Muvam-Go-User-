// Wallet Summary Response
class WalletSummaryResponse {
  final int id;
  final double balance;
  final String currency;
  final bool isActive;
  final bool isFrozen;
  final bool isVerified;
  final double pendingBalance;
  final double totalDeposits;
  final double totalEarnings;
  final double totalWithdrawals;
  final String type;
  final VirtualAccountInfo? virtualAccount;
  final List<TransactionData> transactions;

  WalletSummaryResponse({
    required this.id,
    required this.balance,
    required this.currency,
    required this.isActive,
    required this.isFrozen,
    required this.isVerified,
    required this.pendingBalance,
    required this.totalDeposits,
    required this.totalEarnings,
    required this.totalWithdrawals,
    required this.type,
    this.virtualAccount,
    required this.transactions,
  });

  factory WalletSummaryResponse.fromJson(Map<String, dynamic> json) =>
      WalletSummaryResponse(
        id: json['id'] ?? 0,
        balance: (json['balance'] ?? 0).toDouble(),
        currency: json['currency'] ?? 'NGN',
        isActive: json['is_active'] ?? false,
        isFrozen: json['is_frozen'] ?? false,
        isVerified: json['is_verified'] ?? false,
        pendingBalance: (json['pending_balance'] ?? 0).toDouble(),
        totalDeposits: (json['total_deposits'] ?? 0).toDouble(),
        totalEarnings: (json['total_earnings'] ?? 0).toDouble(),
        totalWithdrawals: (json['total_withdrawals'] ?? 0).toDouble(),
        type: json['type'] ?? '',
        virtualAccount: json['virtual_account'] != null
            ? VirtualAccountInfo.fromJson(json['virtual_account'])
            : null,
        transactions:
            (json['transactions'] as List<dynamic>?)
                ?.map((t) => TransactionData.fromJson(t))
                .toList() ??
            [],
      );
}

class VirtualAccountInfo {
  final String accountName;
  final String accountNumber;
  final String bankName;
  final String bankCode;

  VirtualAccountInfo({
    required this.accountName,
    required this.accountNumber,
    required this.bankName,
    required this.bankCode,
  });

  factory VirtualAccountInfo.fromJson(Map<String, dynamic> json) =>
      VirtualAccountInfo(
        accountName: json['account_name'] ?? '',
        accountNumber: json['account_number'] ?? '',
        bankName: json['bank_name'] ?? '',
        bankCode: json['bank_code'] ?? '',
      );
}

class TransactionData {
  final int id;
  final double amount;
  final String type;
  final String status;
  final String description;
  final String createdAt;
  final double balanceBefore;
  final double balanceAfter;

  TransactionData({
    required this.id,
    required this.amount,
    required this.type,
    required this.status,
    required this.description,
    required this.createdAt,
    required this.balanceBefore,
    required this.balanceAfter,
  });

  factory TransactionData.fromJson(Map<String, dynamic> json) =>
      TransactionData(
        id: json['id'] ?? 0,
        amount: (json['amount'] ?? 0).toDouble(),
        type: json['type'] ?? '',
        status: json['status'] ?? '',
        description: json['description'] ?? '',
        createdAt: json['createdAt'] ?? '',
        balanceBefore: (json['balance_before'] ?? 0).toDouble(),
        balanceAfter: (json['balance_after'] ?? 0).toDouble(),
      );

  bool get isSuccess =>
      status.toLowerCase() == 'successful' ||
      status.toLowerCase() == 'completed';
  bool get isFailed => status.toLowerCase() == 'failed';
}

// Create Virtual Account Request
class CreateVirtualAccountRequest {
  final KycData kyc;

  CreateVirtualAccountRequest({required this.kyc});

  Map<String, dynamic> toJson() => {"kyc": kyc.toJson()};
}

class KycData {
  final String? bvn;
  final String? nin;

  KycData({this.bvn, this.nin});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (bvn != null) data['bvn'] = bvn;
    if (nin != null) data['nin'] = nin;
    return data;
  }
}

class CreateVirtualAccountResponse {
  final String accountName;
  final String accountNumber;
  final String bankCode;
  final String bankName;
  final String currency;
  final String expiresAt;
  final int id;
  final bool isActive;
  final bool isVerified;
  final String kycProvider;
  final bool kycVerified;
  final String providerType;
  final int userId;
  final int walletId;
  final WalletData? wallet;
  final UserData? user;

  CreateVirtualAccountResponse({
    required this.accountName,
    required this.accountNumber,
    required this.bankCode,
    required this.bankName,
    required this.currency,
    required this.expiresAt,
    required this.id,
    required this.isActive,
    required this.isVerified,
    required this.kycProvider,
    required this.kycVerified,
    required this.providerType,
    required this.userId,
    required this.walletId,
    this.wallet,
    this.user,
  });

  factory CreateVirtualAccountResponse.fromJson(Map<String, dynamic> json) =>
      CreateVirtualAccountResponse(
        accountName: json['account_name'] ?? '',
        accountNumber: json['account_number'] ?? '',
        bankCode: json['bank_code'] ?? '',
        bankName: json['bank_name'] ?? '',
        currency: json['currency'] ?? 'NGN',
        expiresAt: json['expires_at'] ?? '',
        id: json['id'] ?? 0,
        isActive: json['is_active'] ?? false,
        isVerified: json['is_verified'] ?? false,
        kycProvider: json['kyc_provider'] ?? '',
        kycVerified: json['kyc_verified'] ?? false,
        providerType: json['provider_type'] ?? '',
        userId: json['user_id'] ?? 0,
        walletId: json['wallet_id'] ?? 0,
        wallet: json['wallet'] != null
            ? WalletData.fromJson(json['wallet'])
            : null,
        user: json['user'] != null ? UserData.fromJson(json['user']) : null,
      );
}

class WalletData {
  final int id;
  final double balance;
  final String currency;
  final bool isActive;
  final bool isFrozen;
  final bool isVerified;
  final double pendingBalance;
  final double totalDeposits;
  final double totalEarnings;
  final double totalWithdrawals;
  final String type;

  WalletData({
    required this.id,
    required this.balance,
    required this.currency,
    required this.isActive,
    required this.isFrozen,
    required this.isVerified,
    required this.pendingBalance,
    required this.totalDeposits,
    required this.totalEarnings,
    required this.totalWithdrawals,
    required this.type,
  });

  factory WalletData.fromJson(Map<String, dynamic> json) => WalletData(
    id: json['id'] ?? 0,
    balance: (json['balance'] ?? 0).toDouble(),
    currency: json['currency'] ?? 'NGN',
    isActive: json['is_active'] ?? false,
    isFrozen: json['is_frozen'] ?? false,
    isVerified: json['is_verified'] ?? false,
    pendingBalance: (json['pending_balance'] ?? 0).toDouble(),
    totalDeposits: (json['total_deposits'] ?? 0).toDouble(),
    totalEarnings: (json['total_earnings'] ?? 0).toDouble(),
    totalWithdrawals: (json['total_withdrawals'] ?? 0).toDouble(),
    type: json['type'] ?? '',
  );
}

class UserData {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String phone;
  final bool phoneVerified;
  final bool profileComplete;
  final String? profilePhoto;
  final String? location;
  final String role;
  final double averageRating;
  final int ratingCount;
  final int walletId;

  UserData({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.phone,
    required this.phoneVerified,
    required this.profileComplete,
    this.profilePhoto,
    this.location,
    required this.role,
    required this.averageRating,
    required this.ratingCount,
    required this.walletId,
  });

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
    id: json['id'] ?? 0,
    email: json['email'] ?? '',
    firstName: json['first_name'] ?? '',
    lastName: json['last_name'] ?? '',
    middleName: json['middle_name'],
    phone: json['phone'] ?? '',
    phoneVerified: json['phone_verified'] ?? false,
    profileComplete: json['profile_complete'] ?? false,
    profilePhoto: json['profile_photo'],
    location: json['location'],
    role: json['role'] ?? 'passenger',
    averageRating: (json['average_rating'] ?? 0).toDouble(),
    ratingCount: json['rating_count'] ?? 0,
    walletId: json['wallet_id'] ?? 0,
  );
}
