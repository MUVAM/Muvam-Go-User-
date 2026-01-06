import 'package:flutter/material.dart';

extension StringExtensions on String {
  bool get isValidEmail {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(this);
  }

  bool get isValidPhone {
    return RegExp(
      r'^\+?[0-9]{10,15}$',
    ).hasMatch(replaceAll(RegExp(r'[\s-]'), ''));
  }

  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  bool get isNullOrEmpty => isEmpty;

  String get removeWhitespace => replaceAll(RegExp(r'\s+'), '');

  String get toSnakeCase {
    return replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    ).replaceFirst(RegExp('^_'), '');
  }

  String get toCamelCase {
    final words = split('_');
    if (words.isEmpty) return this;
    return words.first + words.skip(1).map((w) => w.capitalize).join();
  }
}

extension DateTimeExtensions on DateTime {
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

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else {
      return '${(difference.inDays / 365).floor()}y ago';
    }
  }

  String get smartFormat {
    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';
    if (isTomorrow) return 'Tomorrow';

    final now = DateTime.now();
    if (difference(now).inDays.abs() < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[weekday - 1];
    }

    return '$day/${month.toString().padLeft(2, '0')}/$year';
  }
}

extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  EdgeInsets get padding => MediaQuery.of(this).padding;
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;

  NavigatorState get navigator => Navigator.of(this);
  void pop<T>([T? result]) => Navigator.of(this).pop(result);

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }
}

extension DoubleExtensions on double {
  String toCurrency({String symbol = '\$'}) {
    return '$symbol${toStringAsFixed(2)}';
  }

  String toDistanceString() {
    if (this < 1000) {
      return '${toStringAsFixed(0)} m';
    }
    return '${(this / 1000).toStringAsFixed(1)} km';
  }

  String toPercentage() {
    return '${(this * 100).toStringAsFixed(0)}%';
  }

  double roundToDecimal(int places) {
    final mod = 10.0 * places;
    return (this * mod).round() / mod;
  }
}

extension ListExtensions<T> on List<T> {
  bool get isNullOrEmpty => isEmpty;

  T? get firstOrNull => isEmpty ? null : first;

  T? get lastOrNull => isEmpty ? null : last;
}

extension DurationExtensions on Duration {
  String get formatDuration {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String get tripFormat {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);

    if (hours > 0) {
      return '$hours hr $minutes min';
    }
    return '$minutes min';
  }
}
