import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

extension BuildContextExtensions on BuildContext {
  // Theme accessors
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  // MediaQuery accessors
  Size get screenSize => MediaQuery.of(this).size;
  Size get size => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  double get totalDeviceHeight => size.height;
  EdgeInsets get viewPadding => MediaQuery.of(this).viewPadding;
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;

  // Device size helpers
  double deviceHeight(double h) => size.height * h;
  double deviceWidth(double w) => size.width * w;

  // GoRouter Navigation helpers
  Future<T?> pushRoute<T extends Object?>(String route, {Object? extra}) {
    return push<T>(route, extra: extra);
  }

  Future<T?> pushNamedRoute<T extends Object?>(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) {
    return pushNamed<T>(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  void goRoute(String route, {Object? extra}) {
    go(route, extra: extra);
  }

  void goNamedRoute(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) {
    goNamed(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  // Legacy Navigator helpers (kept for compatibility)
  Future<dynamic> pushScreen(Widget screen) {
    return Navigator.of(this).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<dynamic> pushReplacement(Widget screen) {
    return Navigator.of(
      this,
    ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  Future<dynamic> pushNamedLegacy(String route, {Object? args}) {
    return Navigator.of(this).pushNamed(route, arguments: args);
  }

  Future<dynamic> pushNamedReplacement(String route, {Object? args}) {
    return Navigator.of(this).pushReplacementNamed(route, arguments: args);
  }

  Future<dynamic> pushNamedAndClear(String id, {Object? args}) {
    return Navigator.of(this).pushNamedAndRemoveUntil(
      id,
      (Route<dynamic> route) => false,
      arguments: args,
    );
  }

  Future<dynamic> pushNamedAndReplaceUntil(
    String route,
    String id, {
    Object? args,
  }) {
    return Navigator.of(
      this,
    ).pushNamedAndRemoveUntil(route, ModalRoute.withName(id), arguments: args);
  }

  void pop([Object? arg]) {
    if (canPop()) {
      Navigator.of(this).pop(arg);
    }
  }

  void popUntil(List<String> ids) {
    Navigator.of(this).popUntil((route) => ids.contains(route.settings.name));
  }

  T getArgs<T>() {
    return ModalRoute.of(this)?.settings.arguments as T;
  }
}

extension WidgetExtensions on Widget {
  Widget padAll(double padding) {
    return Padding(padding: EdgeInsets.all(padding), child: this);
  }

  Widget padSymmetric({double horizontal = 0, double vertical = 0}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      child: this,
    );
  }

  Widget padOnly({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: left,
        top: top,
        right: right,
        bottom: bottom,
      ),
      child: this,
    );
  }

  Widget center() {
    return Center(child: this);
  }

  Widget expanded({int flex = 1}) {
    return Expanded(flex: flex, child: this);
  }
}

extension StringExtensions on String {
  void logError({String? name}) {
    dev.log(this, name: name ?? 'App Log', level: 900);
  }

  void logInfo({String? name}) {
    dev.log(this, name: name ?? 'App Info', level: 800);
  }

  bool get isValidEmail {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(this);
  }

  bool get isValidPhone {
    return RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(this);
  }

  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$suffix';
  }
}

extension DateTimeExtensions on DateTime {
  String get formatDate {
    return '${year.toString()}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  String get formatTime {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String get formatDateTime {
    return '$formatDate $formatTime';
  }

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }
}

extension ListExtensions<T> on List<T> {
  T? get firstOrNull {
    return isEmpty ? null : first;
  }

  T? get lastOrNull {
    return isEmpty ? null : last;
  }
}
