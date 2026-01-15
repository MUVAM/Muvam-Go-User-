import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:country_picker/country_picker.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/auth/data/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/text_styles.dart';
import 'package:muvam/features/otp/presentation/screens/otp_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String countryCode = '+234';
  String countryFlag = '🇳🇬';
  final TextEditingController phoneController = TextEditingController();

  bool _isValidPhone() {
    return phoneController.text.length == 10;
  }

  @override
  void initState() {
    super.initState();
    phoneController.addListener(() {
      setState(() {});
    });
  }

  void _showCustomCountryPicker(BuildContext context) {
    final TextEditingController searchController = TextEditingController();
    List<Country> allCountries = CountryService().getAll();
    List<Country> filteredCountries = allCountries;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 12.h),
                    width: 50.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: TextField(
                      controller: searchController,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search location',
                        hintStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                          height: 1.0,
                        ),
                        suffixIcon: Padding(
                          padding: EdgeInsets.all(12.w),
                          child: Image.asset(
                            'assets/images/search.png',
                            width: 20.w,
                            height: 20.h,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(color: Colors.grey, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(color: Colors.grey, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(
                            color: Colors.grey,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 12.h,
                        ),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          if (value.isEmpty) {
                            filteredCountries = allCountries;
                          } else {
                            filteredCountries = allCountries
                                .where(
                                  (country) =>
                                      country.name.toLowerCase().contains(
                                        value.toLowerCase(),
                                      ) ||
                                      country.phoneCode.contains(value),
                                )
                                .toList();
                          }
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      itemCount: filteredCountries.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey[200],
                      ),
                      itemBuilder: (context, index) {
                        final country = filteredCountries[index];
                        final isSelected =
                            countryCode == '+${country.phoneCode}';

                        return InkWell(
                          onTap: () {
                            setState(() {
                              countryCode = '+${country.phoneCode}';
                              countryFlag = country.flagEmoji;
                            });
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            child: Row(
                              children: [
                                // Flag
                                Text(
                                  country.flagEmoji,
                                  style: TextStyle(fontSize: 28.sp),
                                ),
                                SizedBox(width: 16.w),
                                // Country name
                                Expanded(
                                  child: Text(
                                    country.name,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                Text(
                                  '+${country.phoneCode}',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (isSelected) ...[
                                  SizedBox(width: 12.w),
                                  Icon(
                                    Icons.check,
                                    color: Color(ConstColors.mainColor),
                                    size: 20.sp,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              children: [
                SizedBox(height: 50.h),
                Image.asset(
                  ConstImages.onboardCar,
                  width: 411.w,
                  height: 411.h,
                ),
                // SizedBox(height: 2.h),
                const Text(
                  'Enter your phone number',
                  style: ConstTextStyles.boldTitle,
                ),
                SizedBox(height: 5.h),
                const Text(
                  'We will send you a validation code',
                  style: ConstTextStyles.lightSubtitle,
                ),
                SizedBox(height: 25.h),
                Container(
                  width: 353.w,
                  height: 50.h,
                  decoration: BoxDecoration(
                    color: Color(ConstColors.fieldColor).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _showCustomCountryPicker(context);
                        },
                        child: Container(
                          width: 85.w,
                          height: 42.h,
                          margin: EdgeInsets.only(left: 4.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                countryFlag,
                                style: TextStyle(fontSize: 14.sp),
                              ),
                              SizedBox(width: 2.w),
                              Flexible(
                                child: Text(
                                  countryCode,
                                  style: ConstTextStyles.inputText.copyWith(
                                    fontSize: 14.sp,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.arrow_drop_down, size: 14.sp),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          style: ConstTextStyles.inputText,
                          maxLength: 10,
                          decoration: InputDecoration(
                            hintText: 'Phone number',
                            border: InputBorder.none,
                            counterText: '',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 15.h,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 95.h),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return GestureDetector(
                      onTap: _isValidPhone() && !authProvider.isLoading
                          ? () async {
                              final fullPhone =
                                  countryCode + phoneController.text;
                              final success = await authProvider.sendOtp(
                                fullPhone,
                              );

                              if (!mounted) return;

                              if (success) {
                                // Store phone number for registration
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setString('user_phone', fullPhone);

                                // Small delay to ensure UI updates
                                await Future.delayed(
                                  Duration(milliseconds: 100),
                                );

                                if (mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          OtpScreen(phoneNumber: fullPhone),
                                    ),
                                  );
                                }
                              } else {
                                CustomFlushbar.showError(
                                  context: context,
                                  message:
                                      authProvider.errorMessage ??
                                      'Failed to send OTP',
                                );
                              }
                            }
                          : null,
                      child: Container(
                        width: 353.w,
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: _isValidPhone() && !authProvider.isLoading
                              ? Color(ConstColors.mainColor)
                              : Color(ConstColors.fieldColor),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: authProvider.isLoading
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.h,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Continue',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
