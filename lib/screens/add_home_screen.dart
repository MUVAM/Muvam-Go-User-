import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/colors.dart';
import '../constants/images.dart';
import '../constants/text_styles.dart';
import '../services/places_service.dart';

class AddHomeScreen extends StatefulWidget {
  const AddHomeScreen({super.key});

  @override
  State<AddHomeScreen> createState() => _AddHomeScreenState();
}

class _AddHomeScreenState extends State<AddHomeScreen> {
  final List<String> recentLocations = [
    'Nsukka, Ogige',
    'Holy ghost Enugu',
    'Abakpa, Enugu',
  ];
  
  final PlacesService _placesService = PlacesService();
  final TextEditingController _searchController = TextEditingController();
  List<PlacePrediction> _locationSuggestions = [];
  bool _showSuggestions = false;
  String? _sessionToken;
  Position? _currentLocation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission != LocationPermission.denied) {
        Position position = await Geolocator.getCurrentPosition();
        setState(() {
          _currentLocation = position;
        });
      }
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
        currentLocation: _currentLocation,
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
    _searchController.text = prediction.description;
    setState(() {
      _locationSuggestions = [];
      _showSuggestions = false;
      _sessionToken = null;
    });
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
                      ConstImages.back, // Using avatar as placeholder for back icon
                      width: 24.w,
                      height: 24.h,
                    ),
                  ),
                 
                ],
              ),
            ),
            SizedBox(height:15.h),
             Text(
                    '    Add home',
                    style: ConstTextStyles.addHomeTitle,
                  ),
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
                  controller: _searchController,
                  onChanged: _searchLocations,
                  decoration: InputDecoration(
                    hintText: 'Search an address',
                    prefixIcon: Icon(Icons.search, size: 20.sp),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                  ),
                ),
              ),
            ),
            if (_showSuggestions && _locationSuggestions.isNotEmpty)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                constraints: BoxConstraints(maxHeight: 300.h),
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
                  shrinkWrap: true,
                  itemCount: _locationSuggestions.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final prediction = _locationSuggestions[index];
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.location_on, 
                        size: 20.sp, 
                        color: Color(ConstColors.mainColor)
                      ),
                      title: Text(
                        prediction.mainText,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: prediction.secondaryText.isNotEmpty ? Text(
                        prediction.secondaryText,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ) : null,
                      trailing: prediction.distance != null ? Text(
                        prediction.distance!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ) : null,
                      onTap: () => _selectLocation(prediction),
                    );
                  },
                ),
              ),
            SizedBox(height: 30.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Text(
                'Recent locations',
                style: ConstTextStyles.recentLocation.copyWith(
                  color: Color(ConstColors.recentLocationColor),
                ),
              ),
            ),
            SizedBox(height: 15.h),
            Divider(thickness: 1, color: Colors.grey.shade300),
            Expanded(
              child: ListView.separated(
                itemCount: recentLocations.length,
                separatorBuilder: (context, index) => Divider(thickness: 1, color: Colors.grey.shade300),
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Image.asset(
                      ConstImages.add,
                      width: 24.w,
                      height: 24.h,
                    ),
                    title: Text(
                      recentLocations[index],
                      style: ConstTextStyles.drawerItem,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}