import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(String price) {
    if (price == '0' || price.isEmpty) return '0.00';
    double value = double.tryParse(price) ?? 0.0;
    final formatter = NumberFormat("#,##0.00", "en_US");
    return formatter.format(value);
  }
}
