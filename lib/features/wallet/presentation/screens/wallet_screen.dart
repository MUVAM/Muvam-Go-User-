import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/app_routes.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/wallet/data/providers/wallet_provider.dart';
import 'package:muvam/features/wallet/presentation/widgets/fund_wallet_sheet.dart';
import 'package:muvam/features/wallet/presentation/widgets/transaction_item.dart';
import 'package:muvam/features/wallet/presentation/widgets/wallet_card.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final provider = context.read<WalletProvider>();
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        debugPrint('Auth token: ${token != null ? 'exists' : 'null'}');
        await provider.fetchWalletSummary();
      } catch (e, stack) {
        debugPrint('Error in WalletScreen initState: $e\n$stack');
      }
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    CustomFlushbar.showInfo(
      context: context,
      message: 'Account number copied!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: SafeArea(
        child: Consumer<WalletProvider>(
          builder: (context, walletProvider, child) {
            if (walletProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.kMainColor),
              );
            }

            final walletSummary = walletProvider.walletSummary;

            if (walletSummary == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48.sp, color: Colors.grey),
                    SizedBox(height: 16.h),
                    MuvamTexts.bodyLarge16(
                      context,
                      text: 'Failed to load wallet data',
                      isTextWidget: true,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: () => walletProvider.fetchWalletSummary(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.kMainColor,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (context.canPop()) context.pop();
                        },
                        child: Image.asset(
                          ConstImages.back,
                          width: 33.w,
                          height: 33.h,
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            context.pushNamed(AppRoutes.howToFund.name),
                        child: MuvamTexts.bodyLarge16(
                          context,
                          text: 'How to fund',
                          isTextWidget: true,
                          color: AppColors.kMainColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  MuvamTexts.headlineSmall24(
                    context,
                    text: 'Wallet',
                    isTextWidget: true,
                  ),
                  SizedBox(height: 20.h),
                  WalletCard(
                    walletSummary: walletSummary,
                    walletProvider: walletProvider,
                    onCopyAccountNumber: () {
                      final virtualAccount = walletSummary.virtualAccount;
                      if (virtualAccount != null) {
                        _copyToClipboard(virtualAccount.accountNumber);
                      }
                    },
                    onFundWallet: () => FundWalletSheet.show(context),
                  ),
                  SizedBox(height: 15.h),
                  MuvamTexts.bodySmall12(
                    context,
                    text:
                        'Transfer to this account to instantly fund your Muvam wallet',
                    center: true,
                    isTextWidget: true,
                    fontWeight: FontWeight.w500,
                  ),
                  SizedBox(height: 30.h),
                  MuvamTexts.titleMedium18(
                    context,
                    text: 'Transaction History',
                    isTextWidget: true,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(height: 20.h),
                  Expanded(
                    child: walletSummary.transactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 48.sp,
                                  color: Colors.grey.shade300,
                                ),
                                SizedBox(height: 16.h),
                                MuvamTexts.bodyMedium14(
                                  context,
                                  text: 'No transactions yet',
                                  isTextWidget: true,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: walletSummary.transactions.length,
                            separatorBuilder: (context, index) => Divider(
                              thickness: 1,
                              color: Colors.grey.shade300,
                            ),
                            itemBuilder: (context, index) {
                              final transaction =
                                  walletSummary.transactions[index];
                              return TransactionItem(
                                amount: walletProvider.formatAmount(
                                  transaction.amount,
                                ),
                                dateTime: walletProvider.formatDateTime(
                                  transaction.createdAt,
                                ),
                                status: transaction.status,
                                statusColor: transaction.isSuccess
                                    ? AppColors.kSuccessColor
                                    : AppColors.kFailureColor,
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
