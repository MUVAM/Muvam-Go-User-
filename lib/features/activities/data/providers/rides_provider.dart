import 'dart:async';
import 'package:flutter/material.dart';
import 'package:muvam/core/services/rides_service.dart';
import 'package:muvam/features/activities/data/models/ride_user.dart';

class RidesProvider with ChangeNotifier {
  final RidesService _ridesService = RidesService();

  List<Ride> _allRides = [];
  Ride? _selectedRide;
  bool _isLoading = false;
  bool _isLoadingDetails = false;
  String? _errorMessage;
  Timer? _refreshTimer;

  List<Ride> get allRides => _allRides;
  Ride? get selectedRide => _selectedRide;
  bool get isLoading => _isLoading;
  bool get isLoadingDetails => _isLoadingDetails;
  String? get errorMessage => _errorMessage;

  List<Ride> get prebookedRides =>
      _allRides.where((r) => r.isPrebooked).toList();
  List<Ride> get activeRides => _allRides.where((r) => r.isActive).toList();
  List<Ride> get historyRides => _allRides.where((r) => r.isHistory).toList();

  void startAutoRefresh() {
    fetchRides();
    _refreshTimer = Timer.periodic(Duration(seconds: 10), (_) {
      fetchRides();
    });
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> fetchRides({String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allRides = await _ridesService.getRides(status: status);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRideDetails(int rideId) async {
    _isLoadingDetails = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedRide = await _ridesService.getRideById(rideId);
      _isLoadingDetails = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoadingDetails = false;
      notifyListeners();
    }
  }

  void clearSelectedRide() {
    _selectedRide = null;
    notifyListeners();
  }

  String formatPrice(double price) {
    return '₦${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  String formatDateTime(String dateTime) {
    try {
      final dt = DateTime.parse(dateTime);
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'pm' : 'am';
      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at ${hour}:${minute} $period';
    } catch (e) {
      return dateTime;
    }
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
