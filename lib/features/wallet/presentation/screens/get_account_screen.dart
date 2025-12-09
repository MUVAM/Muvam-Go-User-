import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/features/wallet/data/providers/wallet_provider.dart';
import 'package:muvam/features/wallet/presentation/screens/account_created_screen.dart';
import 'package:provider/provider.dart';

class GetAccountScreen extends StatefulWidget {
  const GetAccountScreen({super.key});

  @override
  State<GetAccountScreen> createState() => _GetAccountScreenState();
}

class _GetAccountScreenState extends State<GetAccountScreen> {
  final TextEditingController bvnController = TextEditingController();

  @override
  void dispose() {
    bvnController.dispose();
    super.dispose();
  }

  bool _isFormValid() {
    return bvnController.text.length == 11;
  }

  void _handleVerify() async {
    if (!_isFormValid()) return;

    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    // Clear any previous errors
    walletProvider.clearError();

    final success = await walletProvider.createVirtualAccount(
      bvn: bvnController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      // Navigate to success screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AccountCreatedScreen()),
      );
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            walletProvider.errorMessage ?? 'Failed to create virtual account',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        return Stack(
          children: [
            Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20.h),
                      _buildHeader(),
                      SizedBox(height: 40.h),
                      _buildBVNLabel(),
                      SizedBox(height: 12.h),
                      _buildBVNTextField(),
                      SizedBox(height: 16.h),
                      _buildInfoNote(),
                      const Spacer(),
                      _buildVerifyButton(walletProvider),
                      SizedBox(height: 30.h),
                    ],
                  ),
                ),
              ),
            ),
            // Overlay Loader
            if (walletProvider.isLoading) _buildLoadingOverlay(),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Icon(Icons.arrow_back, size: 24.w, color: Colors.black),
          ),
        ),
        const Spacer(),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Get an account',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            Text(
              'Enter your BVN to create your \npersonal wallet',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildBVNLabel() {
    return Text(
      'Bank Verification Number (BVN)',
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }

  Widget _buildBVNTextField() {
    return TextField(
      controller: bvnController,
      keyboardType: TextInputType.number,
      maxLength: 11,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (value) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Enter your BVN',
        hintStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          color: Colors.grey[400],
        ),
        filled: true,
        fillColor: Color(ConstColors.formFieldColor),
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(
            color: Color(ConstColors.mainColor),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
    );
  }

  Widget _buildInfoNote() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Color(ConstColors.mainColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Note: We only collect your BVN to generate a wallet account for you and it is totally optional.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: Color(ConstColors.mainColor),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Your bvn is totally safe and will never be disclosed.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: Color(ConstColors.mainColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton(WalletProvider walletProvider) {
    final isEnabled = _isFormValid() && !walletProvider.isLoading;

    return GestureDetector(
      onTap: isEnabled ? _handleVerify : null,
      child: Container(
        width: double.infinity,
        height: 48.h,
        decoration: BoxDecoration(
          color: isEnabled
              ? Color(ConstColors.mainColor)
              : Color(ConstColors.fieldColor),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Center(
          child: Text(
            'Verify',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48.w,
                height: 48.h,
                child: CircularProgressIndicator(
                  color: Color(ConstColors.mainColor),
                  strokeWidth: 4,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Creating your account...',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Please wait a moment',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
