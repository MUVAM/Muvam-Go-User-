import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:muvam/core/services/activities_service.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/features/activities/data/models/ride_data.dart';

class ActivitiesTabsProvider extends ChangeNotifier {
  final ActivitiesService _activitiesService = ActivitiesService();

  List<RideData> _prebookedRides = [];
  List<RideData> _activeRides = [];
  List<RideData> _historyRides = [];
  RideData? _selectedRide;

  bool _isLoading = false;
  bool _isLoadingDetails = false;
  String? _errorMessage;
  Timer? _refreshTimer;

  List<RideData> get prebookedRides => _prebookedRides;
  List<RideData> get activeRides => _activeRides;
  List<RideData> get historyRides => _historyRides;
  RideData? get selectedRide => _selectedRide;

  bool get isLoading => _isLoading;
  bool get isLoadingDetails => _isLoadingDetails;
  String? get errorMessage => _errorMessage;

  ActivitiesTabsProvider() {
    fetchRides();
  }

  Future<void> fetchRides() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      AppLogger.log('Fetching rides from API');

      bool hasError = false;

      // Fetch prebooked rides
      final prebookedResult = await _activitiesService.getPrebookedRides();
      if (prebookedResult['success'] == true) {
        _prebookedRides = _parseRides(prebookedResult['data']);
        AppLogger.log('Prebooked rides: ${_prebookedRides.length}');
      } else {
        AppLogger.log('Prebooked rides failed: ${prebookedResult['message']}');
        hasError = true;
        _prebookedRides = [];
      }

      // Fetch active rides
      final activeResult = await _activitiesService.getActiveRides();
      if (activeResult['success'] == true) {
        _activeRides = _parseRides(activeResult['data']);
        AppLogger.log('Active rides: ${_activeRides.length}');
      } else {
        AppLogger.log('Active rides failed: ${activeResult['message']}');
        hasError = true;
        _activeRides = [];
      }

      // Fetch history rides
      final historyResult = await _activitiesService.getHistoryRides();
      if (historyResult['success'] == true) {
        _historyRides = _parseRides(historyResult['data']);
        AppLogger.log('History rides: ${_historyRides.length}');
      } else {
        AppLogger.log('History rides failed: ${historyResult['message']}');
        hasError = true;
        _historyRides = [];
      }

      // Only set error if API calls failed, not if they're just empty
      if (hasError) {
        _errorMessage = 'Failed to load some rides';
      } else {
        _errorMessage = null;
        AppLogger.log('All rides fetched successfully');
      }
    } catch (e) {
      _errorMessage = 'Error fetching rides: $e';
      AppLogger.log('Exception: $e');
      _prebookedRides = [];
      _activeRides = [];
      _historyRides = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRideDetails(int rideId) async {
    _isLoadingDetails = true;
    _errorMessage = null;
    notifyListeners();

    try {
      AppLogger.log('Fetching ride details for ID: $rideId');

      final result = await _activitiesService.getRideDetails(rideId);

      if (result['success'] == true && result['data'] != null) {
        _selectedRide = RideData.fromJson(result['data']);
        _errorMessage = null;
      } else {
        AppLogger.log('Failed to fetch ride details: ${result['message']}');
        _errorMessage = result['message'] ?? 'Failed to fetch ride details';
        _selectedRide = null;
      }
    } catch (e) {
      _errorMessage = 'Error fetching ride details: $e';
      AppLogger.log('Exception in fetchRideDetails: $e');
      _selectedRide = null;
    } finally {
      _isLoadingDetails = false;
      notifyListeners();
    }
  }

  void clearSelectedRide() {
    _selectedRide = null;
    notifyListeners();
  }

  List<RideData> _parseRides(dynamic data) {
    try {
      List<dynamic> ridesJson = [];

      if (data is Map<String, dynamic>) {
        if (data.containsKey('rides') && data['rides'] is List) {
          ridesJson = data['rides'] as List<dynamic>;
          AppLogger.log('Parsed ${ridesJson.length} rides from map response');
        } else {
          AppLogger.log('Response is a map but has no rides array');
        }
      } else if (data is List) {
        ridesJson = data;
        AppLogger.log('Parsed ${ridesJson.length} rides from list response');
      } else {
        AppLogger.log('Unexpected data type: ${data.runtimeType}');
      }

      return ridesJson
          .map((json) {
            try {
              return RideData.fromJson(json);
            } catch (e) {
              AppLogger.log('Failed to parse ride: $e');
              return null;
            }
          })
          .whereType<RideData>()
          .toList();
    } catch (e) {
      AppLogger.log('Error parsing rides: $e');
      return [];
    }
  }

  void startAutoRefresh() {
    AppLogger.log('Starting auto-refresh');
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => fetchRides(),
    );
  }

  void stopAutoRefresh() {
    AppLogger.log('Stopping auto-refresh');
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  String formatPrice(double price) {
    return '₦${price.toStringAsFixed(2)}';
  }

  String formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final formatter = DateFormat('MMM dd, yyyy • hh:mm a');
      return formatter.format(dateTime);
    } catch (e) {
      AppLogger.log('Error formatting date: $e');
      return dateTimeStr;
    }
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
