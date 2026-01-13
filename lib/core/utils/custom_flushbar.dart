import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:muvam/core/constants/colors.dart';

class CustomFlushbar {
  static void showSuccess({
    required BuildContext context,
    required String message,
    String title = "Success",
    Duration duration = const Duration(seconds: 3),
  }) {
    Flushbar(
      title: title,
      message: message,
      duration: duration,
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: Color(ConstColors.successColor),
      icon: const Icon(
        Icons.check_circle,
        color: Color(ConstColors.whiteColor),
      ),
    ).show(context);
  }

  static void showError({
    required BuildContext context,
    required String message,
    String title = "Error",
    Duration duration = const Duration(seconds: 5),
  }) {
    Flushbar(
      title: title,
      message: message,
      duration: duration,
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: Color(ConstColors.failureColor),
      icon: const Icon(Icons.error, color: Color(ConstColors.whiteColor)),
    ).show(context);
  }

  static void showInfo({
    required BuildContext context,
    required String message,
    String title = "Info",
    Duration duration = const Duration(seconds: 3),
  }) {
    Flushbar(
      title: title,
      message: message,
      duration: duration,
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: Color(ConstColors.failureColor),
      icon: const Icon(Icons.info, color: Color(ConstColors.whiteColor)),
    ).show(context);
  }

  static void showRegistrationSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    showSuccess(
      context: context,
      message: message,
      title: "Registration Successful",
      duration: duration,
    );
  }

  static void showRegistrationError({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 5),
  }) {
    showError(
      context: context,
      message: message,
      title: "Registration Failed",
      duration: duration,
    );
  }

  static void showOtpSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    showSuccess(
      context: context,
      message: message,
      title: "OTP Verified",
      duration: duration,
    );
  }

  static void showOtpResent({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    showInfo(
      context: context,
      message: message,
      title: "Code Resent",
      duration: duration,
    );
  }

  static void showConnected({
    required BuildContext context,
    Duration duration = const Duration(seconds: 2),
  }) {
    Flushbar(
      message: "Internet is connected",
      duration: duration,
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: Colors.green,
      icon: const Icon(Icons.wifi, color: Colors.white),
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
    ).show(context);
  }

  static void showDisconnected({
    required BuildContext context,
    Duration duration = const Duration(seconds: 3),
  }) {
    Flushbar(
      message: "No internet connection",
      duration: duration,
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: Colors.red,
      icon: const Icon(Icons.wifi_off, color: Colors.white),
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
    ).show(context);
  }
}
