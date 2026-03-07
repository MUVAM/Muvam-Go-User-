import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/app_routes.dart';
import 'package:muvam/core/constants/app_spacings.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/core/services/favourite_location_service.dart';
import 'package:muvam/core/services/places_service.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/home/data/models/favourite_location_models.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';
import 'package:muvam/layouts/presentation/shared/bottom_padding.dart';

class AddFavouriteScreen extends StatefulWidget {
  const AddFavouriteScreen({super.key});

  @override
  AddFavouriteScreenState createState() => AddFavouriteScreenState();
}

class AddFavouriteScreenState extends State<AddFavouriteScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final FavouriteLocationService _favouriteService = FavouriteLocationService();
  final PlacesService _placesService = PlacesService();
  bool _isLoading = false;
  List<PlacePrediction> _locationSuggestions = [];
  bool _showSuggestions = false;
  String? _sessionToken;
  Position? _userCurrentLocation;
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() => _userCurrentLocation = position);
    } catch (e) {
      AppLogger.log('Error getting location: $e');
    }
  }

  Future<void> _searchLocations(String query) async {
    if (query.length < 2) {
      setState(() {
        _locationSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    try {
      _sessionToken ??= DateTime.now().millisecondsSinceEpoch.toString();
      final predictions = await _placesService.getPlacePredictions(
        query,
        sessionToken: _sessionToken,
        currentLocation: _userCurrentLocation,
      );
      setState(() {
        _locationSuggestions = predictions;
        _showSuggestions = predictions.isNotEmpty;
      });
    } catch (e) {
      AppLogger.log('Error searching locations: $e');
      setState(() {
        _locationSuggestions = [];
        _showSuggestions = false;
      });
    }
  }

  void _selectLocation(PlacePrediction prediction) async {
    final placeDetails = await _placesService.getPlaceDetails(
      prediction.placeId,
      sessionToken: _sessionToken,
    );
    setState(() {
      _locationController.text = prediction.description;
      _selectedLocation = placeDetails != null
          ? LatLng(placeDetails.latitude, placeDetails.longitude)
          : null;
      _locationSuggestions = [];
      _showSuggestions = false;
      _sessionToken = null;
    });
  }

  Future<void> _saveFavouriteLocation() async {
    if (_nameController.text.trim().isEmpty) {
      CustomFlushbar.showInfo(
        context: context,
        message: 'Please enter a name for this location',
      );
      return;
    }
    if (_locationController.text.trim().isEmpty || _selectedLocation == null) {
      CustomFlushbar.showInfo(
        context: context,
        message: 'Please select a location',
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final request = FavouriteLocationRequest(
        destAddress: _locationController.text.trim(),
        destLocation:
            'POINT(${_selectedLocation!.latitude} ${_selectedLocation!.longitude})',
        name: _nameController.text.trim(),
      );
      await _favouriteService.addFavouriteLocation(request);
      CustomFlushbar.showSuccess(
        context: context,
        message: 'Favourite location added successfully',
      );
      context.pop(true);
    } catch (e) {
      AppLogger.log('Error saving favourite location: $e');
      CustomFlushbar.showError(
        context: context,
        message: 'Failed to add favourite location: ${e.toString()}',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showSuggestions = false),
      child: AppScaffold(
        backgroundColor: AppColors.kWhiteColor,
        appBar: AppBar(
          title: MuvamTexts.titleMedium18(
            context,
            text: 'Add Favourite Location',
            isTextWidget: true,
            fontWeight: FontWeight.w600,
          ),
          backgroundColor: AppColors.kWhiteColor,
          foregroundColor: AppColors.kBlackColor,
          elevation: 0,
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacings.k20),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter name for this location',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  prefixIcon: const Icon(Icons.label_outline),
                ),
              ),
              SizedBox(height: 20.h),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.kFieldColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: TextField(
                  controller: _locationController,
                  onChanged: _searchLocations,
                  decoration: InputDecoration(
                    hintText: 'Location',
                    prefixIcon: GestureDetector(
                      onTap: () async {
                        final result = await context.push(
                          AppRoutes.mapSelection.urlPath,
                          extra: {
                            'isFromField': false,
                            'initialLocation': _userCurrentLocation != null
                                ? LatLng(
                                    _userCurrentLocation!.latitude,
                                    _userCurrentLocation!.longitude,
                                  )
                                : const LatLng(9.0765, 7.3986),
                          },
                        );
                        if (result != null && result is Map<String, dynamic>) {
                          setState(() {
                            _locationController.text = result['address'];
                            _selectedLocation = result['location'];
                          });
                        }
                      },
                      child: Icon(Icons.map, color: AppColors.kMainColor),
                    ),
                    suffixIcon: _locationController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              setState(() {
                                _locationController.clear();
                                _selectedLocation = null;
                              });
                            },
                            child: const Icon(Icons.clear, color: Colors.grey),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 15.h,
                    ),
                  ),
                ),
              ),
              if (_showSuggestions && _locationSuggestions.isNotEmpty)
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(top: 10.h),
                    decoration: BoxDecoration(
                      color: AppColors.kWhiteColor,
                      borderRadius: BorderRadius.circular(8.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      itemCount: _locationSuggestions.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (context, index) {
                        final prediction = _locationSuggestions[index];
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.location_on,
                            size: 20.sp,
                            color: AppColors.kMainColor,
                          ),
                          title: MuvamTexts.bodyMedium14(
                            context,
                            text: prediction.mainText,
                            isTextWidget: true,
                            fontWeight: FontWeight.w600,
                          ),
                          subtitle: prediction.secondaryText.isNotEmpty
                              ? MuvamTexts.bodySmall12(
                                  context,
                                  text: prediction.secondaryText,
                                  isTextWidget: true,
                                  color: Colors.grey[600]!,
                                )
                              : null,
                          trailing: prediction.distance != null
                              ? MuvamTexts.bodySmall12(
                                  context,
                                  text: prediction.distance!,
                                  isTextWidget: true,
                                  color: Colors.grey[600]!,
                                  fontWeight: FontWeight.w500,
                                )
                              : null,
                          onTap: () => _selectLocation(prediction),
                        );
                      },
                    ),
                  ),
                ),
              if (!_showSuggestions) const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 47.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveFavouriteLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kMainColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: AppColors.kWhiteColor)
                      : MuvamTexts.button16(
                          context,
                          text: 'Save Favourite Location',
                          isTextWidget: true,
                          color: AppColors.kWhiteColor,
                        ),
                ),
              ),
              DeviceBottomPadding(),
            ],
          ),
        ),
      ),
    );
  }
}
