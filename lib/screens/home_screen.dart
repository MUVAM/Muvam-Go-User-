import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/colors.dart';
import '../constants/images.dart';
import '../constants/text_styles.dart';
import '../providers/location_provider.dart';
import '../providers/websocket_provider.dart';
import '../services/ride_service.dart';
import '../models/ride_models.dart';
import 'package:geocoding/geocoding.dart';
import 'add_home_screen.dart';
import 'add_favourite_screen.dart';
import 'tip_screen.dart';
import 'services_screen.dart';
import 'chat_screen.dart';
import 'activities_screen.dart';
import 'profile_screen.dart';
import 'wallet_screen.dart';
import 'referral_screen.dart';
import 'promo_code_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isBottomSheetVisible = true;
  bool _showDestinationField = false;
  int _currentIndex = 0;
  int? selectedVehicle;
  int? selectedDelivery;
  String selectedPaymentMethod = 'Pay in car';
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  int? selectedCancelReason;
  GoogleMapController? _mapController;
  LatLng _currentLocation = LatLng(6.8720015, 7.4069943); // Default location
  bool _isRideAccepted = false;
  bool _isDriverAssigned = false;
  String _driverArrivalTime = "5";
  bool _isInCar = false;
  String _driverDistance = "5 min";
  String _pickupLocation = "Your current location";
  String _dropoffLocation = "Destination";
  LatLng? _driverLocation;
  final RideService _rideService = RideService();
  List<String> _locationSuggestions = [];
  bool _showSuggestions = false;
  bool _isFromFieldFocused = false;
  RideEstimateResponse? _currentEstimate;
  bool _isLoadingEstimate = false;
  bool _isBookingRide = false;
  RideResponse? _currentRideResponse;
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LocationProvider>(context, listen: false).loadFavouriteLocations();
      final wsProvider = Provider.of<WebSocketProvider>(context, listen: false);
      wsProvider.connect();
      _listenToWebSocketMessages(wsProvider);
    });
  }

  void _listenToWebSocketMessages(WebSocketProvider wsProvider) {
    // Listen for ride accepted messages
    wsProvider.addListener(() {
      // This would be called when WebSocket receives messages
      // When driver accepts ride and DriverID is not null:
      // setState(() {
      //   _isDriverAssigned = true;
      //   _driverArrivalTime = "5"; // Set actual arrival time from WebSocket
      // });
    });
  }

  void _simulateRideAccepted() {
    setState(() {
      _isDriverAssigned = true;
      _isRideAccepted = true;
      _driverLocation = LatLng(
        _currentLocation.latitude + 0.01,
        _currentLocation.longitude + 0.01,
      );
      _driverDistance = _formatDistance(
        _calculateDistance(_currentLocation, _driverLocation!)
      );
      _pickupLocation = _currentRideResponse?.pickupAddress ?? 
          (fromController.text.isNotEmpty ? fromController.text : "Your current location");
      _dropoffLocation = _currentRideResponse?.destAddress ?? 
          (toController.text.isNotEmpty ? toController.text : "Destination");
    });
  }

  void _simulateInCar() {
    setState(() {
      _isRideAccepted = false;
      _isInCar = true;
    });
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
      // Create more comprehensive location suggestions
      List<String> suggestions = [];
      
      // Add common Nigerian locations that match the query
      List<String> commonLocations = [
        'Lagos, Nigeria',
        'Abuja, Nigeria', 
        'Port Harcourt, Nigeria',
        'Kano, Nigeria',
        'Ibadan, Nigeria',
        'Benin City, Nigeria',
        'Kaduna, Nigeria',
        'Jos, Nigeria',
        'Ilorin, Nigeria',
        'Enugu, Nigeria',
        'Aba, Nigeria',
        'Onitsha, Nigeria',
        'Warri, Nigeria',
        'Sokoto, Nigeria',
        'Calabar, Nigeria',
        'Uyo, Nigeria',
        'Akure, Nigeria',
        'Bauchi, Nigeria',
        'Minna, Nigeria',
        'Gombe, Nigeria',
        'Nsukka, Enugu',
        'Ikeja, Lagos',
        'Victoria Island, Lagos',
        'Lekki, Lagos',
        'Surulere, Lagos',
        'Yaba, Lagos',
        'Ajah, Lagos',
        'Ikoyi, Lagos',
        'Maryland, Lagos',
        'Gbagada, Lagos',
        'Festac, Lagos',
        'Alaba, Lagos',
        'Oshodi, Lagos',
        'Mushin, Lagos',
        'Agege, Lagos',
        'Ikorodu, Lagos',
        'Badagry, Lagos',
        'Epe, Lagos'
      ];
      
      // Filter locations based on query
      for (String location in commonLocations) {
        if (location.toLowerCase().contains(query.toLowerCase())) {
          suggestions.add(location);
        }
      }
      
      // Try geocoding for more specific results
      try {
        List<Location> locations = await locationFromAddress(query + ", Nigeria");
        for (Location location in locations.take(3)) {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            String address = '${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}'.replaceAll(RegExp(r'^,\s*|,\s*$'), '');
            if (address.isNotEmpty && !suggestions.contains(address)) {
              suggestions.add(address);
            }
          }
        }
      } catch (e) {
        // Geocoding failed, continue with filtered suggestions
      }
      
      setState(() {
        _locationSuggestions = suggestions.take(8).toList();
        _showSuggestions = suggestions.isNotEmpty;
      });
    } catch (e) {
      print('Error searching locations: $e');
      setState(() {
        _locationSuggestions = [];
        _showSuggestions = false;
      });
    }
  }

  void _selectLocation(String location, bool isFrom) {
    setState(() {
      if (isFrom) {
        fromController.text = location;
        _showDestinationField = true;
        _isFromFieldFocused = false;
      } else {
        toController.text = location;
      }
      _locationSuggestions = [];
      _showSuggestions = false;
    });
    
    // Save to recent locations
    Provider.of<LocationProvider>(context, listen: false)
        .addRecentLocation(location, location);
    
    // Only show vehicle selection after both fields are filled via selection
    if (!isFrom && fromController.text.isNotEmpty) {
      _checkBothFields();
    }
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
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  double _calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude, start.longitude,
      end.latitude, end.longitude,
    ) / 1000; // Convert to kilometers
  }

  String _formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  @override
  void dispose() {
    Provider.of<WebSocketProvider>(context, listen: false).disconnect();
    super.dispose();
  }

  void _showContactBottomSheet() {
    Navigator.pop(context); // Close drawer
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Contact us',
                  style: ConstTextStyles.addHomeTitle,
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, size: 24.sp),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            ListTile(
              leading: Image.asset(
                ConstImages.phoneCall,
                width: 22.w,
                height: 22.h,
              ),
              title: Text(
                'Via Call',
                style: ConstTextStyles.contactOption,
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 12.sp,
                color: Colors.grey,
              ),
            ),
            Divider(thickness: 1, color: Colors.grey.shade300),
            ListTile(
              leading: Image.asset(
                ConstImages.whatsapp,
                width: 22.w,
                height: 22.h,
              ),
              title: Text(
                'Via WhatsApp',
                style: ConstTextStyles.contactOption,
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 12.sp,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _dismissSuggestions() {
    setState(() {
      _showSuggestions = false;
      _locationSuggestions = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismissSuggestions,
      child: Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: Colors.white,
        selectedItemColor: Color(ConstColors.mainColor),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Image.asset(
              ConstImages.homeIcon,
              width: 24.w,
              height: 24.h,
              color: _currentIndex == 0 ? Color(ConstColors.mainColor) : Colors.grey,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              ConstImages.services,
              width: 24.w,
              height: 24.h,
              color: _currentIndex == 1 ? Color(ConstColors.mainColor) : Colors.grey,
            ),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              ConstImages.activities,
              width: 24.w,
              height: 24.h,
              color: _currentIndex == 2 ? Color(ConstColors.mainColor) : Colors.grey,
            ),
            label: 'Activities',
          ),
        ],
      ),
      body: _currentIndex == 1 ? const ServicesScreen() : _currentIndex == 2 ? ActivitiesScreen() : Stack(
        children: [
          // Google Maps background
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _currentLocation,
              zoom: 15.0,
            ),
            markers: {
              Marker(
                markerId: MarkerId('current_location'),
                position: _currentLocation,
                infoWindow: InfoWindow(title: 'Your Location'),
              ),
              if (_driverLocation != null)
                Marker(
                  markerId: MarkerId('driver_location'),
                  position: _driverLocation!,
                  infoWindow: InfoWindow(title: 'Driver'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          // Center widgets for pickup/dropoff
          Positioned(
            top: 270.h,
            left: 84.w,
            child: Column(
              children: [
                _buildPickupWidget(),
                if (_isDriverAssigned || _isInCar) _buildRouteLineWidget(),
                _buildDropoffWidget(),
                // if (!_isRideAccepted && !_isInCar)
                //   Image.asset(
                //     ConstImages.locationPin,
                //     width: 30.w,
                //     height: 30.h,
                //   ),
              ],
            ),
          ),
          // Drawer date
          Positioned(
            top: 66.h,
            left: 20.w,
            child: GestureDetector(
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              child: Container(
                width: 50.w,
                height: 50.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25.r),
                ),
                padding: EdgeInsets.all(10.w),
                child: Icon(Icons.menu, size: 24.sp),
              ),
            ),
          ),
          // Bottom sheet
          Positioned(
            bottom: _isBottomSheetVisible ? 0 : -294.h,
            left: 0,
            right: 0,
            child: Container(
              height: 344.h,
              width: 393.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isBottomSheetVisible = !_isBottomSheetVisible;
                        });
                      },
                      child: Container(
                        height: 50.h,
                        child: Column(
                          children: [
                            SizedBox(height: 11.75.h),
                            Container(
                              width: 69.w,
                              height: 5.h,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2.5.r),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: 20.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 14.w,
                              height: 14.h,
                              decoration: BoxDecoration(
                                color: Color(ConstColors.mainColor),
                                shape: BoxShape.circle,
                              ),
                            ),
                            if (_showDestinationField)
                              Column(
                                children: [
                                  SizedBox(height: 4.h),
                                  Container(
                                    width: 2.w,
                                    height: 4.h,
                                    color: Colors.red,
                                  ),
                                  SizedBox(height: 4.h),
                                  Container(
                                    width: 2.w,
                                    height: 4.h,
                                    color: Colors.red,
                                  ),
                                  SizedBox(height: 4.h),
                                  Container(
                                    width: 2.w,
                                    height: 4.h,
                                    color: Colors.red,
                                  ),
                                  SizedBox(height: 4.h),
                                  Container(
                                    width: 14.w,
                                    height: 14.h,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        SizedBox(width: 15.w),
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                width: 338.w,
                                height: 50.h,
                                decoration: BoxDecoration(
                                  color: Color(ConstColors.fieldColor).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: TextField(
                                  controller: fromController,
                                  onTap: () {
                                    setState(() {
                                      _showDestinationField = true;
                                      _isFromFieldFocused = true;
                                      _showSuggestions = false;
                                    });
                                  },
                                  onChanged: (value) {
                                    if (_isFromFieldFocused || !_showDestinationField) {
                                      _searchLocations(value);
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText: _showDestinationField ? 'From?' : 'Where to?',
                                    prefixIcon: Icon(Icons.search, size: 20.sp, color: Colors.grey),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                                  ),
                                ),
                              ),
                              if (_showDestinationField)
                                Column(
                                  children: [
                                    SizedBox(height: 10.h),
                                    Container(
                                      width: 338.w,
                                      height: 50.h,
                                      decoration: BoxDecoration(
                                        color: Color(ConstColors.fieldColor).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                      child: TextField(
                                        controller: toController,
                                        onTap: () {
                                          setState(() {
                                            _isFromFieldFocused = false;
                                          });
                                        },
                                        onChanged: (value) {
                                          _searchLocations(value);
                                        },
                                        decoration: InputDecoration(
                                          hintText: 'Where to?',
                                          prefixIcon: Icon(Icons.search, size: 20.sp, color: Colors.grey),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
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
                          final suggestion = _locationSuggestions[index];
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.location_on, 
                              size: 20.sp, 
                              color: Color(ConstColors.mainColor)
                            ),
                            title: Text(
                              suggestion,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            onTap: () => _selectLocation(suggestion, _isFromFieldFocused),
                          );
                        },
                      ),
                    ),
                  SizedBox(height: 15.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Saved location',
                        style: ConstTextStyles.savedLocation,
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Divider(thickness: 1, color: Colors.grey.shade300),
                  ListTile(
                    leading: Image.asset(
                      ConstImages.add,
                      width: 24.w,
                      height: 24.h,
                    ),
                    title: Text(
                      'Add home location',
                      style: ConstTextStyles.locationItem,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddHomeScreen()),
                      );
                    },
                  ),
                  Divider(thickness: 1, color: Colors.grey.shade300),
                  ListTile(
                    leading: Image.asset(
                      ConstImages.add,
                      width: 24.w,
                      height: 24.h,
                    ),
                    title: Text(
                      'Add work location',
                      style: ConstTextStyles.locationItem,
                    ),
                  ),
                  Divider(thickness: 1, color: Colors.grey.shade300),
                  ListTile(
                    leading: Image.asset(
                      ConstImages.add,
                      width: 24.w,
                      height: 24.h,
                    ),
                    title: Text(
                      'Add favourite location',
                      style: ConstTextStyles.locationItem,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddFavouriteScreen()),
                      );
                    },
                  ),
                  SizedBox(height: 15.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Recent locations',
                        style: ConstTextStyles.recentLocation.copyWith(
                          color: Color(ConstColors.recentLocationColor),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Divider(thickness: 1, color: Colors.grey.shade300),
                  Consumer<LocationProvider>(
                    builder: (context, locationProvider, child) {
                      final allLocations = <Widget>[];
                      
                      // Add favourite locations with star icon
                      for (final fav in locationProvider.favouriteLocations) {
                        allLocations.add(
                          Column(
                            children: [
                              ListTile(
                                leading: Image.asset(
                                  ConstImages.locationPin,
                                  width: 24.w,
                                  height: 24.h,
                                ),
                                title: Text(
                                  fav.name,
                                  style: ConstTextStyles.drawerItem1,
                                ),
                                subtitle: Text(
                                  fav.destAddress,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey,
                                  ),
                                ),
                                trailing: GestureDetector(
                                  onTap: () async {
                                    final success = await locationProvider.deleteFavouriteLocation(fav.id);
                                    if (success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Favourite removed')),
                                      );
                                    }
                                  },
                                  child: Icon(
                                    Icons.star,
                                    size: 20.sp,
                                    color: Colors.black,
                                  ),
                                ),
                                onTap: () {
                                  toController.text = fav.name;
                                  if (fromController.text.isNotEmpty) {
                                    _checkBothFields();
                                  }
                                },
                              ),
                              Divider(thickness: 1, color: Colors.grey.shade300),
                            ],
                          ),
                        );
                      }
                      
                      // Add recent locations without star
                      for (final recent in locationProvider.recentLocations) {
                        if (!recent.isFavourite) {
                          allLocations.add(
                            Column(
                              children: [
                                ListTile(
                                  leading: Image.asset(
                                    ConstImages.locationPin,
                                    width: 24.w,
                                    height: 24.h,
                                  ),
                                  title: Text(
                                    recent.name,
                                    style: ConstTextStyles.drawerItem1,
                                  ),
                                  subtitle: Text(
                                    recent.address,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  onTap: () {
                                    toController.text = recent.name;
                                    if (fromController.text.isNotEmpty) {
                                      _checkBothFields();
                                    }
                                  },
                                ),
                                if (allLocations.length < locationProvider.favouriteLocations.length + locationProvider.recentLocations.where((r) => !r.isFavourite).length)
                                  Divider(thickness: 1, color: Colors.grey.shade300),
                              ],
                            ),
                          );
                        }
                      }
                      
                      return Column(children: allLocations);
                    },
                  ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _checkBothFields() {
    if (fromController.text.length >= 3 && toController.text.length >= 3) {
      _showVehicleSelection();
    }
  }

  void _showVehicleSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: 600.h,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Container(
                width: 69.w,
                height: 5.h,
                margin: EdgeInsets.only(bottom: 20.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.5.r),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select your vehicle',
                    style: ConstTextStyles.addHomeTitle,
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, size: 24.sp),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Divider(thickness: 1, color: Colors.grey.shade300),
              SizedBox(height: 20.h),
              _buildVehicleOption(0, 'Regular vehicle', '20 min | 4 passengers', '₦12,000', setModalState),
              SizedBox(height: 15.h),
              _buildVehicleOption(1, 'Fancy vehicle', '20 min | 4 passengers', '₦12,000', setModalState),
              SizedBox(height: 15.h),
              _buildVehicleOption(2, 'VIP', '20 min | 4 passengers', '₦12,000', setModalState),
              SizedBox(height: 30.h),
              Text(
                'Delivery service',
                style: ConstTextStyles.deliveryTitle,
              ),
              SizedBox(height: 20.h),
              _buildDeliveryOption(0, 'Bicycle', '20 min', '₦12,000', ConstImages.bike, setModalState),
              SizedBox(height: 15.h),
              _buildDeliveryOption(1, 'Vehicle', '20 min', '₦12,000', ConstImages.car, setModalState),
              SizedBox(height: 15.h),
              _buildDeliveryOption(2, 'Motor bike', '20 min', '₦12,000', ConstImages.car, setModalState),
              SizedBox(height: 30.h),
              Container(
                width: 353.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: (selectedVehicle != null || selectedDelivery != null)
                      ? Color(ConstColors.mainColor)
                      : Color(ConstColors.fieldColor),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: GestureDetector(
                  onTap: (selectedVehicle != null || selectedDelivery != null) && !_isLoadingEstimate ? () async {
                    setModalState(() {
                      _isLoadingEstimate = true;
                    });
                    try {
                      await _estimateRide();
                      if (mounted) {
                        Navigator.pop(context);
                        _showBookingDetails();
                      }
                    } catch (e) {
                      print('Estimate error: $e');
                      if (mounted) {
                        Navigator.pop(context);
                        _showBookingDetails();
                      }
                    } finally {
                      if (mounted) {
                        setModalState(() {
                          _isLoadingEstimate = false;
                        });
                      }
                    }
                  } : null,
                  child: Center(
                    child: _isLoadingEstimate
                        ? SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Select vehicle',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleOption(int index, String title, String subtitle, String price, StateSetter setModalState) {
    final isSelected = selectedVehicle == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedVehicle = index;
          selectedDelivery = null;
        });
        setModalState(() {});
      },
      child: Container(
        width: 353.w,
        height: 65.h,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        decoration: BoxDecoration(
          color: isSelected ? Color(ConstColors.mainColor) : Colors.transparent,
          border: Border.all(
            color: isSelected ? Color(ConstColors.mainColor) : Colors.grey.shade300,
            width: 0.7,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Image.asset(
              ConstImages.car,
              width: 55.w,
              height: 26.h,
            ),
            SizedBox(width: 15.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: ConstTextStyles.vehicleTitle.copyWith(
                    color: isSelected ? Colors.white : Colors.black,
                  )),
                  Text(subtitle, style: ConstTextStyles.vehicleSubtitle.copyWith(
                    color: isSelected ? Colors.white : Colors.black,
                  )),
                ],
              ),
            ),
            Text(price, style: ConstTextStyles.vehicleTitle.copyWith(
              color: isSelected ? Colors.white : Colors.black,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryOption(int index, String title, String subtitle, String price, String imagePath, StateSetter setModalState) {
    final isSelected = selectedDelivery == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDelivery = index;
          selectedVehicle = null;
        });
        setModalState(() {});
      },
      child: Container(
        width: 353.w,
        height: 65.h,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        decoration: BoxDecoration(
          color: isSelected ? Color(ConstColors.mainColor) : Colors.transparent,
          border: Border.all(
            color: isSelected ? Color(ConstColors.mainColor) : Colors.grey.shade300,
            width: 0.7,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Image.asset(
              imagePath,
              width: 55.w,
              height: 26.h,
            ),
            SizedBox(width: 15.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: ConstTextStyles.vehicleTitle.copyWith(
                    color: isSelected ? Colors.white : Colors.black,
                  )),
                  Text(subtitle, style: ConstTextStyles.vehicleSubtitle.copyWith(
                    color: isSelected ? Colors.white : Colors.black,
                  )),
                ],
              ),
            ),
            Text(price, style: ConstTextStyles.vehicleTitle.copyWith(
              color: isSelected ? Colors.white : Colors.black,
            )),
          ],
        ),
      ),
    );
  }

  void _showBookingDetails() {
    // Reset booking state
    _isBookingRide = false;
    
    final selectedOption = selectedVehicle != null 
        ? ['Regular vehicle', 'Fancy vehicle', 'VIP'][selectedVehicle!]
        : ['Bicycle', 'Vehicle', 'Motor bike'][selectedDelivery!];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setBookingState) => Container(
          height: 400.h,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
            Container(
              width: 69.w,
              height: 5.h,
              margin: EdgeInsets.only(bottom: 20.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.5.r),
              ),
            ),
            GestureDetector(
              onTap: () => _showAddNoteSheet(),
              child: Column(
                children: [
                  Icon(Icons.message, size: 25.67.w),
                  SizedBox(height: 4.67.h),
                  Text(
                    'Add note',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w400,
                      height: 22 / 16,
                      letterSpacing: -0.41,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            Divider(thickness: 1, color: Colors.grey.shade300),
            SizedBox(height: 20.h),
            Row(
              children: [
                Image.asset(
                  selectedVehicle != null ? ConstImages.car : ConstImages.bike,
                  width: 55.w,
                  height: 26.h,
                ),
                SizedBox(width: 15.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(selectedOption, style: ConstTextStyles.vehicleTitle),
                      Text('4 passengers', style: ConstTextStyles.vehicleSubtitle),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _currentEstimate != null 
                          ? '${_currentEstimate!.currency}${_currentEstimate!.price.toStringAsFixed(0)}'
                          : '₦12,000', 
                      style: ConstTextStyles.vehicleTitle
                    ),
                    Text(
                      _currentEstimate != null 
                          ? '${_currentEstimate!.durationMin} min'
                          : 'Fixed', 
                      style: ConstTextStyles.fixedPrice.copyWith(
                        color: Color(ConstColors.recentLocationColor),
                      )
                    ),
                  ],
                ),
                SizedBox(width: 10.w),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _showVehicleSelection();
                  },
                  child: Icon(Icons.arrow_forward_ios, size: 16.sp),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Divider(thickness: 1, color: Colors.grey.shade300),
            SizedBox(height: 20.h),
            GestureDetector(
              onTap: () => _showPaymentMethods(),
              child: Row(
                children: [
                  Image.asset(
                    ConstImages.wallet,
                    width: 24.w,
                    height: 24.h,
                  ),
                  SizedBox(width: 15.w),
                  Expanded(
                    child: Text(selectedPaymentMethod, style: ConstTextStyles.vehicleTitle),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16.sp),
                ],
              ),
            ),
            Spacer(),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _showPrebookSheet();
                  },
                  child: Container(
                    width: 170.w,
                    height: 47.h,
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Color(ConstColors.mainColor)),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: Text(
                        'Book Later',
                        style: TextStyle(
                          color: Color(ConstColors.mainColor),
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                GestureDetector(
                  onTap: !_isBookingRide ? () async {
                    setBookingState(() {
                      _isBookingRide = true;
                    });
                    try {
                      _currentRideResponse = await _requestRide();
                      
                      final wsProvider = Provider.of<WebSocketProvider>(context, listen: false);
                      wsProvider.sendMessage({
                        'type': 'ride_request',
                        'data': _currentRideResponse!.toJson(),
                        'timestamp': DateTime.now().toIso8601String(),
                      });
                      
                      if (mounted) {
                        fromController.clear();
                        toController.clear();
                        setState(() {
                          _showDestinationField = false;
                        });
                        Navigator.pop(context);
                        _showBookingRequestSheet();
                      }
                    } catch (e) {
                      if (mounted) {
                        setBookingState(() {
                          _isBookingRide = false;
                        });
                      }
                    }
                  } : null,
                  child: Container(
                    width: 170.w,
                    height: 47.h,
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Color(ConstColors.mainColor),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: _isBookingRide
                          ? SizedBox(
                              width: 20.w,
                              height: 20.h,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Book Now',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentMethods() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 69.w,
              height: 5.h,
              margin: EdgeInsets.only(bottom: 20.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.5.r),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Choose payment method',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, size: 24.sp),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            _buildPaymentOption('Pay with wallet'),
            Divider(thickness: 1, color: Colors.grey.shade300),
            _buildPaymentOption('Pay with card'),
            Divider(thickness: 1, color: Colors.grey.shade300),
            _buildPaymentOption('pay4me'),
            Divider(thickness: 1, color: Colors.grey.shade300),
            _buildPaymentOption('Pay in car'),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String method) {
    final isSelected = selectedPaymentMethod == method;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPaymentMethod = method;
        });
        Navigator.pop(context);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 15.h),
        child: Row(
          children: [
            Expanded(
              child: Text(method, style: ConstTextStyles.vehicleTitle),
            ),
            if (isSelected)
              Icon(Icons.check, color: Colors.green, size: 20.sp),
          ],
        ),
      ),
    );
  }

  void _showAddNoteSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setNoteState) => Container(
          height: 300.h,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              Container(
                width: 69.w,
                height: 5.h,
                margin: EdgeInsets.only(bottom: 20.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.5.r),
                ),
              ),
              Text(
                'Add note',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 20.h),
              Container(
                width: 350.w,
                height: 111.h,
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Color(0xFFB1B1B1).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: TextField(
                  controller: noteController,
                  maxLines: null,
                  expands: true,
                  onChanged: (value) {
                    setNoteState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: 'Type your note here...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              Spacer(),
              Container(
                width: 353.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: noteController.text.isNotEmpty
                      ? Color(ConstColors.mainColor)
                      : Color(ConstColors.fieldColor),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: GestureDetector(
                  onTap: noteController.text.isNotEmpty ? () {
                    Navigator.pop(context);
                  } : null,
                  child: Center(
                    child: Text(
                      'Submit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          SizedBox(height: 60.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                Image.asset(
                  ConstImages.avatar,
                  width: 60.w,
                  height: 60.h,
                ),
                SizedBox(width: 15.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'John Doe',
                      style: ConstTextStyles.drawerName,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ProfileScreen()),
                        );
                      },
                      child: Text(
                        'My Account',
                        style: ConstTextStyles.drawerAccount.copyWith(
                          color: Color(ConstColors.drawerAccountColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          Divider(thickness: 1, color: Colors.grey.shade300),
          _buildDrawerItem('Book a trip', ConstImages.car),
          _buildDrawerItem('Activities', ConstImages.serviceEscort),
          _buildDrawerItem('Wallet', ConstImages.wallet, onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => WalletScreen()),
            );
          }),
          _buildDrawerItem('Drive with us', ConstImages.car),
          _buildDrawerItem('Tip', ConstImages.tip, onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TipScreen()),
            );
          }),
          _buildDrawerItem('Promo code', ConstImages.code, onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PromoCodeScreen()),
            );
          }),
          _buildDrawerItem('Referral', ConstImages.referral, onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ReferralScreen()),
            );
          }),
          _buildDrawerItem('Contact Us', ConstImages.phoneCall, onTap: _showContactBottomSheet),
          _buildDrawerItem('FAQ', ConstImages.faq),
          _buildDrawerItem('About', ConstImages.about),
        ],
      ),
    );
  }

  void _showPrebookSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setPrebookState) => Container(
          height: 450.h,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
              Container(
                width: 69.w,
                height: 5.h,
                margin: EdgeInsets.only(bottom: 20.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.5.r),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Prebook a vehicle',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Select time and date',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 20.h),
              Divider(thickness: 1, color: Colors.grey.shade300),
              ListTile(
                leading: Image.asset(
                  ConstImages.activities,
                  width: 24.w,
                  height: 24.h,                ),
                title: Text(
                  'Date',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    height: 1.0,
                    letterSpacing: -0.32,
                    color: Color(0xFFB1B1B1),
                  ),
                ),
                subtitle: Text(
                  '${_getWeekday(selectedDate.weekday)} ${_getMonth(selectedDate.month)} ${selectedDate.day}, ${selectedDate.year}',
                  style: ConstTextStyles.vehicleTitle,
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );
                  if (picked != null && picked != selectedDate) {
                    setPrebookState(() {
                      selectedDate = picked;
                    });
                  }
                },
              ),
              Divider(thickness: 1, color: Colors.grey.shade300),
              ListTile(
                leading: Image.asset(
                  'assets/images/time.png',
                  width: 24.w,
                  height: 24.h,
                ),
                title: Text(
                  'Time',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    height: 1.0,
                    letterSpacing: -0.32,
                    color: Color(0xFFB1B1B1),
                  ),
                ),
                subtitle: Text(
                  '${selectedTime.format(context)}',
                  style: ConstTextStyles.vehicleTitle,
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (picked != null && picked != selectedTime) {
                    setPrebookState(() {
                      selectedTime = picked;
                    });
                  }
                },
              ),
              SizedBox(height: 30.h),
              Column(
                children: [
                  Container(
                    width: 353.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Color(ConstColors.mainColor)),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        setPrebookState(() {
                          selectedDate = DateTime.now();
                          selectedTime = TimeOfDay.now();
                        });
                      },
                      child: Center(
                        child: Text(
                          'Reset to now',
                          style: TextStyle(
                            color: Color(ConstColors.mainColor),
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    width: 353.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: Color(ConstColors.mainColor),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _showTripScheduledSheet();
                      },
                      child: Center(
                        child: Text(
                          'Set pick date and time',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getWeekday(int weekday) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekdays[weekday - 1];
  }

  String _getMonth(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
                   'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }

  void _showBookingRequestSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        height: 380.h,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
            Container(
              width: 69.w,
              height: 5.h,
              margin: EdgeInsets.only(bottom: 20.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.5.r),
              ),
            ),
            Text(
              'Booking request successful',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'You\'ll receive a push notification when your driver is assigned.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                height: 1.0,
                letterSpacing: -0.32,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20.h),
            Divider(thickness: 1, color: Colors.grey.shade300),
            SizedBox(height: 20.h),
            Container(
              padding: EdgeInsets.all(15.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6.w,
                        height: 6.h,
                        decoration: BoxDecoration(
                          color: Color(ConstColors.mainColor),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'Pick Up',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          height: 1.0,
                          letterSpacing: -0.32,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 16.w),
                      child: Text(
                        _currentRideResponse?.pickupAddress ?? 'Pickup Location',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                          letterSpacing: -0.32,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 15.h),
                  Divider(thickness: 1, color: Colors.grey.shade300),
                  SizedBox(height: 15.h),
                  Row(
                    children: [
                      Container(
                        width: 6.w,
                        height: 6.h,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'Destination',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          height: 1.0,
                          letterSpacing: -0.32,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 16.w),
                      child: Text(
                        _currentRideResponse?.destAddress ?? 'Destination',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                          letterSpacing: -0.32,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            Container(
              width: 353.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: Color(ConstColors.mainColor),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _showBookSuccessfulSheet();
                  // Simulate ride acceptance after 3 seconds
                  Future.delayed(Duration(seconds: 3), () {
                    _simulateRideAccepted();
                  });
                },
                child: Center(
                  child: Text(
                    'View Trip',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
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

  void _showBookSuccessfulSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        height: 300.h,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          children: [
            Container(
              width: 69.w,
              height: 5.h,
              margin: EdgeInsets.only(bottom: 20.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.5.r),
              ),
            ),
            Text(
              'Book Successful',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                height: 1.0,
                letterSpacing: -0.32,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'We are searching for available nearby driver',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                height: 1.0,
                letterSpacing: -0.32,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20.h),
            Divider(thickness: 1, color: Colors.grey.shade300),
            SizedBox(height: 20.h),
            Container(
              width: 353.w,
              height: 10.h,
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(Color(ConstColors.mainColor)),
              ),
            ),
            Spacer(),
            Container(
              width: 353.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: Color(ConstColors.mainColor),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _showTripDetailsSheet();
                },
                child: Center(
                  child: Text(
                    'Trip Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTripDetailsSheet() {
    final selectedOption = _currentRideResponse?.vehicleType ?? 
        (selectedVehicle != null 
            ? ['Regular vehicle', 'Fancy vehicle', 'VIP'][selectedVehicle!]
            : ['Bicycle', 'Vehicle', 'Motor bike'][selectedDelivery!]);
    final currentDate = '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} at ${TimeOfDay.now().format(context)}';
    final paymentMethod = _currentRideResponse?.paymentMethod?.replaceAll('_', ' ')?.replaceAll('pay', 'Pay') ?? selectedPaymentMethod;
    final pickupAddr = _currentRideResponse?.pickupAddress ?? 'Pickup Location';
    final destAddr = _currentRideResponse?.destAddress ?? 'Destination';
    final vehicleType = _currentRideResponse?.vehicleType ?? selectedOption;
    final ridePrice = _currentRideResponse?.price?.toStringAsFixed(0) ?? '12,000';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        height: 600.h,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: 69.w,
                height: 5.h,
                margin: EdgeInsets.only(bottom: 20.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.5.r),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ID: #${_currentRideResponse?.id ?? '12345'}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, size: 24.sp, color: Colors.black),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Divider(thickness: 1, color: Colors.grey.shade300),
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.all(15.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6.w,
                          height: 6.h,
                          decoration: BoxDecoration(
                            color: Color(ConstColors.mainColor),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'Pick Up',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 16.w),
                        child: Text(
                          'Nsukka, Enugu',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 15.h),
                    Divider(thickness: 1, color: Colors.grey.shade300),
                    SizedBox(height: 15.h),
                    Row(
                      children: [
                        Container(
                          width: 6.w,
                          height: 6.h,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'Destination',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 16.w),
                        child: Text(
                          'Ikeja, Lagos',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Divider(thickness: 1, color: Colors.grey.shade300),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Text(
                    'Date',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                      letterSpacing: -0.32,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'November 28, 2025 at 03:45 pm',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                    letterSpacing: -0.32,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Divider(thickness: 1, color: Colors.grey.shade300),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Method',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          selectedPaymentMethod,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1.w,
                    height: 40.h,
                    color: Colors.grey.shade300,
                  ),
                  SizedBox(width: 20.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vehicle',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          selectedOption,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Divider(thickness: 1, color: Colors.grey.shade300),
              SizedBox(height: 20.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                        letterSpacing: -0.32,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      '₦${_currentRideResponse?.price?.toStringAsFixed(0) ?? '12,000'}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Container(
                width: 328.w,
                height: 50.h,
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {},
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit, size: 16.sp, color: Colors.black),
                            SizedBox(width: 8.w),
                            Text(
                              'Modify Trip',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w400,
                                height: 22 / 16,
                                letterSpacing: -0.41,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 1.w,
                      height: 30.h,
                      color: Colors.grey.shade300,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ChatScreen()),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat, size: 16.sp, color: Colors.black),
                            SizedBox(width: 8.w),
                            Text(
                              'Chat Driver',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w400,
                                height: 22 / 16,
                                letterSpacing: -0.41,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTripScheduledSheet() {
    final selectedOption = selectedVehicle != null 
        ? ['Regular vehicle', 'Fancy vehicle', 'VIP'][selectedVehicle!]
        : ['Bicycle', 'Vehicle', 'Motor bike'][selectedDelivery!];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        height: 500.h,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: 69.w,
                height: 5.h,
                margin: EdgeInsets.only(bottom: 20.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.5.r),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Trip scheduled',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Divider(thickness: 1, color: Colors.grey.shade300),
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.all(15.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6.w,
                          height: 6.h,
                          decoration: BoxDecoration(
                            color: Color(ConstColors.mainColor),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'Pick Up',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 16.w),
                        child: Text(
                          'Nsukka, Enugu',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 15.h),
                    Divider(thickness: 1, color: Colors.grey.shade300),
                    SizedBox(height: 15.h),
                    Row(
                      children: [
                        Container(
                          width: 6.w,
                          height: 6.h,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'Destination',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 16.w),
                        child: Text(
                          'Ikeja, Lagos',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Divider(thickness: 1, color: Colors.grey.shade300),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Text(
                    'Date',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                      letterSpacing: -0.32,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'November 28, 2025 at 03:45 pm',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                    letterSpacing: -0.32,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Divider(thickness: 1, color: Colors.grey.shade300),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Method',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          selectedPaymentMethod,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1.w,
                    height: 40.h,
                    color: Colors.grey.shade300,
                  ),
                  SizedBox(width: 20.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vehicle',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          selectedOption,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                            letterSpacing: -0.32,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Divider(thickness: 1, color: Colors.grey.shade300),
              SizedBox(height: 20.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                        letterSpacing: -0.32,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      '₦12,000',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30.h),
              Container(
                width: 353.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: Color(ConstColors.mainColor),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _showEditPrebookingSheet();
                  },
                  child: Center(
                    child: Text(
                      'Edit pre booking',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
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

  void _showEditPrebookingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        height: 600.h,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: 69.w,
                height: 5.h,
                margin: EdgeInsets.only(bottom: 20.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.5.r),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit pre booking',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, size: 24.sp, color: Colors.black),
                  ),
                ],
              ),
              SizedBox(height: 30.h),
              _buildEditField('PICK UP', 'Nsukka, Enugu'),
              SizedBox(height: 15.h),
              _buildEditField('DESTINATION', 'Ikeja, Lagos'),
              SizedBox(height: 15.h),
              _buildEditField('WHEN', 'November 28, 2025 at 03:45 pm'),
              SizedBox(height: 15.h),
              _buildEditField('PAYMENT METHOD', selectedPaymentMethod),
              SizedBox(height: 15.h),
              _buildEditField('VEHICLE', selectedVehicle != null 
                  ? ['Regular vehicle', 'Fancy vehicle', 'VIP'][selectedVehicle!]
                  : ['Bicycle', 'Vehicle', 'Motor bike'][selectedDelivery!]),
              SizedBox(height: 40.h),
              Column(
                children: [
                  Container(
                    width: 353.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _showTripCanceledSheet();
                      },
                      child: Center(
                        child: Text(
                          'Cancel prebooking',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 15.h),
                  Container(
                    width: 353.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: Color(ConstColors.mainColor),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Center(
                        child: Text(
                          'Save prebooking',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: 353.w,
          height: 50.h,
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          decoration: BoxDecoration(
            color: Color(0xFFB1B1B1).withOpacity(0.12),
            borderRadius: BorderRadius.circular(2.r),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showTripCanceledSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setCancelState) => Container(
          height: 450.h,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              Container(
                width: 69.w,
                height: 5.h,
                margin: EdgeInsets.only(bottom: 20.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.5.r),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Trip Canceled',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Help us improve by sharing why you are canceling',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    height: 1.0,
                    letterSpacing: -0.32,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 30.h),
              _buildCancelReason(0, 'I am taking alternative transport', setCancelState),
              SizedBox(height: 10.h),
              _buildCancelReason(1, 'It is taking too long to get a driver', setCancelState),
              SizedBox(height: 10.h),
              _buildCancelReason(2, 'I have to attend to something', setCancelState),
              SizedBox(height: 10.h),
              _buildCancelReason(3, 'Others', setCancelState),
              Spacer(),
              Container(
                width: 353.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: selectedCancelReason != null
                      ? Color(ConstColors.mainColor)
                      : Color(ConstColors.fieldColor),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: GestureDetector(
                  onTap: selectedCancelReason != null ? () {
                    Navigator.pop(context);
                    _showFeedbackSuccessSheet();
                  } : null,
                  child: Center(
                    child: Text(
                      'Submit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildCancelReason(int index, String reason, StateSetter setCancelState) {
    final isSelected = selectedCancelReason == index;
    return GestureDetector(
      onTap: () {
        setCancelState(() {
          selectedCancelReason = index;
        });
      },
      child: Container(
        width: 353.w,
        height: 40.h,
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: isSelected ? Color(ConstColors.mainColor) : Colors.white,
          border: Border.all(color: Color(ConstColors.mainColor)),
          borderRadius: BorderRadius.circular(15.r),
        ),
        child: Center(
          child: Text(
            reason,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  void _showFeedbackSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        height: 400.h,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          children: [
            Container(
              width: 69.w,
              height: 5.h,
              margin: EdgeInsets.only(bottom: 30.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.5.r),
              ),
            ),
            Container(
              width: 266.w,
              height: 212.h,
              margin: EdgeInsets.only(top: 30.h, left: 62.w),
              child: Image.asset(
                'assets/images/Feedback_suucess.png',
                fit: BoxFit.contain,
              ),
            ),
            Spacer(),
            Container(
              width: 353.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: Color(ConstColors.mainColor),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Center(
                  child: Text(
                    'GO HOME',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String title, String iconPath, {VoidCallback? onTap}) {
    return ListTile(
      leading: Image.asset(
        iconPath,
        width: 24.w,
        height: 24.h,
      ),
      title: Text(
        title,
        style: ConstTextStyles.drawerItem,
      ),
      onTap: onTap,
    );
  }

  Widget _buildPickupWidget() {
    // Only show when driver is actually assigned (DriverID is not null)
    if (!_isDriverAssigned || _currentRideResponse?.id == null) return SizedBox.shrink();
    
    return Container(
      width: 247.w,
      height: 50.h,
      padding: EdgeInsets.only( right:12.h,top:4, bottom:4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 50.w,
            height: 50.h,
            decoration: BoxDecoration(
              color: Color(ConstColors.mainColor),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Column(
                children: [
                  Text(
                    _driverArrivalTime,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),

             Text(
                    "MIN",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),     
                ],
              ),
            ),
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Driver arriving',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.41,
                  ),
                ),
                Text(
                  _pickupLocation,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.41,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16.sp),
        ],
      ),
    );
  }

  Widget _buildDropoffWidget() {
    if (!_isInCar) return SizedBox.shrink();
    
    return Container(
      width: 242.w,
      height: 48.h,
      padding: EdgeInsets.fromLTRB(22.w, 7.h, 22.w, 7.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Row(
        children: [
          Image.asset(
            ConstImages.locationIcon,
            width: 24.w,
            height: 24.h,
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Drop off',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.41,
                  ),
                ),
                Text(
                  _dropoffLocation,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.41,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16.sp),
        ],
      ),
    );
  }

  Widget _buildRouteLineWidget() {
    if (!_isDriverAssigned && !_isInCar) return SizedBox.shrink();
    
    return Container(
      width: 2.w,
      height: 30.h,
      color: Color(ConstColors.mainColor),
    );
  }

  Future<void> _estimateRide() async {
    final serviceType = selectedVehicle != null ? "taxi" : "delivery";
    final vehicleType = selectedVehicle != null 
        ? ["regular", "fancy", "vip"][selectedVehicle!]
        : ["bicycle", "vehicle", "motorbike"][selectedDelivery!];
    
    final request = RideEstimateRequest(
      pickup: "POINT(${_currentLocation.longitude} ${_currentLocation.latitude})",
      dest: "POINT(${_currentLocation.longitude} ${_currentLocation.latitude})",
      destAddress: toController.text,
      serviceType: serviceType,
      vehicleType: vehicleType,
    );
    
    _currentEstimate = await _rideService.estimateRide(request, vehicleType);
    setState(() {});
  }

  Future<RideResponse> _requestRide() async {
    final serviceType = selectedVehicle != null ? "taxi" : "delivery";
    final vehicleType = selectedVehicle != null 
        ? ["regular", "fancy", "vip"][selectedVehicle!]
        : ["bicycle", "vehicle", "motorbike"][selectedDelivery!];
    
    final request = RideRequest(
      pickup: "POINT(${_currentLocation.longitude} ${_currentLocation.latitude})",
      dest: "POINT(${_currentLocation.longitude} ${_currentLocation.latitude})",
      destAddress: toController.text,
      paymentMethod: selectedPaymentMethod.toLowerCase().replaceAll(' ', '_'),
      pickupAddress: fromController.text,
      serviceType: serviceType,
      vehicleType: vehicleType,
    );
    
    return await _rideService.requestRide(request);
  }
}