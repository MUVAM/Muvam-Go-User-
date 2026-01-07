import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/text_styles.dart';
import 'package:muvam/core/services/favourite_location_service.dart';
import 'package:muvam/core/services/places_service.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/home/data/models/favourite_location_models.dart';
import 'package:muvam/features/home/presentation/screens/map_picker_screen.dart';

class AddHomeScreen extends StatefulWidget {
  final String locationType;

  const AddHomeScreen({super.key, this.locationType = 'home'});

  @override
  State<AddHomeScreen> createState() => _AddHomeScreenState();
}

class _AddHomeScreenState extends State<AddHomeScreen> {
  final TextEditingController _addressController = TextEditingController();
  final FavouriteLocationService _favouriteService = FavouriteLocationService();
  final PlacesService _placesService = PlacesService();

  List<PlacePrediction> _predictions = [];
  bool _isSaving = false;
  bool _showPredictions = false;
  LatLng? _selectedLocation;
  String? _sessionToken;

  String get _title {
    switch (widget.locationType.toLowerCase()) {
      case 'work':
        return 'Add work';
      case 'favourite':
        return 'Add favourite';
      case 'home':
      default:
        return 'Add home';
    }
  }

  String get _locationName {
    switch (widget.locationType.toLowerCase()) {
      case 'work':
        return 'Work Location';
      case 'favourite':
        return 'Favourite Location';
      case 'home':
      default:
        return 'Home Location';
    }
  }

  @override
  void initState() {
    super.initState();
    _sessionToken = DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _predictions = [];
        _showPredictions = false;
      });
      return;
    }

    try {
      final predictions = await _placesService.getPlacePredictions(
        query,
        sessionToken: _sessionToken,
      );

      setState(() {
        _predictions = predictions;
        _showPredictions = true;
      });
    } catch (e) {
      AppLogger.log('Error searching places: $e');
    }
  }

  Future<void> _selectPrediction(PlacePrediction prediction) async {
    try {
      final placeDetails = await _placesService.getPlaceDetails(
        prediction.placeId,
        sessionToken: _sessionToken,
      );

      if (placeDetails != null) {
        setState(() {
          _addressController.text = prediction.description;
          _selectedLocation = LatLng(
            placeDetails.latitude,
            placeDetails.longitude,
          );
          _showPredictions = false;
        });

        _sessionToken = DateTime.now().millisecondsSinceEpoch.toString();
      }
    } catch (e) {
      CustomFlushbar.showError(
        context: context,
        message: 'Could not get location details',
      );
    }
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerScreen()),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _addressController.text = result['address'];
        _selectedLocation = LatLng(result['latitude'], result['longitude']);
      });
    }
  }

  Future<void> _saveLocation() async {
    if (_addressController.text.isEmpty) {
      CustomFlushbar.showError(
        context: context,
        message: 'Please enter or select an address',
      );
      return;
    }

    if (_selectedLocation == null) {
      CustomFlushbar.showError(
        context: context,
        message: 'Please select a location from suggestions or map',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final destLocation =
          'POINT(${_selectedLocation!.longitude} ${_selectedLocation!.latitude})';

      final request = FavouriteLocationRequest(
        name: _locationName,
        destLocation: destLocation,
        destAddress: _addressController.text,
      );

      await _favouriteService.addFavouriteLocation(request);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      CustomFlushbar.showError(
        context: context,
        message: 'Failed to save location: $e',
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset(
                      ConstImages.back,
                      width: 30.w,
                      height: 30.h,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 15.h),
            Text('    $_title', style: ConstTextStyles.addHomeTitle),
            SizedBox(height: 30.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                width: 353.w,
                height: 50.h,
                decoration: BoxDecoration(
                  color: Color(ConstColors.fieldColor).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    hintText: 'Search an address',
                    prefixIcon: Icon(Icons.search, size: 20.sp),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.map, size: 20.sp),
                      onPressed: _openMapPicker,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 8.h,
                    ),
                  ),
                  onChanged: _searchPlaces,
                ),
              ),
            ),
            SizedBox(height: 10.h),
            if (_showPredictions && _predictions.isNotEmpty)
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 5.h,
                  ),
                  itemCount: _predictions.length,
                  separatorBuilder: (context, index) =>
                      Divider(thickness: 1, color: Colors.grey.shade300),
                  itemBuilder: (context, index) {
                    final prediction = _predictions[index];
                    return ListTile(
                      leading: Icon(
                        Icons.location_on,
                        color: Color(ConstColors.mainColor),
                      ),
                      title: Text(
                        prediction.mainText,
                        style: ConstTextStyles.drawerItem1,
                      ),
                      subtitle: Text(
                        prediction.secondaryText,
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                      ),
                      onTap: () => _selectPrediction(prediction),
                    );
                  },
                ),
              )
            else
              Spacer(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(ConstColors.mainColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Save Location',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
