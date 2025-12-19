import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:muvam/core/services/activities_service.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/features/activities/data/models/ride_data.dart';

class TabsRideProvider extends ChangeNotifier {
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

  TabsRideProvider() {
    fetchRides();
  }

  Future<void> fetchRides() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      AppLogger.log('🔄 Fetching rides from API...');

      // Fetch prebooked rides
      final prebookedResult = await _activitiesService.getPrebookedRides();
      if (prebookedResult['success'] == true &&
          prebookedResult['data'] != null) {
        _prebookedRides = _parseRides(prebookedResult['data']);
        AppLogger.log('✅ Prebooked: ${_prebookedRides.length} rides');
      } else {
        AppLogger.log(
          '⚠️ Prebooked rides failed: ${prebookedResult['message']}',
        );
        _prebookedRides = [];
      }

      // Fetch active rides
      final activeResult = await _activitiesService.getActiveRides();
      if (activeResult['success'] == true && activeResult['data'] != null) {
        _activeRides = _parseRides(activeResult['data']);
        AppLogger.log('✅ Active: ${_activeRides.length} rides');
      } else {
        AppLogger.log('⚠️ Active rides failed: ${activeResult['message']}');
        _activeRides = [];
      }

      // Fetch history rides
      final historyResult = await _activitiesService.getHistoryRides();
      if (historyResult['success'] == true && historyResult['data'] != null) {
        _historyRides = _parseRides(historyResult['data']);
        AppLogger.log('✅ History: ${_historyRides.length} rides');
      } else {
        AppLogger.log('⚠️ History rides failed: ${historyResult['message']}');
        _historyRides = [];
      }

      // Only set error if ALL requests failed
      if (_prebookedRides.isEmpty &&
          _activeRides.isEmpty &&
          _historyRides.isEmpty) {
        _errorMessage = 'No rides available';
      } else {
        _errorMessage = null;
      }
    } catch (e) {
      _errorMessage = 'Error fetching rides: $e';
      AppLogger.log('❌ Exception: $e');
      // Clear all rides on exception
      _prebookedRides = [];
      _activeRides = [];
      _historyRides = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch details for a specific ride by ID
  Future<void> fetchRideDetails(int rideId) async {
    _isLoadingDetails = true;
    _errorMessage = null;
    notifyListeners();

    try {
      AppLogger.log('🔄 Fetching ride details for ID: $rideId');

      final result = await _activitiesService.getRideDetails(rideId);

      if (result['success'] == true && result['data'] != null) {
        _selectedRide = RideData.fromJson(result['data']);
        AppLogger.log('✅ Successfully fetched ride details for ID: $rideId');
        _errorMessage = null;
      } else {
        AppLogger.log('⚠️ Failed to fetch ride details: ${result['message']}');
        _errorMessage = result['message'] ?? 'Failed to fetch ride details';
        _selectedRide = null;
      }
    } catch (e) {
      _errorMessage = 'Error fetching ride details: $e';
      AppLogger.log('❌ Exception in fetchRideDetails: $e');
      _selectedRide = null;
    } finally {
      _isLoadingDetails = false;
      notifyListeners();
    }
  }

  /// Clear the selected ride (useful when navigating away from details)
  void clearSelectedRide() {
    _selectedRide = null;
    notifyListeners();
  }

  List<RideData> _parseRides(dynamic data) {
    try {
      List<dynamic> ridesJson = [];

      if (data is Map<String, dynamic>) {
        // Response structure: {"rides": [...], "limit": 50, "offset": 0, "total": 74}
        if (data.containsKey('rides') && data['rides'] is List) {
          ridesJson = data['rides'] as List<dynamic>;
          AppLogger.log(
            '📦 Parsed ${ridesJson.length} rides from Map response',
          );
        }
      } else if (data is List) {
        // Response is directly a list
        ridesJson = data;
        AppLogger.log('📦 Parsed ${ridesJson.length} rides from List response');
      }

      return ridesJson
          .map((json) {
            try {
              return RideData.fromJson(json);
            } catch (e) {
              AppLogger.log('⚠️ Failed to parse ride: $e');
              return null;
            }
          })
          .whereType<RideData>() // Filter out null values
          .toList();
    } catch (e) {
      AppLogger.log('❌ Error parsing rides: $e');
      return [];
    }
  }

  void startAutoRefresh() {
    AppLogger.log('▶️ Starting auto-refresh (every 30 seconds)');
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => fetchRides(),
    );
  }

  void stopAutoRefresh() {
    AppLogger.log('⏸️ Stopping auto-refresh');
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
      AppLogger.log('⚠️ Error formatting date: $e');
      return dateTimeStr;
    }
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
