import 'package:flutter/material.dart';
import 'package:muvam/core/services/location_service.dart';
import 'package:muvam/features/trips/data/models/location_models.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();

  bool _isLoading = false;
  String? _errorMessage;
  List<FavouriteLocation> _favouriteLocations = [];
  List<RecentLocation> _recentLocations = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<FavouriteLocation> get favouriteLocations => _favouriteLocations;
  List<RecentLocation> get recentLocations => _recentLocations;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  Future<void> loadFavouriteLocations() async {
    _setLoading(true);
    _setError(null);

    try {
      _favouriteLocations = await _locationService.getFavouriteLocations();
      await _loadRecentLocations();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<bool> addFavouriteLocation(AddFavouriteRequest request) async {
    _setLoading(true);
    _setError(null);

    try {
      await _locationService.addFavouriteLocation(request);
      await loadFavouriteLocations();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> _loadRecentLocations() async {
    final recent = await _locationService.getRecentLocations();
    _recentLocations = recent.map((location) {
      final isFavourite = _favouriteLocations.any(
        (fav) => fav.name == location.name,
      );
      return RecentLocation(
        name: location.name,
        address: location.address,
        isFavourite: isFavourite,
      );
    }).toList();
  }

  Future<void> addRecentLocation(String name, String address) async {
    await _locationService.saveRecentLocation(name, address);
    await _loadRecentLocations();
    notifyListeners();
  }

  Future<bool> deleteFavouriteLocation(int favId) async {
    _setLoading(true);
    _setError(null);

    try {
      await _locationService.deleteFavouriteLocation(favId);
      await loadFavouriteLocations();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
}
