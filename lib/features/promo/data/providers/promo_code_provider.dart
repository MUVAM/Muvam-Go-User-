import 'package:flutter/material.dart';
import 'package:muvam/core/services/promo_code_service.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/features/promo/data/models/promo_code_model.dart';

class PromoCodeProvider extends ChangeNotifier {
  final PromoCodeService _promoCodeService = PromoCodeService();

  PromoCodeValidation? _promoValidation;
  bool _isValidating = false;
  String? _errorMessage;
  String? _appliedPromoCode;

  PromoCodeValidation? get promoValidation => _promoValidation;
  bool get isValidating => _isValidating;
  String? get errorMessage => _errorMessage;
  String? get appliedPromoCode => _appliedPromoCode;
  bool get hasAppliedPromo => _appliedPromoCode != null;

  Future<bool> validatePromoCode(String code) async {
    _isValidating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      AppLogger.log('Validating promo code: $code');

      final result = await _promoCodeService.validatePromoCode(code);

      if (result['success'] == true && result['data'] != null) {
        _promoValidation = PromoCodeValidation.fromJson(result['data']);
        _appliedPromoCode = code.toUpperCase();
        _errorMessage = null;
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Invalid promo code';
        _promoValidation = null;
        _appliedPromoCode = null;
        AppLogger.log('Validation failed: $_errorMessage');
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      AppLogger.log('Exception: $e');
      _promoValidation = null;
      _appliedPromoCode = null;
      return false;
    } finally {
      _isValidating = false;
      notifyListeners();
    }
  }

  void clearPromoCode() {
    _promoValidation = null;
    _appliedPromoCode = null;
    _errorMessage = null;
    notifyListeners();
  }

  String formatPrice(double price) {
    return '₦${price.toStringAsFixed(0)}';
  }
}
