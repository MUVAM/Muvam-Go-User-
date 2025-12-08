import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/colors.dart';
import '../constants/images.dart';
import '../constants/text_styles.dart';
import '../services/favourite_location_service.dart';
import '../services/places_service.dart';
import '../models/favourite_location_models.dart';
import 'map_selection_screen.dart';

class AddFavouriteScreen extends StatefulWidget {
  @override
  _AddFavouriteScreenState createState() => _AddFavouriteScreenState();
}

class _AddFavouriteScreenState extends State<AddFavouriteScreen> {
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
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _userCurrentLocation = position;
      });
    } catch (e) {
      print('Error getting location: $e');
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
      print('Error searching locations: $e');
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a name for this location')),
      );
      return;
    }

    if (_locationController.text.trim().isEmpty || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a location')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = FavouriteLocationRequest(
        destAddress: _locationController.text.trim(),
        destLocation: 'POINT(${_selectedLocation!.latitude} ${_selectedLocation!.longitude})',
        name: _nameController.text.trim(),
      );

      print('🔄 Saving favourite location:');
      print('Name: ${request.name}');
      print('Address: ${request.destAddress}');
      print('Location: ${request.destLocation}');
      print('Request JSON: ${request.toJson()}');

      await _favouriteService.addFavouriteLocation(request);
      
      print('✅ Favourite location saved successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Favourite location added successfully')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      print('❌ Error saving favourite location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add favourite location: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showSuggestions = false;
        });
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Add Favourite Location'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter name for this location',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),
              SizedBox(height: 20.h),
              Container(
                decoration: BoxDecoration(
                  color: Color(ConstColors.fieldColor).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: TextField(
                  controller: _locationController,
                  onChanged: _searchLocations,
                  decoration: InputDecoration(
                    hintText: 'Location',
                    prefixIcon: GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MapSelectionScreen(
                              isFromField: false,
                              initialLocation: _userCurrentLocation != null
                                  ? LatLng(_userCurrentLocation!.latitude, _userCurrentLocation!.longitude)
                                  : LatLng(9.0765, 7.3986),
                            ),
                          ),
                        );
                        if (result != null) {
                          setState(() {
                            _locationController.text = result['address'];
                            _selectedLocation = result['location'];
                          });
                        }
                      },
                      child: Icon(Icons.map, color: Color(ConstColors.mainColor)),
                    ),
                    suffixIcon: _locationController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              setState(() {
                                _locationController.clear();
                                _selectedLocation = null;
                              });
                            },
                            child: Icon(Icons.clear, color: Colors.grey),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 15.h),
                  ),
                ),
              ),
              if (_showSuggestions && _locationSuggestions.isNotEmpty)
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(top: 10.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      itemCount: _locationSuggestions.length,
                      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (context, index) {
                        final prediction = _locationSuggestions[index];
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.location_on,
                            size: 20.sp,
                            color: Color(ConstColors.mainColor),
                          ),
                          title: Text(
                            prediction.mainText,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: prediction.secondaryText.isNotEmpty
                              ? Text(
                                  prediction.secondaryText,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey[600],
                                  ),
                                )
                              : null,
                          trailing: prediction.distance != null
                              ? Text(
                                  prediction.distance!,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              : null,
                          onTap: () => _selectLocation(prediction),
                        );
                      },
                    ),
                  ),
                ),
              if (!_showSuggestions) Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveFavouriteLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(ConstColors.mainColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Save Favourite Location',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}