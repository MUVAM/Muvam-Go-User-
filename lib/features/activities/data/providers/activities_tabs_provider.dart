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
  bool _isRefreshing = false;
  bool _isLoadingDetails = false;
  String? _errorMessage;
  Timer? _pollingTimer;

  List<RideData> get prebookedRides => _prebookedRides;
  List<RideData> get activeRides => _activeRides;
  List<RideData> get historyRides => _historyRides;
  RideData? get selectedRide => _selectedRide;

  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingDetails => _isLoadingDetails;
  String? get errorMessage => _errorMessage;

  bool get hasData =>
      _prebookedRides.isNotEmpty ||
      _activeRides.isNotEmpty ||
      _historyRides.isNotEmpty;

  ActivitiesTabsProvider() {
    fetchRides();
    startPolling();
  }

  Future<void> fetchRides({bool isBackground = false}) async {
    // Only show loading spinner on first load when there's no data
    if (!isBackground && !hasData) {
      _isLoading = true;
    } else if (isBackground) {
      _isRefreshing = true;
    }

    _errorMessage = null;
    notifyListeners();

    try {
      AppLogger.log('Fetching rides from API (background: $isBackground)');

      // Fetch all rides in parallel for faster response
      final results = await Future.wait([
        _activitiesService.getPrebookedRides(),
        _activitiesService.getActiveRides(),
        _activitiesService.getHistoryRides(),
      ]);

      final prebookedResult = results[0];
      final activeResult = results[1];
      final historyResult = results[2];

      // Store previous counts to detect changes
      final previousActiveCount = _activeRides.length;
      final previousHistoryCount = _historyRides.length;

      // Fetch prebooked rides
      if (prebookedResult['success'] == true) {
        _prebookedRides = _parseRides(prebookedResult['data']);
        AppLogger.log('Prebooked rides: ${_prebookedRides.length}');
      } else {
        AppLogger.log('Prebooked rides failed: ${prebookedResult['message']}');
        if (!hasData) {
          _errorMessage = prebookedResult['message'];
        }
        _prebookedRides = [];
      }

      // Fetch active rides
      if (activeResult['success'] == true) {
        _activeRides = _parseRides(activeResult['data']);
        AppLogger.log('Active rides: ${_activeRides.length}');

        if (isBackground && _activeRides.length > previousActiveCount) {
          AppLogger.log('🚗 New active ride(s) detected!');
        }
      } else {
        AppLogger.log('Active rides failed: ${activeResult['message']}');
        if (!hasData) {
          _errorMessage = activeResult['message'];
        }
        _activeRides = [];
      }

      // Fetch history rides
      if (historyResult['success'] == true) {
        _historyRides = _parseRides(historyResult['data']);
        AppLogger.log('History rides: ${_historyRides.length}');

        // Log if new history rides detected
        if (isBackground && _historyRides.length > previousHistoryCount) {
          AppLogger.log('📜 New history ride(s) detected!');
        }
      } else {
        AppLogger.log('History rides failed: ${historyResult['message']}');
        if (!hasData) {
          _errorMessage = historyResult['message'];
        }
        _historyRides = [];
      }

      AppLogger.log('All rides fetched successfully');
    } catch (e) {
      _errorMessage = 'Error fetching rides: $e';
      AppLogger.log('Exception: $e');
      if (!hasData) {
        _prebookedRides = [];
        _activeRides = [];
        _historyRides = [];
      }
    } finally {
      _isLoading = false;
      _isRefreshing = false;
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

  void startPolling() {
    AppLogger.log('Starting automatic polling every 10 seconds');
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 10), // Poll every 10 seconds
      (_) => fetchRides(isBackground: true),
    );
  }

  void stopPolling() {
    AppLogger.log('Stopping automatic polling');
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // Pause polling when app is in background to save battery
  void pausePolling() {
    AppLogger.log('Pausing polling');
    _pollingTimer?.cancel();
  }

  // Resume polling when app comes to foreground
  void resumePolling() {
    AppLogger.log('Resuming polling');
    startPolling();
    fetchRides(isBackground: true); // Fetch immediately on resume
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
    stopPolling();
    super.dispose();
  }
}
