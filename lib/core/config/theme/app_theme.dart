import 'package:flutter/material.dart';
import 'package:muvam/core/constants/app_colors.dart';

ThemeData get lightTheme {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',

    colorScheme: const ColorScheme.light(
      primary: AppColors.kMainColor,
      onPrimary: AppColors.kWhiteColor,
      secondary: AppColors.kMainColor,
      onSecondary: AppColors.kWhiteColor,
      error: AppColors.kError,
      onError: AppColors.kWhiteColor,
      surface: AppColors.kWhiteColor,
      onSurface: AppColors.kBlackColor,
    ),
    scaffoldBackgroundColor: AppColors.kWhiteColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.kWhiteColor,
      foregroundColor: AppColors.kBlackColor,
      elevation: 0,
      centerTitle: false,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.kBlackColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.kBlackColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.kBlackColor,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.kBlackColor,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.kBlackColor,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.kSubtitleColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.kBlackColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.kBlackColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.kSubtitleColor,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.kWhiteColor,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        color: AppColors.kGreyColor,
      ),
    ),

    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.kFormFieldColor,
    ),
  );
}
