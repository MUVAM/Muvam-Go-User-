import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/text_styles.dart';
import 'package:muvam/core/services/call_service.dart';
import 'package:muvam/core/services/directions_service.dart';
import 'package:muvam/core/services/favourite_location_service.dart';
import 'package:muvam/core/services/message_notification_handler.dart';
import 'package:muvam/core/services/payment_service.dart';
import 'package:muvam/core/services/places_service.dart';
import 'package:muvam/core/services/ride_service.dart';
import 'package:muvam/core/services/websocket_service.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/activities/presentation/screens/activities_screen.dart';
import 'package:muvam/features/chat/data/models/chat_model.dart';
import 'package:muvam/features/chat/data/providers/chat_provider.dart';
import 'package:muvam/features/chat/presentation/screens/call_screen.dart';
import 'package:muvam/features/chat/presentation/screens/chat_screen.dart';
import 'package:muvam/features/home/data/models/favourite_location_models.dart';
import 'package:muvam/features/home/data/models/ride_models.dart';
import 'package:muvam/features/home/presentation/widgets/app_drawer.dart';
import 'package:muvam/features/profile/data/providers/user_profile_provider.dart';
import 'package:muvam/features/promo/presentation/screens/promo_code_screen.dart';
import 'package:muvam/features/services/presentation/screens/services_screen.dart';
import 'package:muvam/features/wallet/data/providers/wallet_provider.dart';
import 'package:muvam/features/wallet/presentation/screens/wallet_empty_screen.dart';
import 'package:muvam/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:muvam/shared/presentation/screens/payment_webview_screen.dart';
import 'package:muvam/shared/presentation/screens/tip_screen.dart';
import 'package:muvam/shared/providers/location_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'add_home_screen.dart';
import 'map_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isBottomSheetVisible = true;
  bool _showDestinationField = false;
  bool _showStopField = false; // Controls stop address visibility

  Map<String, dynamic>? _incomingCall;
  final CallService _callService = CallService();
  int _currentIndex = 0;
  int? selectedVehicle;
  int? selectedDelivery;
  String selectedPaymentMethod = 'Pay in car';
  DateTime? _lastBackPress;
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();
  final TextEditingController stopController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  int? selectedCancelReason;
  bool isScheduledRide = false; // Track if booking is scheduled
  GoogleMapController? _mapController;
  LatLng _currentLocation = LatLng(6.8720015, 7.4069943); // Default location
  BitmapDescriptor? _driverIcon;
  BitmapDescriptor? _currentLocationIcon;
  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _destinationIcon;
  LatLng? _pickupCoordinates;
  LatLng? _destinationCoordinates;
  LatLng? _stopCoordinates;
  Set<Marker> _mapMarkers = {};
  Set<Polyline> _mapPolylines = {};
  final String _estimatedTime = '5';
  bool _isRideAccepted = false;
  bool _isDriverAssigned = false;
  String _driverArrivalTime = "5";
  bool _isInCar = false;
  final String _driverDistance = "5 min";
  String _pickupLocation = "Your current location";
  String _dropoffLocation = "Destination";
  LatLng? _driverLocation;
  Timer? _driverLocationTimer;
  BitmapDescriptor? _carIcon;
  final RideService _rideService = RideService();
  final PaymentService _paymentService = PaymentService();
  final DirectionsService _directionsService = DirectionsService();
  List<PlacePrediction> _locationSuggestions = [];
  bool _showSuggestions = false;
  bool _isFromFieldFocused = false;
  final PlacesService _placesService = PlacesService();
  String? _sessionToken;
  Position? _userCurrentLocation;
  bool _isFromFieldEditable = false;
  bool _showMapTooltip = false;
  bool _isLocationLoaded = false;
  RideEstimateResponse? _currentEstimate;
  final bool _isLoadingEstimate = false;
  bool _isBookingRide = false;
  RideResponse? _currentRideResponse;
  Driver? _assignedDriver;
  WebSocketService _webSocketService = WebSocketService.instance;
  final FavouriteLocationService _favouriteService = FavouriteLocationService();
  List<FavouriteLocation> _favouriteLocations = [];
  Map<String, dynamic>? _activeRide;
  Timer? _activeRideCheckTimer;
  bool _isActiveRideSheetVisible = false;
  bool _hasUserDismissedSheet = false;
  int? _lastCompletedRideId;
  final Set<int> _dismissedRatingRides = {};
  Timer? _etaUpdateTimer;
  bool _hasInitializedMapCamera = false;
  final bool _userIsInteractingWithMap = false;

  @override
  void initState() {
    super.initState();
    // Get WebSocket instance
    _webSocketService = WebSocketService.instance;

    _getCurrentLocation();
    _forceUpdateLocation();
    _createDriverIcon();
    _createCarIcon();
    _createCurrentLocationIcon();
    _createPickupIcon();
    _createDestinationIcon();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();

      Provider.of<LocationProvider>(
        context,
        listen: false,
      ).loadFavouriteLocations();
      _loadFavouriteLocations();

      // Set up call handler BEFORE connecting
      // _setupCallHandler();

      AppLogger.log(
        '✅ Call handler set BEFORE connect: ${_webSocketService.onIncomingCall != null}',
        tag: 'HOME_INIT',
      );

      // NOW connect WebSocket - handler is already set
      AppLogger.log(
        '🔌 Connecting WebSocket from HomeScreen...',
        tag: 'HOME_INIT',
      );

      _webSocketService.connect().then((_) {
        AppLogger.log('✅ WebSocket connected', tag: 'HOME_INIT');

        // Set up OTHER message listeners (not call handler!)
        _setupOtherWebSocketListeners();
      });

      _checkActiveRides();
      _startActiveRideChecking();
    });
  }

  Map<String, dynamic>?
  _incomingOffer; // NEW: Store incoming offer for CallScreen

  void _setupOtherWebSocketListeners() {
    AppLogger.log(
      '🎧 Setting up other WebSocket listeners...',
      tag: 'HOME_WEBSOCKET',
    );

    // Call handler is already set before connection - don't overwrite it!
    AppLogger.log(
      '🔍 Verifying call handler still exists: ${_webSocketService.onIncomingCall != null}',
      tag: 'HOME_WEBSOCKET',
    );

    // Chat messages
    _webSocketService.onChatMessage = (chatData) {
      AppLogger.log('💬 Global chat handler called in HomeScreen');
      _handleGlobalChatMessage(chatData);
    };

    // Ride accepted
    _webSocketService.onRideAccepted = (data) {
      AppLogger.log('🎉 Ride accepted callback triggered!');

      // Extract driver information from WebSocket data
      final driverData = data['driver'] ?? {};
      _assignedDriver = Driver(
        id: driverData['id']?.toString() ?? 'driver_123',
        name: driverData['name']?.toString() ?? 'Driver',
        profilePicture: driverData['profile_picture']?.toString() ?? '',
        phoneNumber: driverData['phone_number']?.toString() ?? '',
        rating: (driverData['rating'] ?? 4.5).toDouble(),
        vehicleModel: driverData['vehicle_model']?.toString() ?? 'Vehicle',
        plateNumber: driverData['plate_number']?.toString() ?? 'N/A',
      );

      setState(() {
        _isDriverAssigned = true;
        _isRideAccepted = true;
        _driverArrivalTime = data['estimated_arrival']?.toString() ?? '5';
        _pickupLocation =
            _currentRideResponse?.pickupAddress ?? "Your current location";
        _dropoffLocation = _currentRideResponse?.destAddress ?? "Destination";

        if (data['driver_location'] != null) {
          final location = data['driver_location'];
          _driverLocation = LatLng(
            location['latitude']?.toDouble() ??
                _currentLocation.latitude + 0.01,
            location['longitude']?.toDouble() ??
                _currentLocation.longitude + 0.01,
          );
        }
      });

      _showDriverAcceptedSheet();
    };

    // Ride completed
    _webSocketService.onRideCompleted = (data) {
      AppLogger.log(
        '🏁 Ride completed callback triggered!',
        tag: 'RIDE_COMPLETED',
      );

      try {
        int? rideId;

        if (data['ride_id'] != null) {
          rideId = data['ride_id'] is int
              ? data['ride_id']
              : int.tryParse(data['ride_id'].toString());
        }

        if (rideId == null) {
          final messageData = data['data'] as Map<String, dynamic>?;
          if (messageData?['ride_id'] != null) {
            rideId = messageData!['ride_id'] is int
                ? messageData['ride_id']
                : int.tryParse(messageData['ride_id'].toString());
          }
        }

        if (rideId != null && !_dismissedRatingRides.contains(rideId)) {
          _lastCompletedRideId = rideId;

          String price = '0.00';
          // Try to get price from active ride if matches
          if (_activeRide != null &&
              (_activeRide!['ID'] == rideId ||
                  _activeRide!['ID'].toString() == rideId.toString())) {
            price = _activeRide!['Price']?.toString() ?? '0.00';
          }
          // Fallback to data payload
          else if (data['amount'] != null) {
            price = data['amount'].toString();
          } else if (data['data'] != null && data['data']['amount'] != null) {
            price = data['data']['amount'].toString();
          }

          if (mounted) {
            _showTripCompleteSheet(rideId, price);
          }
        }
      } catch (e) {
        AppLogger.log('❌ Error processing ride_completed message: $e');
      }
    };

    AppLogger.log(
      '✅ Non-call WebSocket listeners setup complete',
      tag: 'HOME_WEBSOCKET',
    );
    AppLogger.log(
      '🔍 Final handler check: ${_webSocketService.onIncomingCall != null}',
      tag: 'HOME_WEBSOCKET',
    );
  }

  Future<void> _initializeCallService() async {
    AppLogger.log(
      '🔧 Initializing call service for passenger...',
      tag: 'PASSENGER_CALL',
    );

    // IMPORTANT: Don't set up duplicate call handlers here
    // The global handler in main.dart will handle incoming calls
    await _callService.initialize();

    AppLogger.log(
      '✅ Call service initialized for passenger (no duplicate handlers)',
      tag: 'PASSENGER_CALL',
    );
  }

  Future<void> _createDriverIcon() async {
    _driverIcon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(48, 48)),
      ConstImages.locationPin,
    );
    setState(() {});
  }

  Future<void> _createCarIcon() async {
    AppLogger.log('🚗 === CREATING CAR ICON ===', tag: 'CAR_ICON');
    try {
      _carIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(150, 150)),
        'assets/images/car.png',
      );
      AppLogger.log('✅ Car icon created successfully', tag: 'CAR_ICON');
      setState(() {});
    } catch (e) {
      AppLogger.error('❌ Failed to create car icon', error: e, tag: 'CAR_ICON');
    }
  }

  Future<void> _createCurrentLocationIcon() async {
    _currentLocationIcon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(48, 48)),
      ConstImages.locationPin,
    );
    setState(() {});
  }

  Future<void> _createPickupIcon() async {
    _pickupIcon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(48, 48)),
      ConstImages.locationIconPin,
    );
    setState(() {});
  }

  Future<void> _createDestinationIcon() async {
    _destinationIcon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(48, 48)),
      ConstImages.locationPin,
    );
    setState(() {});
  }

  // Method to convert widget to BitmapDescriptor
  Future<BitmapDescriptor> _createBitmapDescriptorFromWidget(
    Widget widget, {
    Size? size,
  }) async {
    final GlobalKey globalKey = GlobalKey();

    final Widget wrappedWidget = MediaQuery(
      data: MediaQueryData(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: globalKey,
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: size?.width,
              height: size?.height,
              child: widget,
            ),
          ),
        ),
      ),
    );

    // Create a temporary overlay to render the widget
    late OverlayEntry overlayEntry;
    final Completer<BitmapDescriptor> completer = Completer<BitmapDescriptor>();

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: -1000, // Position off-screen
        top: -1000,
        child: wrappedWidget,
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    // Wait for the widget to be rendered
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await Future.delayed(Duration(milliseconds: 100));

        final RenderRepaintBoundary boundary =
            globalKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary;

        final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
        final ByteData? byteData = await image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        final Uint8List pngBytes = byteData!.buffer.asUint8List();

        overlayEntry.remove();
        completer.complete(BitmapDescriptor.fromBytes(pngBytes));
      } catch (e) {
        overlayEntry.remove();
        completer.completeError(e);
      }
    });

    return completer.future;
  }

  // Widget for pickup marker
  Widget _buildPickupMarkerWidget() {
    return Container(
      width: 247.w,
      height: 50.h,
      padding: EdgeInsets.only(right: 12.w, top: 4.h, bottom: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50.w,
            height: 50.h,
            decoration: BoxDecoration(
              color: _isDriverAssigned
                  ? Color(ConstColors.mainColor)
                  : Colors.white,
              shape: BoxShape.circle,
              border: _isDriverAssigned
                  ? null
                  : Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Center(
              child: _isDriverAssigned
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _driverArrivalTime,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          "MIN",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                      ],
                    )
                  : Icon(
                      Icons.location_on,
                      color: Color(ConstColors.mainColor),
                      size: 24.sp,
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
                  'Pick up',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.41,
                    color: Colors.black,
                  ),
                ),
                Text(
                  _activeRide?['PickupAddress']?.toString() ??
                      (fromController.text.isNotEmpty
                          ? fromController.text
                          : 'Current location'),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.41,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget for drop-off marker
  Widget _buildDropoffMarkerWidget() {
    return Container(
      width: 242.w,
      height: 48.h,
      padding: EdgeInsets.fromLTRB(10.w, 7.h, 10.w, 7.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30.w,
            height: 30.h,
            decoration: BoxDecoration(
              color: Color(ConstColors.mainColor),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_on, color: Colors.white, size: 20.sp),
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
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.41,
                    color: Colors.black,
                  ),
                ),
                Text(
                  _activeRide?['DestAddress']?.toString() ??
                      (toController.text.isNotEmpty
                          ? toController.text
                          : 'Destination'),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.41,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget for stop marker
  Widget _buildStopMarkerWidget() {
    String stopText = _activeRide?['StopAddress']?.toString() ?? 'Stop';

    return Container(
      width: 200.w,
      height: 40.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stop_circle, color: Colors.white, size: 16.sp),
          SizedBox(width: 4.w),
          Expanded(
            child: Text(
              stopText,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadFavouriteLocations() async {
    AppLogger.log('🔄 Loading favourite locations on home screen...');
    try {
      _favouriteLocations = await _favouriteService.getFavouriteLocations();
      AppLogger.log(
        '✅ Loaded ${_favouriteLocations.length} favourite locations:',
      );
      for (final fav in _favouriteLocations) {
        AppLogger.log('  - ${fav.name}: ${fav.destAddress}');
      }
      setState(() {});
    } catch (e) {
      AppLogger.log('❌ Error loading favourite locations: $e');
    }
  }

  void _listenToWebSocketMessages() {
    // CRITICAL: Ensure WebSocket connects AFTER call handler is set up
    AppLogger.log(
      '🔌 Setting up WebSocket message listeners...',
      tag: 'HOME_WEBSOCKET',
    );

    _webSocketService.onChatMessage = (chatData) {
      AppLogger.log('💬 Global chat handler called in HomeScreen');
      _handleGlobalChatMessage(chatData);
    };

    // NEW: Send "Hello" message to open WebSocket channel
    if (_activeRide != null) {
      AppLogger.log(
        '📤 Sending initialization message to open WebSocket channel...',
      );
      Future.delayed(Duration(seconds: 3), () {
        if (_webSocketService.isConnected) {
          _webSocketService.sendMessage({
            "type": "chat",
            "data": {"ride_id": _activeRide!['ID'], "message": "Hello"},
          });
          AppLogger.log('✅ Initialization message sent');
        }
      });
    }

    _webSocketService.onRideAccepted = (data) {
      AppLogger.log('🎉 Ride accepted callback triggered!');
      AppLogger.log('Driver data: $data');

      // Extract driver information from WebSocket data
      final driverData = data['driver'] ?? {};
      _assignedDriver = Driver(
        id: driverData['id']?.toString() ?? 'driver_123',
        name: driverData['name']?.toString() ?? 'Driver',
        profilePicture: driverData['profile_picture']?.toString() ?? '',
        phoneNumber: driverData['phone_number']?.toString() ?? '',
        rating: (driverData['rating'] ?? 4.5).toDouble(),
        vehicleModel: driverData['vehicle_model']?.toString() ?? 'Vehicle',
        plateNumber: driverData['plate_number']?.toString() ?? 'N/A',
      );

      setState(() {
        _isDriverAssigned = true;
        _isRideAccepted = true;
        _driverArrivalTime = data['estimated_arrival']?.toString() ?? '5';
        _pickupLocation =
            _currentRideResponse?.pickupAddress ?? "Your current location";
        _dropoffLocation = _currentRideResponse?.destAddress ?? "Destination";

        // Set driver location if provided
        if (data['driver_location'] != null) {
          final location = data['driver_location'];
          _driverLocation = LatLng(
            location['latitude']?.toDouble() ??
                _currentLocation.latitude + 0.01,
            location['longitude']?.toDouble() ??
                _currentLocation.longitude + 0.01,
          );
        }
      });

      // Show driver accepted sheet
      _showDriverAcceptedSheet();
    };

    // Listen for ride_completed message
    _webSocketService.onRideCompleted = (data) {
      AppLogger.log(
        '🏁 Ride completed callback triggered!',
        tag: 'RIDE_COMPLETED',
      );
      AppLogger.log(
        'RAW MESSAGE AS STRING FOR PASSENGER: "${data.toString()}"',
      );

      try {
        // Parse ride_id from the message (can be at root level or in data)
        int? rideId;

        // Try to get ride_id from root level first
        if (data['ride_id'] != null) {
          rideId = data['ride_id'] is int
              ? data['ride_id']
              : int.tryParse(data['ride_id'].toString());
        }

        // If not found, try from data object
        if (rideId == null) {
          final messageData = data['data'] as Map<String, dynamic>?;
          if (messageData?['ride_id'] != null) {
            rideId = messageData!['ride_id'] is int
                ? messageData['ride_id']
                : int.tryParse(messageData['ride_id'].toString());
          }
        }

        AppLogger.log('Parsed Ride ID: $rideId');
        AppLogger.log('Last completed ride ID: $_lastCompletedRideId');
        AppLogger.log('Dismissed rides: $_dismissedRatingRides');

        if (rideId != null && !_dismissedRatingRides.contains(rideId)) {
          AppLogger.log('✅ Showing rating sheet for ride $rideId');

          // Store the ride ID
          _lastCompletedRideId = rideId;

          // Show rating sheet
          if (mounted) {
            _showRatingSheet();
          }
        } else {
          AppLogger.log(
            '⚠️ Not showing rating - rideId: $rideId, already dismissed: ${_dismissedRatingRides.contains(rideId ?? -1)}',
          );
        }
      } catch (e) {
        AppLogger.log('❌ Error processing ride_completed message: $e');
      }
    };

    AppLogger.log(
      '✅ WebSocket message listeners setup complete',
      tag: 'HOME_WEBSOCKET',
    );
  }

  // Add this new method to handle global chat messages
  void _handleGlobalChatMessage(Map<String, dynamic> chatData) async {
    try {
      AppLogger.log('📨 Processing global chat message');
      final data = chatData['data'] ?? {};
      final messageText = data['message'] ?? '';
      final senderName = data['sender_name'] ?? 'Unknown User';
      final senderImage = data['sender_image'];
      final senderId = data['sender_id']?.toString() ?? '';
      final rideId = data['ride_id'] ?? 0;
      final timestamp =
          chatData['timestamp'] ?? DateTime.now().toIso8601String();

      AppLogger.log('   Message: "$messageText"');
      AppLogger.log('   From: $senderName (ID: $senderId)');
      AppLogger.log('   Ride: $rideId');

      // Get current user ID to check if this is our own message
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('user_id');

      AppLogger.log('   Current User ID: $currentUserId');
      AppLogger.log('   Sender ID: $senderId');

      // Add message to ChatProvider so it's available when user opens ChatScreen
      if (mounted && rideId > 0) {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        final message = ChatMessageModel(
          message: messageText,
          timestamp: timestamp,
          rideId: rideId,
          userId: senderId,
        );

        chatProvider.addMessage(rideId, message);
        AppLogger.log('✅ Message added to ChatProvider');

        // Only show notification if the message is NOT from the current user
        if (senderId != currentUserId &&
            senderId.isNotEmpty &&
            currentUserId != null) {
          AppLogger.log('📢 Showing notification (message from other user)');

          // Show notification
          ChatNotificationService.showChatNotification(
            context,
            senderName: senderName,
            message: messageText,
            senderImage: senderImage,
            onTap: () {
              AppLogger.log('🔔 Notification tapped, navigating to chat');

              // Navigate to chat screen
              if (_activeRide != null) {
                // final passenger = _activeRide!['Passenger'] ?? {};
                final passengerName = _assignedDriver!.name;
                final passengerImage = _assignedDriver!.profilePicture;
                final passengerId = _assignedDriver!.id;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      rideId: rideId,
                      driverName: passengerName,
                      driverImage: passengerImage,
                      driverId: passengerId,
                      driverPhone: _assignedDriver?.phoneNumber,
                    ),
                  ),
                );
              } else {
                // Fallback if no active ride
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      rideId: rideId,
                      driverId: senderId,
                      driverName: senderName,
                      driverImage: senderImage,
                      driverPhone: _assignedDriver?.phoneNumber,
                    ),
                  ),
                );
              }
            },
          );
        } else {
          AppLogger.log('🔇 Skipping notification (message from current user)');
        }
      }
    } catch (e, stack) {
      AppLogger.log('❌ Error handling global chat message: $e');
      AppLogger.log('Stack: $stack');
    }
  }

  Future<void> _checkActiveRides() async {
    AppLogger.log('=== CHECKING ACTIVE RIDES ===');
    try {
      final result = await _rideService.getActiveRides();
      AppLogger.log('Active rides result: $result');

      if (result['success'] == true) {
        final data = result['data'];
        final rides = data['rides'] as List? ?? [];
        AppLogger.log('Number of active rides: ${rides.length}');

        if (rides.isNotEmpty) {
          final activeRide = rides.first;
          AppLogger.log('Active ride found: $activeRide');
          AppLogger.log('Ride Status: ${activeRide['Status']}');
          AppLogger.log('Ride ID: ${activeRide['ID']}');

          setState(() {
            _activeRide = activeRide;
          });

          // Show active ride UI based on status
          _handleActiveRideStatus(activeRide);
        } else {
          AppLogger.log('No active rides found');
          setState(() {
            _activeRide = null;
          });
        }
      } else {
        AppLogger.log('Failed to get active rides: ${result['message']}');
      }
    } catch (e) {
      AppLogger.log('Error checking active rides: $e');
    }
    AppLogger.log('=== END CHECKING ACTIVE RIDES ===\n');
  }

  void _startActiveRideChecking() {
    // Check for active rides every 8 seconds
    _activeRideCheckTimer = Timer.periodic(Duration(seconds: 8), (timer) {
      _checkActiveRides();
    });
  }

  void _handleActiveRideStatus(Map<String, dynamic> ride) {
    final status = ride['Status']?.toString().toLowerCase() ?? '';
    final rideId = ride['ID'] as int?;
    AppLogger.log('Handling active ride with status: $status');

    // Store ride ID when active
    if (rideId != null &&
        (status == 'accepted' || status == 'arrived' || status == 'started')) {
      _lastCompletedRideId = rideId;
    }

    switch (status) {
      case 'accepted':
      case 'arrived':
      case 'started':
        // Extract driver and ride information
        final driverData = ride['Driver'] ?? {};
        if (driverData.isNotEmpty) {
          // Extract vehicle information from Vehicles array
          final vehicles = driverData['Vehicles'] as List?;
          final vehicleData = (vehicles != null && vehicles.isNotEmpty)
              ? vehicles[0]
              : null;

          // Build vehicle model string from Make, ModelType, Year, and Color
          String vehicleModel = 'Vehicle';
          if (vehicleData != null) {
            final make = vehicleData['Make']?.toString().trim() ?? '';
            final modelType = vehicleData['ModelType']?.toString().trim() ?? '';
            final year = vehicleData['Year']?.toString() ?? '';
            final color = vehicleData['Color']?.toString().trim() ?? '';

            // Combine: "Make ModelType Year Color" (e.g., "Honda Modelo 2024 White")
            vehicleModel = [
              make,
              modelType,
              year,
              color,
            ].where((part) => part.isNotEmpty).join(' ');

            if (vehicleModel.isEmpty) {
              vehicleModel = 'Vehicle';
            }
          }

          // Get license plate from vehicle data
          final licensePlate =
              vehicleData?['LicensePlate']?.toString() ?? 'N/A';

          _assignedDriver = Driver(
            id: driverData['ID']?.toString() ?? 'driver_${ride['DriverID']}',
            name:
                '${driverData['first_name'] ?? 'Driver'} ${driverData['last_name'] ?? ''}',
            profilePicture: driverData['profile_photo']?.toString() ?? '',
            phoneNumber: driverData['phone']?.toString() ?? '',
            rating: (driverData['average_rating'] ?? 4.5).toDouble(),
            vehicleModel: vehicleModel,
            plateNumber: licensePlate,
          );
        }

        setState(() {
          _isDriverAssigned = true;
          _isRideAccepted = true;
          _pickupLocation = ride['PickupAddress'] ?? "Pickup location";
          _dropoffLocation = ride['DestAddress'] ?? "Destination";

          if (status == 'started') {
            _isInCar = true;
          }
        });

        // Parse PostGIS locations and add markers to map
        AppLogger.log('📍 Parsing PostGIS locations...');
        AppLogger.log('PickupLocation: ${ride['PickupLocation']}');
        AppLogger.log('DestLocation: ${ride['DestLocation']}');

        // Add pickup and drop-off markers to map
        _addActiveRideMarkers(ride);

        // Start tracking driver location if ride is accepted
        AppLogger.log(
          '🔍 Checking ride status for tracking: $status',
          tag: 'RIDE_STATUS',
        );

        if (status == 'accepted') {
          AppLogger.log(
            '✅ Status is ACCEPTED - Starting driver location tracking',
            tag: 'RIDE_STATUS',
          );
          _startDriverLocationTracking();
        } else if (status == 'arrived' || status == 'started') {
          AppLogger.log(
            '🏁 Status is $status - Stopping driver location tracking',
            tag: 'RIDE_STATUS',
          );
          // Stop tracking when driver arrives or trip starts
          _stopDriverLocationTracking();
        } else {
          AppLogger.log(
            '⚠️ Unexpected status: $status - No tracking action taken',
            tag: 'RIDE_STATUS',
          );
        }

        // Show appropriate UI only if not already visible and user hasn't dismissed
        if (status == 'started') {
          // Show in-car UI
        } else if (!_isActiveRideSheetVisible && !_hasUserDismissedSheet) {
          AppLogger.log('✅ Showing driver accepted sheet for status: $status');
          _showDriverAcceptedSheet();
        } else {
          AppLogger.log(
            '⚠️ Sheet not shown - Already visible: $_isActiveRideSheetVisible, User dismissed: $_hasUserDismissedSheet',
          );
        }
        break;

      case 'completed':
        // Check if passenger has rated
        if (_lastCompletedRideId != null &&
            !_dismissedRatingRides.contains(_lastCompletedRideId)) {
          _checkAndShowRating(_lastCompletedRideId!);
        }
        break;

      case 'cancelled':
        // Clear active ride state and map markers
        _stopDriverLocationTracking();
        setState(() {
          _activeRide = null;
          _isDriverAssigned = false;
          _isRideAccepted = false;
          _isInCar = false;
          _assignedDriver = null;
          _mapMarkers = {};
          _mapPolylines = {};
        });
        break;

      default:
        AppLogger.log('Unknown ride status: $status');
    }
  }

  void _simulateInCar() {
    setState(() {
      _isRideAccepted = false;
      _isInCar = true;
    });
  }

  /// Start tracking driver location and updating ETA
  void _startDriverLocationTracking() {
    AppLogger.log(
      '🚗 ========== STARTING DRIVER LOCATION TRACKING ==========',
      tag: 'DRIVER_TRACKING',
    );

    // Cancel any existing timer
    _driverLocationTimer?.cancel();
    _etaUpdateTimer?.cancel();

    AppLogger.log(
      '⏰ Setting up timer to update every 5 seconds',
      tag: 'DRIVER_TRACKING',
    );

    // Update driver location every 5 seconds
    _driverLocationTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      AppLogger.log(
        '⏰ Timer tick - updating driver location',
        tag: 'DRIVER_TRACKING',
      );
      _updateDriverLocation();
    });

    // Initial update
    AppLogger.log(
      '🔄 Performing initial driver location update',
      tag: 'DRIVER_TRACKING',
    );
    _updateDriverLocation();
  }

  /// Stop tracking driver location
  void _stopDriverLocationTracking() {
    AppLogger.log(
      '🛑 ========== STOPPING DRIVER LOCATION TRACKING ==========',
      tag: 'DRIVER_TRACKING',
    );
    _driverLocationTimer?.cancel();
    _etaUpdateTimer?.cancel();
    _driverLocationTimer = null;
    _etaUpdateTimer = null;
  }

  /// Update driver location from active ride data
  Future<void> _updateDriverLocation() async {
    AppLogger.log(
      '📍 === UPDATE DRIVER LOCATION CALLED ===',
      tag: 'DRIVER_LOCATION',
    );

    if (_activeRide == null) {
      AppLogger.log(
        '⚠️ No active ride found, stopping tracking',
        tag: 'DRIVER_LOCATION',
      );
      _stopDriverLocationTracking();
      return;
    }

    AppLogger.log(
      '✅ Active ride exists, fetching latest ride data...',
      tag: 'DRIVER_LOCATION',
    );

    try {
      // Fetch latest ride data to get updated driver location
      final response = await _rideService.getActiveRides();

      AppLogger.log(
        '📥 Response received: ${response['success']}',
        tag: 'DRIVER_LOCATION',
      );

      // Check if rides are in response['rides'] or response['data']['rides']
      List? rides;
      if (response['rides'] != null) {
        rides = response['rides'] as List;
      } else if (response['data'] != null &&
          response['data']['rides'] != null) {
        rides = response['data']['rides'] as List;
      }

      AppLogger.log(
        '📊 Rides found: ${rides != null}, Number of rides: ${rides?.length ?? 0}',
        tag: 'DRIVER_LOCATION',
      );

      if (response['success'] == true && rides != null) {
        AppLogger.log(
          '📊 Number of rides: ${rides.length}',
          tag: 'DRIVER_LOCATION',
        );

        if (rides.isNotEmpty) {
          final ride = rides[0];
          final status = ride['Status']?.toString().toLowerCase() ?? '';

          AppLogger.log('🎯 Ride status: $status', tag: 'DRIVER_LOCATION');

          // Only track location when driver is on the way (accepted status)
          if (status == 'accepted') {
            AppLogger.log(
              '✅ Status is accepted, checking for driver data...',
              tag: 'DRIVER_LOCATION',
            );

            final driverData = ride['Driver'];
            if (driverData != null && driverData['Location'] != null) {
              final driverLocationStr = driverData['Location'].toString();

              AppLogger.log(
                '📍 Driver location (raw): $driverLocationStr',
                tag: 'DRIVER_LOCATION',
              );

              // Parse driver location from WKB format
              final driverCoords = _parsePostGISPoint(driverLocationStr);

              if (driverCoords != null) {
                AppLogger.log(
                  '✅ Driver coords parsed: lat=${driverCoords.latitude}, lng=${driverCoords.longitude}',
                  tag: 'DRIVER_LOCATION',
                );

                setState(() {
                  _driverLocation = driverCoords;
                });

                AppLogger.log(
                  '🗺️ Updating driver marker on map...',
                  tag: 'DRIVER_LOCATION',
                );

                // Update driver marker on map
                _updateDriverMarker(driverCoords);

                AppLogger.log('⏱️ Calculating ETA...', tag: 'DRIVER_LOCATION');

                // Calculate and update ETA
                await _calculateAndUpdateETA(driverCoords);
              } else {
                AppLogger.log(
                  '❌ Failed to parse driver coordinates',
                  tag: 'DRIVER_LOCATION',
                );
              }
            } else {
              AppLogger.log(
                '⚠️ Driver data or location is null. DriverData: ${driverData != null}, Location: ${driverData?['Location']}',
                tag: 'DRIVER_LOCATION',
              );
            }
          } else if (status == 'arrived' || status == 'started') {
            AppLogger.log(
              '🏁 Driver has arrived or trip started, stopping tracking',
              tag: 'DRIVER_LOCATION',
            );
            // Stop tracking when driver arrives or trip starts
            _stopDriverLocationTracking();
          } else {
            AppLogger.log(
              '⚠️ Unexpected status: $status',
              tag: 'DRIVER_LOCATION',
            );
          }
        } else {
          AppLogger.log('⚠️ Rides array is empty', tag: 'DRIVER_LOCATION');
        }
      } else {
        AppLogger.log(
          '❌ Response unsuccessful or no rides. Success: ${response['success']}, Rides: $rides',
          tag: 'DRIVER_LOCATION',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Error updating driver location',
        error: e,
        tag: 'DRIVER_LOCATION',
      );
    }
  }

  /// Update driver marker on the map
  void _updateDriverMarker(LatLng driverLocation) {
    AppLogger.log('🚗 === UPDATING DRIVER MARKER ===', tag: 'DRIVER_MARKER');

    if (_carIcon == null) {
      AppLogger.log(
        '❌ Car icon is null! Cannot add driver marker.',
        tag: 'DRIVER_MARKER',
      );
      return;
    }

    AppLogger.log(
      '✅ Car icon loaded, refreshing map with driver at: ${driverLocation.latitude}, ${driverLocation.longitude}',
      tag: 'DRIVER_MARKER',
    );

    // Refresh all markers and polylines to update the route
    if (_activeRide != null) {
      AppLogger.log(
        '🔄 Refreshing all markers and polylines with updated driver location',
        tag: 'DRIVER_MARKER',
      );
      _addActiveRideMarkers(_activeRide!);
    }

    // Also add the driver marker
    setState(() {
      // Remove old driver marker if exists
      final removedCount = _mapMarkers
          .where((marker) => marker.markerId.value == 'driver_location')
          .length;
      _mapMarkers.removeWhere(
        (marker) => marker.markerId.value == 'driver_location',
      );

      AppLogger.log(
        '🗑️ Removed $removedCount old driver marker(s)',
        tag: 'DRIVER_MARKER',
      );

      // Add new driver marker
      _mapMarkers.add(
        Marker(
          markerId: MarkerId('driver_location'),
          position: driverLocation,
          icon: _carIcon!,
          anchor: Offset(0.5, 0.5),
          rotation: 0, // You can calculate bearing if needed
          infoWindow: InfoWindow(
            title: 'Driver',
            snippet: _assignedDriver?.name ?? 'Your driver',
          ),
        ),
      );

      AppLogger.log(
        '✅ Driver marker added. Total markers: ${_mapMarkers.length}',
        tag: 'DRIVER_MARKER',
      );
    });
  }

  /// Calculate ETA from driver location to pickup location
  Future<void> _calculateAndUpdateETA(LatLng driverLocation) async {
    AppLogger.log('⏱️ === CALCULATING ETA ===', tag: 'ETA');

    if (_activeRide == null) {
      AppLogger.log('⚠️ No active ride', tag: 'ETA');
      return;
    }

    try {
      // Get pickup location
      final pickupLocationStr = _activeRide!['PickupLocation']?.toString();
      if (pickupLocationStr == null) {
        AppLogger.log('❌ Pickup location is null', tag: 'ETA');
        return;
      }

      AppLogger.log('📍 Pickup location (raw): $pickupLocationStr', tag: 'ETA');

      final pickupCoords = _parsePostGISPoint(pickupLocationStr);
      if (pickupCoords == null) {
        AppLogger.log('❌ Failed to parse pickup coordinates', tag: 'ETA');
        return;
      }

      AppLogger.log(
        '✅ Pickup coords: lat=${pickupCoords.latitude}, lng=${pickupCoords.longitude}',
        tag: 'ETA',
      );

      AppLogger.log('🌐 Calling Google Directions API...', tag: 'ETA');

      // Get route details from Google Directions API
      final routeDetails = await _directionsService.getRouteDetails(
        origin: driverLocation,
        destination: pickupCoords,
      );

      if (routeDetails != null) {
        final durationInSeconds = routeDetails['duration_value'] as int;
        final durationInMinutes = (durationInSeconds / 60).ceil();

        AppLogger.log(
          '✅ API Response - Duration: ${routeDetails['duration']}, Value: $durationInSeconds seconds = $durationInMinutes minutes',
          tag: 'ETA',
        );

        setState(() {
          _driverArrivalTime = durationInMinutes.toString();
        });

        AppLogger.log(
          '✅ ETA UPDATED TO: $durationInMinutes mins (displayed as: $_driverArrivalTime)',
          tag: 'ETA',
        );
      } else {
        AppLogger.log(
          '⚠️ API returned null, using fallback calculation',
          tag: 'ETA',
        );

        // Fallback: Calculate straight-line distance and estimate
        final distanceKm = _calculateDistance(driverLocation, pickupCoords);
        final estimatedMinutes = (distanceKm / 0.5)
            .ceil(); // Assume 30 km/h average speed

        AppLogger.log(
          '📏 Distance: ${distanceKm.toStringAsFixed(2)} km, Estimated: $estimatedMinutes mins',
          tag: 'ETA',
        );

        setState(() {
          _driverArrivalTime = estimatedMinutes.toString();
        });

        AppLogger.log(
          '✅ ETA ESTIMATED (fallback): $estimatedMinutes mins',
          tag: 'ETA',
        );
      }
    } catch (e) {
      AppLogger.error('Error calculating ETA', error: e, tag: 'ETA');
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
      // Generate session token for billing optimization
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

  void _selectLocation(PlacePrediction prediction, bool isFrom) async {
    // Get place details for accurate coordinates
    final placeDetails = await _placesService.getPlaceDetails(
      prediction.placeId,
      sessionToken: _sessionToken,
    );

    // Store coordinates if available
    if (placeDetails != null) {
      final coordinates = LatLng(placeDetails.latitude, placeDetails.longitude);

      if (isFrom) {
        _pickupCoordinates = coordinates;
      } else {
        _destinationCoordinates = coordinates;
      }
    }

    setState(() {
      if (isFrom) {
        fromController.text = prediction.description;
        _showDestinationField = true;
        _isFromFieldFocused = false;
      } else {
        toController.text = prediction.description;
      }
      _locationSuggestions = [];
      _showSuggestions = false;
      _sessionToken = null; // Reset session token after use
    });

    // Save to recent locations
    Provider.of<LocationProvider>(
      context,
      listen: false,
    ).addRecentLocation(prediction.description, prediction.description);

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
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        String currentAddress = 'Current location';
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          currentAddress = '${place.street ?? ''}, ${place.locality ?? ''}'
              .replaceAll(RegExp(r'^,\s*|,\s*$'), '');
          if (currentAddress.isEmpty) currentAddress = 'Current location';
        }
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _userCurrentLocation = position;
          fromController.text = currentAddress;
          _isLocationLoaded = true;
        });
        AppLogger.log(
          '📍 Current user location: ${position.latitude}, ${position.longitude}',
        );
      }
    } catch (e) {
      AppLogger.log('Error getting location: $e');
    }
  }

  double _calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
          start.latitude,
          start.longitude,
          end.latitude,
          end.longitude,
        ) /
        1000; // Convert to kilometers
  }

  String _formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  Future<void> _checkAndShowRating(int rideId) async {
    try {
      AppLogger.log('=== CHECKING RATING STATUS ===');
      AppLogger.log('Ride ID: $rideId');
      AppLogger.log('Calling getRideDetails...');

      final result = await _rideService.getRideDetails(rideId);

      AppLogger.log('getRideDetails result: $result');

      if (result['success'] == true) {
        final rideData = result['data'];
        AppLogger.log('Ride data: $rideData');

        final hasRated = rideData['passenger_rated_driver'] ?? false;
        AppLogger.log('passenger_rated_driver: $hasRated');

        if (!hasRated && mounted) {
          AppLogger.log('✅ Showing rating sheet');
          _showRatingSheet();
        } else {
          AppLogger.log(
            '⚠️ Not showing rating sheet - hasRated: $hasRated, mounted: $mounted',
          );
        }
      } else {
        AppLogger.log('❌ getRideDetails failed: ${result['message']}');
      }
      AppLogger.log('=== END CHECKING RATING STATUS ===');
    } catch (e) {
      AppLogger.log('❌ Error checking rating status: $e');
    }
  }

  // Future<RideResponse?> _requestRide({bool isScheduled = false}) async {
  //   if (_currentEstimate == null || selectedVehicle == null) {
  //     throw Exception('No estimate or vehicle selected');
  //   }

  //   final selectedPriceData = _currentEstimate!.priceList[selectedVehicle!];
  //   final vehicleType = selectedPriceData['vehicle_type'];

  //   String? scheduledDateTime;
  //   if (isScheduled) {
  //     final scheduledDate = DateTime(
  //       selectedDate.year,
  //       selectedDate.month,
  //       selectedDate.day,
  //       selectedTime.hour,
  //       selectedTime.minute,
  //     );
  //     scheduledDateTime = scheduledDate.toIso8601String();
  //   }

  //   final request = RideRequest(
  //     pickup: _pickupCoordinates != null
  //         ? '${_pickupCoordinates!.latitude},${_pickupCoordinates!.longitude}'
  //         : '${_currentLocation.latitude},${_currentLocation.longitude}',
  //     dest: _destinationCoordinates != null
  //         ? '${_destinationCoordinates!.latitude},${_destinationCoordinates!.longitude}'
  //         : '${_currentLocation.latitude + 0.01},${_currentLocation.longitude + 0.01}',
  //     pickupAddress: fromController.text.isNotEmpty
  //         ? fromController.text
  //         : 'Current location',
  //     destAddress: toController.text,
  //     stopAddress: stopController.text.isNotEmpty ? stopController.text : null,
  //     serviceType: 'taxi',
  //     vehicleType: vehicleType,
  //     paymentMethod: selectedPaymentMethod,
  //     scheduled: isScheduled,
  //     scheduledAt: scheduledDateTime,
  //   );

  //   return await _rideService.requestRide(request);
  // }

  Future<void> _estimateRide() async {
    AppLogger.log('🚗 === ESTIMATING RIDE ===', tag: 'ESTIMATE');

    if (_pickupCoordinates == null || _destinationCoordinates == null) {
      AppLogger.log('❌ Missing coordinates', tag: 'ESTIMATE');
      AppLogger.log('Pickup: $_pickupCoordinates', tag: 'ESTIMATE');
      AppLogger.log('Destination: $_destinationCoordinates', tag: 'ESTIMATE');
      return;
    }

    final request = RideEstimateRequest(
      pickup:
          'POINT(${_pickupCoordinates!.longitude} ${_pickupCoordinates!.latitude})',
      dest:
          'POINT(${_destinationCoordinates!.longitude} ${_destinationCoordinates!.latitude})',
      destAddress: toController.text,
      serviceType: 'taxi',
      vehicleType: 'regular', // Default for estimation
    );

    AppLogger.log('📤 Estimate Request:', tag: 'ESTIMATE');
    AppLogger.log('  Pickup: ${request.pickup}', tag: 'ESTIMATE');
    AppLogger.log('  Dest: ${request.dest}', tag: 'ESTIMATE');
    AppLogger.log('  Service Type: ${request.serviceType}', tag: 'ESTIMATE');

    try {
      _currentEstimate = await _rideService.estimateRide(request);

      AppLogger.log('✅ === ESTIMATE RESPONSE RECEIVED ===', tag: 'ESTIMATE');
      AppLogger.log('Currency: ${_currentEstimate!.currency}', tag: 'ESTIMATE');
      AppLogger.log(
        'Distance KM: ${_currentEstimate!.distanceKm}',
        tag: 'ESTIMATE',
      );
      AppLogger.log(
        '⏱️ DURATION MIN: ${_currentEstimate!.durationMin}',
        tag: 'ESTIMATE',
      );
      AppLogger.log(
        'Service Type: ${_currentEstimate!.serviceType}',
        tag: 'ESTIMATE',
      );
      AppLogger.log(
        'Price List Length: ${_currentEstimate!.priceList.length}',
        tag: 'ESTIMATE',
      );

      for (int i = 0; i < _currentEstimate!.priceList.length; i++) {
        final price = _currentEstimate!.priceList[i];
        AppLogger.log(
          '  Vehicle $i: ${price['vehicle_type']}',
          tag: 'ESTIMATE',
        );
        AppLogger.log(
          '    Total Fare: ${price['total_fare']}',
          tag: 'ESTIMATE',
        );
      }

      AppLogger.log('=== END ESTIMATE RESPONSE ===', tag: 'ESTIMATE');

      setState(() {});
    } catch (e) {
      AppLogger.error('Error estimating ride', error: e, tag: 'ESTIMATE');
      rethrow;
    }
  }

  void _addActiveRideMarkers(Map<String, dynamic> ride) async {
    AppLogger.log('📍 === ADDING ACTIVE RIDE MARKERS ===', tag: 'MARKERS');

    // Get ride status to determine what to display
    final status = ride['Status']?.toString().toLowerCase() ?? '';
    AppLogger.log('🎯 Ride status for markers: $status', tag: 'MARKERS');

    // Parse PostGIS POINT format: "POINT(longitude latitude)"
    final pickupLocation = ride['PickupLocation']?.toString();
    final destLocation = ride['DestLocation']?.toString();
    final stopLocation = ride['StopLocation']?.toString();

    AppLogger.log('📍 Raw PickupLocation: $pickupLocation', tag: 'MARKERS');
    AppLogger.log('📍 Raw DestLocation: $destLocation', tag: 'MARKERS');
    AppLogger.log('📍 Raw StopLocation: $stopLocation', tag: 'MARKERS');

    LatLng? pickupCoords;
    LatLng? destCoords;
    LatLng? stopCoords;

    // Check if location is in WKB format (hex string) or POINT format
    if (pickupLocation != null &&
        (pickupLocation.startsWith('0101000020') ||
            pickupLocation.contains('POINT'))) {
      final coords = _parsePostGISPoint(pickupLocation);
      if (coords != null) {
        pickupCoords = coords;
        AppLogger.log('✅ Pickup coords parsed: $coords', tag: 'MARKERS');
      } else {
        AppLogger.log('❌ Failed to parse pickup coords', tag: 'MARKERS');
      }
    } else {
      AppLogger.log(
        '⚠️ Pickup location is null or not in recognized format',
        tag: 'MARKERS',
      );
    }

    if (destLocation != null &&
        (destLocation.startsWith('0101000020') ||
            destLocation.contains('POINT'))) {
      final coords = _parsePostGISPoint(destLocation);
      if (coords != null) {
        destCoords = coords;
        AppLogger.log('✅ Dest coords parsed: $coords', tag: 'MARKERS');
      } else {
        AppLogger.log('❌ Failed to parse dest coords', tag: 'MARKERS');
      }
    } else {
      AppLogger.log(
        '⚠️ Dest location is null or not in recognized format',
        tag: 'MARKERS',
      );
    }

    // Handle stop location - if "No stops", place marker at midpoint
    final stopAddress = ride['StopAddress']?.toString() ?? '';
    if (stopAddress == 'No stops' &&
        pickupCoords != null &&
        destCoords != null) {
      // Calculate midpoint between pickup and destination
      stopCoords = LatLng(
        (pickupCoords.latitude + destCoords.latitude) / 2,
        (pickupCoords.longitude + destCoords.longitude) / 2,
      );
      AppLogger.log(
        '✅ Stop coords calculated as midpoint: $stopCoords',
        tag: 'MARKERS',
      );
    } else if (stopLocation != null &&
        (stopLocation.startsWith('0101000020') ||
            stopLocation.contains('POINT'))) {
      final coords = _parsePostGISPoint(stopLocation);
      if (coords != null) {
        stopCoords = coords;
        AppLogger.log('✅ Stop coords parsed: $coords', tag: 'MARKERS');
      } else {
        AppLogger.log('❌ Failed to parse stop coords', tag: 'MARKERS');
      }
    } else {
      AppLogger.log(
        '⚠️ Stop location is null or not in recognized format',
        tag: 'MARKERS',
      );
    }

    // Create markers
    final markers = <Marker>{};

    // Always add pickup marker
    if (pickupCoords != null) {
      AppLogger.log('🎨 Creating pickup marker widget...', tag: 'MARKERS');
      try {
        final pickupIcon = await _createBitmapDescriptorFromWidget(
          _buildPickupMarkerWidget(),
          size: Size(247.w, 50.h),
        );
        markers.add(
          Marker(
            markerId: MarkerId('active_pickup'),
            position: pickupCoords,
            icon: pickupIcon,
            anchor: Offset(0.5, 1.0),
          ),
        );
        AppLogger.log('✅ Pickup marker added with custom icon', tag: 'MARKERS');
      } catch (e) {
        AppLogger.log(
          '⚠️ Failed to create custom pickup marker, using default: $e',
          tag: 'MARKERS',
        );
        // Fallback to default marker
        markers.add(
          Marker(
            markerId: MarkerId('active_pickup'),
            position: pickupCoords,
            infoWindow: InfoWindow(
              title: 'Pickup',
              snippet:
                  _activeRide?['PickupAddress']?.toString() ??
                  'Pickup Location',
            ),
          ),
        );
      }
    }

    // Only add dropoff marker when ride has started
    if (status == 'started' && destCoords != null) {
      AppLogger.log(
        '🎨 Creating dropoff marker widget (ride started)...',
        tag: 'MARKERS',
      );
      try {
        final dropoffIcon = await _createBitmapDescriptorFromWidget(
          _buildDropoffMarkerWidget(),
          size: Size(242.w, 48.h),
        );
        markers.add(
          Marker(
            markerId: MarkerId('active_dropoff'),
            position: destCoords,
            icon: dropoffIcon,
            anchor: Offset(0.5, 1.0),
          ),
        );
        AppLogger.log(
          '✅ Dropoff marker added with custom icon',
          tag: 'MARKERS',
        );
      } catch (e) {
        AppLogger.log(
          '⚠️ Failed to create custom dropoff marker, using default: $e',
          tag: 'MARKERS',
        );
        // Fallback to default marker
        markers.add(
          Marker(
            markerId: MarkerId('active_dropoff'),
            position: destCoords,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: 'Destination',
              snippet: _activeRide?['DestAddress']?.toString() ?? 'Destination',
            ),
          ),
        );
      }
    } else if (status == 'accepted') {
      AppLogger.log(
        '⏭️ Skipping dropoff marker (ride not started yet)',
        tag: 'MARKERS',
      );
    }

    // Only add stop marker when ride has started
    if (status == 'started' && stopCoords != null) {
      AppLogger.log('🎨 Creating stop marker widget...', tag: 'MARKERS');
      try {
        final stopIcon = await _createBitmapDescriptorFromWidget(
          _buildStopMarkerWidget(),
          size: Size(200.w, 40.h),
        );
        markers.add(
          Marker(
            markerId: MarkerId('active_stop'),
            position: stopCoords,
            icon: stopIcon,
            anchor: Offset(0.5, 1.0),
          ),
        );
        AppLogger.log('✅ Stop marker added with custom icon', tag: 'MARKERS');
      } catch (e) {
        AppLogger.log(
          '⚠️ Failed to create custom stop marker, using default: $e',
          tag: 'MARKERS',
        );
        // Fallback to default marker
        markers.add(
          Marker(
            markerId: MarkerId('active_stop'),
            position: stopCoords,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange,
            ),
            infoWindow: InfoWindow(
              title: 'Stop',
              snippet: _activeRide?['StopAddress']?.toString() ?? 'Stop',
            ),
          ),
        );
      }
    }

    AppLogger.log(
      '📊 Total markers created: ${markers.length}',
      tag: 'MARKERS',
    );

    // Draw polyline based on ride status
    final polylines = <Polyline>{};

    if (status == 'accepted') {
      // When accepted: Draw polyline from pickup to driver location
      if (pickupCoords != null && _driverLocation != null) {
        AppLogger.log(
          '🛣️ Drawing route from PICKUP to DRIVER (accepted status)...',
          tag: 'MARKERS',
        );

        try {
          final routePoints = await _directionsService.getRoutePolyline(
            origin: pickupCoords,
            destination: _driverLocation!,
          );

          AppLogger.log(
            '✅ Got ${routePoints.length} route points (pickup to driver)',
            tag: 'MARKERS',
          );

          polylines.add(
            Polyline(
              polylineId: PolylineId('driver_to_pickup_route'),
              points: routePoints,
              color: Color(ConstColors.mainColor),
              width: 5,
              geodesic: true,
            ),
          );

          AppLogger.log(
            '✅ Polyline created (pickup to driver)',
            tag: 'MARKERS',
          );
        } catch (e) {
          AppLogger.log('⚠️ Failed to get route polyline: $e', tag: 'MARKERS');
          // Fallback: draw straight line
          polylines.add(
            Polyline(
              polylineId: PolylineId('driver_to_pickup_route'),
              points: [pickupCoords, _driverLocation!],
              color: Color(ConstColors.mainColor),
              width: 5,
              geodesic: true,
            ),
          );
        }
      } else {
        AppLogger.log(
          '⚠️ Cannot draw pickup-to-driver route: pickupCoords=${pickupCoords != null}, driverLocation=${_driverLocation != null}',
          tag: 'MARKERS',
        );
      }
    } else if (status == 'started') {
      // When started: Draw polyline from pickup to destination
      if (pickupCoords != null && destCoords != null) {
        AppLogger.log(
          '🛣️ Drawing route from PICKUP to DESTINATION (started status)...',
          tag: 'MARKERS',
        );

        try {
          final routePoints = await _directionsService.getRoutePolyline(
            origin: pickupCoords,
            destination: destCoords,
            waypoints: stopCoords != null ? [stopCoords] : null,
          );

          AppLogger.log(
            '✅ Got ${routePoints.length} route points (pickup to destination)',
            tag: 'MARKERS',
          );

          polylines.add(
            Polyline(
              polylineId: PolylineId('active_route'),
              points: routePoints,
              color: Color(ConstColors.mainColor),
              width: 5,
              geodesic: true,
            ),
          );

          // AppLogger.log(
          //   '✅ Polyline created (pickup to destination)',
          //   tag: 'MARKERS',
          // );
        } catch (e) {
          AppLogger.log('⚠️ Failed to get route polyline: $e', tag: 'MARKERS');
          // Fallback: draw straight line
          polylines.add(
            Polyline(
              polylineId: PolylineId('active_route'),
              points: [pickupCoords, destCoords],
              color: Color(ConstColors.mainColor),
              width: 5,
              geodesic: true,
            ),
          );
        }
      }
    }

    setState(() {
      _mapMarkers = markers;
      _mapPolylines = polylines;
    });

    AppLogger.log('✅ Markers and polylines set in state', tag: 'MARKERS');

    // Only fit camera to show all markers on the FIRST load
    // After that, let the user control the map zoom/pan
    if (!_hasInitializedMapCamera &&
        markers.isNotEmpty &&
        _mapController != null) {
      final positions = markers.map((m) => m.position).toList();
      final bounds = _calculateBounds(positions);
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
      _hasInitializedMapCamera = true;
      AppLogger.log(
        '📷 Camera adjusted to fit markers (first time only)',
        tag: 'MARKERS',
      );
    } else if (_hasInitializedMapCamera) {
      AppLogger.log(
        '⏭️ Skipping camera adjustment - user can control map freely',
        tag: 'MARKERS',
      );
    } else {
      AppLogger.log(
        '⚠️ Cannot adjust camera: markers=${markers.length}, controller=${_mapController != null}',
        tag: 'MARKERS',
      );
    }

    AppLogger.log('📍 === MARKERS SETUP COMPLETE ===', tag: 'MARKERS');
  }

  LatLng? _parsePostGISPoint(String pointString) {
    try {
      // Check if it's WKB format (hex string)
      if (pointString.startsWith('0101000020')) {
        AppLogger.log('🔍 Parsing WKB format: $pointString', tag: 'WKB_PARSER');
        final result = _parsePostGISLocation(pointString);
        if (result != null && result['lat'] != null && result['lng'] != null) {
          final latLng = LatLng(result['lat']!, result['lng']!);
          AppLogger.log('✅ WKB parsed to LatLng: $latLng', tag: 'WKB_PARSER');
          return latLng;
        } else {
          AppLogger.log('❌ Failed to parse WKB format', tag: 'WKB_PARSER');
          return null;
        }
      }

      // Otherwise, try POINT format
      // Remove "POINT(" and ")" and split by space
      final coords = pointString
          .replaceAll('POINT(', '')
          .replaceAll(')', '')
          .split(' ');

      if (coords.length == 2) {
        final longitude = double.parse(coords[0]);
        final latitude = double.parse(coords[1]);
        return LatLng(latitude, longitude);
      }
    } catch (e) {
      AppLogger.log('Error parsing PostGIS point: $e');
    }
    return null;
  }

  LatLngBounds _calculateBounds(List<LatLng> positions) {
    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (final pos in positions) {
      minLat = math.min(minLat, pos.latitude);
      maxLat = math.max(maxLat, pos.latitude);
      minLng = math.min(minLng, pos.longitude);
      maxLng = math.max(maxLng, pos.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  // void _showRatingSheet() {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     isDismissible: false,
  //     enableDrag: false,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
  //     ),
  //     builder: (context) => StatefulBuilder(
  //       builder: (context, setRatingState) {
  //         int selectedRating = 0;
  //         final TextEditingController commentController = TextEditingController();

  //         return Container(
  //           height: 400.h,
  //           padding: EdgeInsets.all(20.w),
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
  //           ),
  //           child: Column(
  //             children: [
  //               Text(
  //                 'Rate your driver',
  //                 style: TextStyle(
  //                   fontSize: 18.sp,
  //                   fontWeight: FontWeight.w600,
  //                 ),
  //               ),
  //               SizedBox(height: 20.h),
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: List.generate(5, (index) {
  //                   return GestureDetector(
  //                     onTap: () {
  //                       setRatingState(() {
  //                         selectedRating = index + 1;
  //                       });
  //                     },
  //                     child: Icon(
  //                       Icons.star,
  //                       size: 40.sp,
  //                       color: index < selectedRating ? Colors.amber : Colors.grey,
  //                     ),
  //                   );
  //                 }),
  //               ),
  //               SizedBox(height: 20.h),
  //               TextField(
  //                 controller: commentController,
  //                 decoration: InputDecoration(
  //                   hintText: 'Add a comment (optional)',
  //                   border: OutlineInputBorder(),
  //                 ),
  //                 maxLines: 3,
  //               ),
  //               Spacer(),
  //               Row(
  //                 children: [
  //                   Expanded(
  //                     child: TextButton(
  //                       onPressed: () {
  //                         if (_lastCompletedRideId != null) {
  //                           _dismissedRatingRides.add(_lastCompletedRideId!);
  //                         }
  //                         Navigator.pop(context);
  //                       },
  //                       child: Text('Skip'),
  //                     ),
  //                   ),
  //                   SizedBox(width: 10.w),
  //                   Expanded(
  //                     child: ElevatedButton(
  //                       onPressed: selectedRating > 0
  //                           ? () async {
  //                               if (_lastCompletedRideId != null) {
  //                                 try {
  //                                   await _rideService.rateRide(
  //                                     rideId: _lastCompletedRideId!,
  //                                     score: selectedRating,
  //                                     comment: commentController.text,
  //                                   );
  //                                   Navigator.pop(context);
  //                                 } catch (e) {
  //                                   AppLogger.log('Error rating ride: $e');
  //                                 }
  //                               }
  //                             }
  //                           : null,
  //                       child: Text('Submit'),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }

  Widget _buildDrawerItem(
    String title,
    String iconPath, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Image.asset(iconPath, width: 24.w, height: 24.h),
      title: Text(title),
      onTap: onTap,
    );
  }

  // @override
  // void dispose() {
  //   _webSocketService.disconnect();
  //   _activeRideCheckTimer?.cancel();

  //   _callService.dispose(); // Add this line

  //   super.dispose();
  // }

  void _navigateToWallet() async {
    Navigator.pop(context);

    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    final hasAccount = await walletProvider.checkVirtualAccount();

    AppLogger.log('Navigate to appropriate screen');
    if (mounted) {
      if (hasAccount) {
        AppLogger.log('Navigate to appropriate WalletScreen');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WalletScreen()),
        );
      } else {
        AppLogger.log('Navigate to appropriate WalletEmptyScreen');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WalletEmptyScreen()),
        );
      }
    }
  }

  Future<void> _launchPhoneDialer() async {
    const phoneNumber = '07032992768';
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        AppLogger.log(
          '📞 Launched phone dialer for: $phoneNumber',
          tag: 'CONTACT',
        );
      } else {
        AppLogger.error('Could not launch phone dialer', tag: 'CONTACT');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open phone dialer')),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error launching phone dialer', error: e, tag: 'CONTACT');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _launchWhatsApp() async {
    const phoneNumber = '2347032992768'; // WhatsApp format with country code
    final Uri whatsappUri = Uri.parse('https://wa.me/$phoneNumber');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        AppLogger.log('💬 Launched WhatsApp for: $phoneNumber', tag: 'CONTACT');
      } else {
        AppLogger.error('Could not launch WhatsApp', tag: 'CONTACT');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open WhatsApp')),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error launching WhatsApp', error: e, tag: 'CONTACT');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _dismissSuggestions() {
    setState(() {
      _showSuggestions = false;
      _locationSuggestions = [];
    });
  }

  void _loadProfile() async {
    final profileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );
    await profileProvider.fetchUserProfile();
  }

  Future<void> _forceUpdateLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _userCurrentLocation = position;
        });

        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _currentLocation, zoom: 16.0),
          ),
        );
        AppLogger.log('📍 Map centered to: $_currentLocation', tag: 'LOCATION');
      }
    } catch (e) {
      AppLogger.error('Error getting location: $e', tag: 'LOCATION');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        } else {
          final now = DateTime.now();
          if (_lastBackPress == null ||
              now.difference(_lastBackPress!) > Duration(seconds: 2)) {
            _lastBackPress = now;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Press back again to exit'),
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            Navigator.of(context).pop();
          }
        }
      },
      child: GestureDetector(
        onTap: _dismissSuggestions,
        child: Scaffold(
          key: _scaffoldKey,
          drawer: const AppDrawer(),
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
                  color: _currentIndex == 0
                      ? Color(ConstColors.mainColor)
                      : Colors.grey,
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  ConstImages.services,
                  width: 24.w,
                  height: 24.h,
                  color: _currentIndex == 1
                      ? Color(ConstColors.mainColor)
                      : Colors.grey,
                ),
                label: 'Services',
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  ConstImages.activities,
                  width: 24.w,
                  height: 24.h,
                  color: _currentIndex == 2
                      ? Color(ConstColors.mainColor)
                      : Colors.grey,
                ),
                label: 'Activities',
              ),
            ],
          ),
          body: _currentIndex == 1
              ? const ServicesScreen()
              : _currentIndex == 2
              ? ActivitiesScreen()
              : Stack(
                  children: [
                    // Google Maps background
                    GoogleMap(
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                        _forceUpdateLocation();
                      },
                      initialCameraPosition: CameraPosition(
                        target: _currentLocation,
                        zoom: 15.0,
                      ),
                      markers: _mapMarkers,
                      polylines: _mapPolylines,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
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
                    // Active ride indicator
                    if (_activeRide != null)
                      Positioned(
                        top: 66.h,
                        right: 30.w,
                        child: GestureDetector(
                          onTap: () {
                            if (_activeRide != null) {
                              _hasUserDismissedSheet = false;
                              _showDriverAcceptedSheet();
                            }
                          },
                          child: Container(
                            width: 50.w,
                            height: 50.h,
                            decoration: BoxDecoration(
                              color: Color(ConstColors.mainColor),
                              borderRadius: BorderRadius.circular(25.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(10.w),
                            child: Icon(
                              Icons.directions_car,
                              size: 24.sp,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    // Bottom sheet
                    if (_isBottomSheetVisible)
                      DraggableScrollableSheet(
                        initialChildSize: 0.4,
                        minChildSize: 0.2,
                        maxChildSize: 0.8,
                        builder: (BuildContext context, ScrollController scrollController) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20.r),
                                topRight: Radius.circular(20.r),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, -2),
                                ),
                              ],
                            ),
                            child: ListView(
                              controller: scrollController,
                              children: [
                                SizedBox(
                                  child: Column(
                                    children: [
                                      // SizedBox(height: 10.h),
                                      Container(
                                        width: 69.w,
                                        height: 5.h,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(
                                            2.5.r,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20.w,
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 14.w,
                                        child: Column(
                                          children: [
                                            Container(
                                              width: 14.w,
                                              height: 14.h,
                                              decoration: BoxDecoration(
                                                color: Color(
                                                  ConstColors.mainColor,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            if (_showDestinationField) ...[
                                              SizedBox(height: 5.h),
                                              Container(
                                                width: 2.w,
                                                height: 8.h,
                                                color: Colors.grey,
                                              ),
                                              SizedBox(height: 4.h),
                                              Container(
                                                width: 2.w,
                                                height: 8.h,
                                                color: Colors.grey,
                                              ),
                                              SizedBox(height: 4.h),
                                              Container(
                                                width: 2.w,
                                                height: 8.h,
                                                color: Colors.grey,
                                              ),

                                              if (_showStopField) ...[
                                                SizedBox(height: 4.h),
                                                Container(
                                                  width: 14.w,
                                                  height: 14.h,
                                                  decoration: BoxDecoration(
                                                    color: Colors.black,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                SizedBox(height: 5.h),
                                                Container(
                                                  width: 2.w,
                                                  height: 8.h,
                                                  color: Colors.grey,
                                                ),
                                                SizedBox(height: 4.h),
                                                Container(
                                                  width: 2.w,
                                                  height: 8.h,
                                                  color: Colors.grey,
                                                ),
                                                SizedBox(height: 4.h),

                                                Container(
                                                  width: 2.w,
                                                  height: 8.h,
                                                  color: Colors.grey,
                                                ),
                                              ],
                                              SizedBox(height: 5.h),
                                              Container(
                                                width: 14.w,
                                                height: 14.h,
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 15.w),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Container(
                                                    height: 50.h,
                                                    decoration: BoxDecoration(
                                                      color: Color(
                                                        ConstColors.fieldColor,
                                                      ).withOpacity(0.12),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8.r,
                                                          ),
                                                    ),
                                                    child: TextField(
                                                      controller:
                                                          fromController,
                                                      readOnly:
                                                          _showDestinationField
                                                          ? !_isFromFieldEditable
                                                          : false,
                                                      onTap: () {
                                                        if (!_showDestinationField) {
                                                          setState(() {
                                                            _showDestinationField =
                                                                true;
                                                            _isFromFieldFocused =
                                                                true;
                                                            _showSuggestions =
                                                                false;
                                                          });
                                                        } else if (!_isFromFieldEditable &&
                                                            _isLocationLoaded) {
                                                          setState(() {
                                                            _isFromFieldEditable =
                                                                true;
                                                            _isFromFieldFocused =
                                                                true;
                                                          });
                                                        } else {
                                                          setState(() {
                                                            _isFromFieldFocused =
                                                                true;
                                                          });
                                                        }
                                                      },
                                                      onChanged: (value) {
                                                        if (_isFromFieldFocused ||
                                                            !_showDestinationField) {
                                                          _searchLocations(
                                                            value,
                                                          );
                                                        }
                                                      },
                                                      decoration: InputDecoration(
                                                        hintText:
                                                            _showDestinationField
                                                            ? 'From?'
                                                            : 'Where to?',
                                                        prefixIcon: Icon(
                                                          Icons.search,
                                                          size: 20.sp,
                                                          color: Colors.grey,
                                                        ),
                                                        suffixIcon:
                                                            _showDestinationField
                                                            ? Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  if (fromController
                                                                      .text
                                                                      .isNotEmpty)
                                                                    GestureDetector(
                                                                      onTap: () {
                                                                        setState(() {
                                                                          fromController
                                                                              .clear();
                                                                          _isFromFieldEditable =
                                                                              false;
                                                                        });
                                                                      },
                                                                      child: Container(
                                                                        width:
                                                                            24.w,
                                                                        height:
                                                                            24.h,
                                                                        margin: EdgeInsets.only(
                                                                          right:
                                                                              8.w,
                                                                        ),
                                                                        child: Icon(
                                                                          Icons
                                                                              .clear,
                                                                          size:
                                                                              16.sp,
                                                                          color:
                                                                              Colors.grey,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  GestureDetector(
                                                                    onTap: () async {
                                                                      setState(() {
                                                                        _showMapTooltip =
                                                                            true;
                                                                      });
                                                                      Future.delayed(
                                                                        Duration(
                                                                          seconds:
                                                                              2,
                                                                        ),
                                                                        () {
                                                                          if (mounted) {
                                                                            setState(() {
                                                                              _showMapTooltip = false;
                                                                            });
                                                                          }
                                                                        },
                                                                      );
                                                                      final result = await Navigator.push(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                          builder:
                                                                              (
                                                                                context,
                                                                              ) => MapSelectionScreen(
                                                                                isFromField: true,
                                                                                initialLocation: _currentLocation,
                                                                              ),
                                                                        ),
                                                                      );
                                                                      if (result !=
                                                                          null) {
                                                                        setState(() {
                                                                          fromController.text =
                                                                              result['address'];
                                                                          _pickupCoordinates =
                                                                              result['location'];
                                                                          _currentLocation =
                                                                              result['location'];
                                                                        });
                                                                        // Check if both fields are filled to show vehicle selection
                                                                        if (toController
                                                                            .text
                                                                            .isNotEmpty) {
                                                                          _checkBothFields();
                                                                        }
                                                                      }
                                                                    },
                                                                    child: Stack(
                                                                      children: [
                                                                        Container(
                                                                          width:
                                                                              24.w,
                                                                          height:
                                                                              24.h,
                                                                          margin: EdgeInsets.only(
                                                                            right:
                                                                                8.w,
                                                                          ),
                                                                          child: Icon(
                                                                            Icons.map,
                                                                            size:
                                                                                16.sp,
                                                                            color: Color(
                                                                              ConstColors.mainColor,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        if (_showMapTooltip)
                                                                          Positioned(
                                                                            right:
                                                                                35.w,
                                                                            top:
                                                                                -25.h,
                                                                            child: Container(
                                                                              padding: EdgeInsets.symmetric(
                                                                                horizontal: 8.w,
                                                                                vertical: 4.h,
                                                                              ),
                                                                              decoration: BoxDecoration(
                                                                                color: Colors.black87,
                                                                                borderRadius: BorderRadius.circular(
                                                                                  4.r,
                                                                                ),
                                                                              ),
                                                                              child: Text(
                                                                                'Select from map',
                                                                                style: TextStyle(
                                                                                  color: Colors.white,
                                                                                  fontSize: 10.sp,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                              )
                                                            : null,
                                                        border:
                                                            InputBorder.none,
                                                        contentPadding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 10.w,
                                                              vertical: 8.h,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _showStopField =
                                                          !_showStopField;
                                                    });
                                                  },
                                                  child: Icon(
                                                    Icons.add,
                                                    size: 24.sp,
                                                    color: Color(
                                                      ConstColors.mainColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (_showDestinationField) ...[
                                              SizedBox(height: 10.h),
                                              if (_showStopField) ...[
                                                Container(
                                                  height: 50.h,
                                                  decoration: BoxDecoration(
                                                    color: Color(
                                                      ConstColors.fieldColor,
                                                    ).withOpacity(0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8.r,
                                                        ),
                                                  ),
                                                  child: TextField(
                                                    controller: stopController,
                                                    onTap: () {
                                                      setState(() {
                                                        _isFromFieldFocused =
                                                            false;
                                                      });
                                                    },
                                                    onChanged: (value) {
                                                      if (!_isFromFieldFocused) {
                                                        _searchLocations(value);
                                                      }
                                                    },
                                                    decoration: InputDecoration(
                                                      hintText: 'Add stop',
                                                      prefixIcon: Icon(
                                                        Icons.search,
                                                        size: 20.sp,
                                                        color: Colors.grey,
                                                      ),
                                                      suffixIcon: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          if (stopController
                                                              .text
                                                              .isNotEmpty)
                                                            GestureDetector(
                                                              onTap: () {
                                                                setState(() {
                                                                  stopController
                                                                      .clear();
                                                                });
                                                              },
                                                              child: Container(
                                                                width: 24.w,
                                                                height: 24.h,
                                                                margin:
                                                                    EdgeInsets.only(
                                                                      right:
                                                                          8.w,
                                                                    ),
                                                                child: Icon(
                                                                  Icons.clear,
                                                                  size: 16.sp,
                                                                  color: Colors
                                                                      .grey,
                                                                ),
                                                              ),
                                                            ),
                                                          GestureDetector(
                                                            onTap: () async {
                                                              setState(() {
                                                                _showMapTooltip =
                                                                    true;
                                                              });
                                                              Future.delayed(
                                                                Duration(
                                                                  seconds: 2,
                                                                ),
                                                                () {
                                                                  if (mounted) {
                                                                    setState(() {
                                                                      _showMapTooltip =
                                                                          false;
                                                                    });
                                                                  }
                                                                },
                                                              );
                                                              final result = await Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder: (context) => MapSelectionScreen(
                                                                    isFromField:
                                                                        false,
                                                                    initialLocation:
                                                                        _currentLocation,
                                                                  ),
                                                                ),
                                                              );
                                                              if (result !=
                                                                  null) {
                                                                setState(() {
                                                                  stopController
                                                                          .text =
                                                                      result['address'];
                                                                  _stopCoordinates =
                                                                      result['location'];
                                                                });
                                                              }
                                                            },
                                                            child: Stack(
                                                              children: [
                                                                Container(
                                                                  width: 24.w,
                                                                  height: 24.h,
                                                                  margin:
                                                                      EdgeInsets.only(
                                                                        right:
                                                                            8.w,
                                                                      ),
                                                                  child: Icon(
                                                                    Icons.map,
                                                                    size: 16.sp,
                                                                    color: Color(
                                                                      ConstColors
                                                                          .mainColor,
                                                                    ),
                                                                  ),
                                                                ),
                                                                if (_showMapTooltip)
                                                                  Positioned(
                                                                    right: 35.w,
                                                                    top: -25.h,
                                                                    child: Container(
                                                                      padding: EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            8.w,
                                                                        vertical:
                                                                            4.h,
                                                                      ),
                                                                      decoration: BoxDecoration(
                                                                        color: Colors
                                                                            .black87,
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              4.r,
                                                                            ),
                                                                      ),
                                                                      child: Text(
                                                                        'Select from map',
                                                                        style: TextStyle(
                                                                          color:
                                                                              Colors.white,
                                                                          fontSize:
                                                                              10.sp,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      border: InputBorder.none,
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 10.w,
                                                            vertical: 8.h,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: 10.h),
                                              ],
                                              Container(
                                                height: 50.h,
                                                decoration: BoxDecoration(
                                                  color: Color(
                                                    ConstColors.fieldColor,
                                                  ).withOpacity(0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        8.r,
                                                      ),
                                                ),
                                                child: TextField(
                                                  controller: toController,
                                                  onTap: () {
                                                    setState(() {
                                                      _isFromFieldFocused =
                                                          false;
                                                    });
                                                  },
                                                  onChanged: (value) {
                                                    if (!_isFromFieldFocused) {
                                                      _searchLocations(value);
                                                    }
                                                  },
                                                  decoration: InputDecoration(
                                                    hintText: 'Where to?',
                                                    prefixIcon: Icon(
                                                      Icons.search,
                                                      size: 20.sp,
                                                      color: Colors.grey,
                                                    ),
                                                    suffixIcon: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        if (toController
                                                            .text
                                                            .isNotEmpty)
                                                          GestureDetector(
                                                            onTap: () {
                                                              setState(() {
                                                                toController
                                                                    .clear();
                                                              });
                                                            },
                                                            child: Container(
                                                              width: 24.w,
                                                              height: 24.h,
                                                              margin:
                                                                  EdgeInsets.only(
                                                                    right: 8.w,
                                                                  ),
                                                              child: Icon(
                                                                Icons.clear,
                                                                size: 16.sp,
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                            ),
                                                          ),
                                                        GestureDetector(
                                                          onTap: () async {
                                                            setState(() {
                                                              _showMapTooltip =
                                                                  true;
                                                            });
                                                            Future.delayed(
                                                              Duration(
                                                                seconds: 2,
                                                              ),
                                                              () {
                                                                if (mounted) {
                                                                  setState(() {
                                                                    _showMapTooltip =
                                                                        false;
                                                                  });
                                                                }
                                                              },
                                                            );
                                                            final result = await Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (context) =>
                                                                    MapSelectionScreen(
                                                                      isFromField:
                                                                          false,
                                                                      initialLocation:
                                                                          _currentLocation,
                                                                    ),
                                                              ),
                                                            );
                                                            if (result !=
                                                                null) {
                                                              setState(() {
                                                                toController
                                                                        .text =
                                                                    result['address'];
                                                                _destinationCoordinates =
                                                                    result['location'];
                                                              });
                                                              // Check if both fields are filled to show vehicle selection
                                                              if (fromController
                                                                  .text
                                                                  .isNotEmpty) {
                                                                _checkBothFields();
                                                              }
                                                            }
                                                          },
                                                          child: Stack(
                                                            children: [
                                                              Container(
                                                                width: 24.w,
                                                                height: 24.h,
                                                                margin:
                                                                    EdgeInsets.only(
                                                                      right:
                                                                          8.w,
                                                                    ),
                                                                child: Icon(
                                                                  Icons.map,
                                                                  size: 16.sp,
                                                                  color: Color(
                                                                    ConstColors
                                                                        .mainColor,
                                                                  ),
                                                                ),
                                                              ),
                                                              if (_showMapTooltip)
                                                                Positioned(
                                                                  right: 35.w,
                                                                  top: -25.h,
                                                                  child: Container(
                                                                    padding: EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          8.w,
                                                                      vertical:
                                                                          4.h,
                                                                    ),
                                                                    decoration: BoxDecoration(
                                                                      color: Colors
                                                                          .black87,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            4.r,
                                                                          ),
                                                                    ),
                                                                    child: Text(
                                                                      'Select from map',
                                                                      style: TextStyle(
                                                                        color: Colors
                                                                            .white,
                                                                        fontSize:
                                                                            10.sp,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    border: InputBorder.none,
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 10.w,
                                                          vertical: 8.h,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_showSuggestions &&
                                    _locationSuggestions.isNotEmpty)
                                  Container(
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 20.w,
                                      vertical: 10.h,
                                    ),
                                    constraints: BoxConstraints(
                                      maxHeight: 300.h,
                                    ),
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
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: _locationSuggestions.length,
                                      separatorBuilder: (context, index) =>
                                          Divider(
                                            height: 1,
                                            color: Colors.grey.shade200,
                                          ),
                                      itemBuilder: (context, index) {
                                        final prediction =
                                            _locationSuggestions[index];
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
                                          subtitle:
                                              prediction
                                                  .secondaryText
                                                  .isNotEmpty
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
                                          onTap: () => _selectLocation(
                                            prediction,
                                            _isFromFieldFocused,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                SizedBox(height: 15.h),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20.w,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Saved location',
                                      style: ConstTextStyles.savedLocation,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                Divider(
                                  thickness: 1,
                                  color: Colors.grey.shade300,
                                ),
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
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AddHomeScreen(
                                              locationType: 'home',
                                            ),
                                      ),
                                    );
                                    if (result == true) {
                                      _loadFavouriteLocations();
                                      CustomFlushbar.showSuccess(
                                        context: context,
                                        message:
                                            'Home Location saved successfully!',
                                      );
                                    }
                                  },
                                ),
                                Divider(
                                  thickness: 1,
                                  color: Colors.grey.shade300,
                                ),
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
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AddHomeScreen(
                                              locationType: 'work',
                                            ),
                                      ),
                                    );
                                    if (result == true) {
                                      _loadFavouriteLocations();
                                      CustomFlushbar.showSuccess(
                                        context: context,
                                        message:
                                            'Work Location saved successfully!',
                                      );
                                    }
                                  },
                                ),
                                Divider(
                                  thickness: 1,
                                  color: Colors.grey.shade300,
                                ),
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
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AddHomeScreen(
                                              locationType: 'favourite',
                                            ),
                                      ),
                                    );
                                    if (result == true) {
                                      _loadFavouriteLocations();
                                      CustomFlushbar.showSuccess(
                                        context: context,
                                        message:
                                            'Favourite Location saved successfully!',
                                      );
                                    }
                                  },
                                ),
                                SizedBox(height: 15.h),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20.w,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Recent locations',
                                      style: ConstTextStyles.recentLocation
                                          .copyWith(
                                            color: Color(
                                              ConstColors.recentLocationColor,
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                Divider(
                                  thickness: 1,
                                  color: Colors.grey.shade300,
                                ),
                                Consumer<LocationProvider>(
                                  builder: (context, locationProvider, child) {
                                    final allLocations = <Widget>[];

                                    // Add favourite locations with appropriate icons
                                    for (final fav in _favouriteLocations) {
                                      allLocations.add(
                                        Column(
                                          children: [
                                            ListTile(
                                              leading: _getFavoriteLocationIcon(
                                                fav.name,
                                              ),
                                              title: Text(
                                                fav.name,
                                                style:
                                                    ConstTextStyles.drawerItem1,
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
                                                  final shouldDelete =
                                                      await showDialog<bool>(
                                                        context: context,
                                                        builder: (context) => AlertDialog(
                                                          title: Text(
                                                            'Remove Favourite',
                                                          ),
                                                          content: Text(
                                                            'Are you sure you want to remove this location from favourites?',
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                    false,
                                                                  ),
                                                              child: Text(
                                                                'Cancel',
                                                              ),
                                                            ),
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                    true,
                                                                  ),
                                                              child: Text(
                                                                'Remove',
                                                                style: TextStyle(
                                                                  color: Colors
                                                                      .red,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );

                                                  if (shouldDelete == true) {
                                                    try {
                                                      await _favouriteService
                                                          .deleteFavouriteLocation(
                                                            fav.id,
                                                          );
                                                      _loadFavouriteLocations();
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Favourite removed',
                                                          ),
                                                        ),
                                                      );
                                                    } catch (e) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Failed to remove favourite',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                                child: Icon(
                                                  Icons.star,
                                                  color: Colors.amber,
                                                  size: 24.sp,
                                                ),
                                              ),
                                              onTap: () {
                                                if (_isFromFieldFocused) {
                                                  fromController.text =
                                                      fav.destAddress;
                                                } else {
                                                  toController.text =
                                                      fav.destAddress;
                                                }
                                                setState(() {
                                                  _showSuggestions = false;
                                                });
                                                // Check if both fields are filled
                                                if (fromController
                                                            .text
                                                            .length >=
                                                        3 &&
                                                    toController.text.length >=
                                                        3) {
                                                  _checkBothFields();
                                                }
                                              },
                                            ),
                                            Divider(
                                              thickness: 1,
                                              color: Colors.grey.shade300,
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    // Add recent locations without star
                                    for (final recent
                                        in locationProvider.recentLocations) {
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
                                                  style: ConstTextStyles
                                                      .drawerItem1,
                                                ),
                                                subtitle: Text(
                                                  recent.address,
                                                  style: TextStyle(
                                                    fontSize: 12.sp,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                onTap: () {
                                                  if (_isFromFieldFocused) {
                                                    fromController.text =
                                                        recent.address;
                                                  } else {
                                                    toController.text =
                                                        recent.address;
                                                  }
                                                  setState(() {
                                                    _showSuggestions = false;
                                                  });
                                                  // Check if both fields are filled
                                                  if (fromController
                                                              .text
                                                              .length >=
                                                          3 &&
                                                      toController
                                                              .text
                                                              .length >=
                                                          3) {
                                                    _checkBothFields();
                                                  }
                                                },
                                              ),
                                              if (recent !=
                                                      locationProvider
                                                          .recentLocations
                                                          .where(
                                                            (r) =>
                                                                !r.isFavourite,
                                                          )
                                                          .last ||
                                                  _favouriteLocations
                                                      .isNotEmpty ||
                                                  locationProvider
                                                          .recentLocations
                                                          .where(
                                                            (r) =>
                                                                !r.isFavourite,
                                                          )
                                                          .length >
                                                      locationProvider
                                                          .recentLocations
                                                          .where(
                                                            (r) =>
                                                                !r.isFavourite,
                                                          )
                                                          .length)
                                                Divider(
                                                  thickness: 1,
                                                  color: Colors.grey.shade300,
                                                ),
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
                          );
                        },
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  void _checkBothFields() {
    if (fromController.text.length >= 3 && toController.text.length >= 3) {
      _updateMapWithRoute();
      _showBookingDetails();
    }
  }

  void _updateMapWithRoute() async {
    // Use stored coordinates or fallback
    _pickupCoordinates ??= _currentLocation;
    _destinationCoordinates ??= LatLng(
      _currentLocation.latitude + 0.01,
      _currentLocation.longitude + 0.01,
    );

    AppLogger.log('🗺️ Getting real route path...');

    // Get the actual route polyline from Google Directions API
    final routePoints = await _directionsService.getRoutePolyline(
      origin: _pickupCoordinates!,
      destination: _destinationCoordinates!,
    );

    AppLogger.log('✅ Got ${routePoints.length} route points');

    // Create custom marker icons from widgets
    final pickupIcon = await _createBitmapDescriptorFromWidget(
      _buildPickupMarkerWidget(),
      size: Size(247.w, 50.h),
    );

    final dropoffIcon = await _createBitmapDescriptorFromWidget(
      _buildDropoffMarkerWidget(),
      size: Size(242.w, 48.h),
    );

    // Create markers with custom icons
    final markers = <Marker>{
      Marker(
        markerId: MarkerId('pickup'),
        position: _pickupCoordinates!,
        icon: pickupIcon,
        anchor: Offset(0.5, 1.0),
      ),
      Marker(
        markerId: MarkerId('dropoff'),
        position: _destinationCoordinates!,
        icon: dropoffIcon,
        anchor: Offset(0.5, 1.0),
      ),
    };

    // Add stop marker if stop address is provided
    if (stopController.text.isNotEmpty) {
      final stopIcon = await _createBitmapDescriptorFromWidget(
        _buildStopMarkerWidget(),
        size: Size(200.w, 40.h),
      );

      // Calculate stop position between pickup and destination
      final stopLat =
          (_pickupCoordinates!.latitude + _destinationCoordinates!.latitude) /
          2;
      final stopLng =
          (_pickupCoordinates!.longitude + _destinationCoordinates!.longitude) /
          2;
      _stopCoordinates = LatLng(stopLat, stopLng);

      markers.add(
        Marker(
          markerId: MarkerId('stop'),
          position: _stopCoordinates!,
          icon: stopIcon,
          anchor: Offset(0.5, 1.0),
        ),
      );
    }

    // Create polyline with actual route points
    final polylines = <Polyline>{
      Polyline(
        polylineId: PolylineId('route'),
        points: routePoints,
        color: Color(ConstColors.mainColor),
        width: 5,
        geodesic: true,
      ),
    };

    setState(() {
      _mapMarkers = markers;
      _mapPolylines = polylines;
    });

    // Fit map to show all locations with padding
    if (_mapController != null) {
      final allLatitudes = [
        _pickupCoordinates!.latitude,
        _destinationCoordinates!.latitude,
      ];
      final allLongitudes = [
        _pickupCoordinates!.longitude,
        _destinationCoordinates!.longitude,
      ];

      if (_stopCoordinates != null) {
        allLatitudes.add(_stopCoordinates!.latitude);
        allLongitudes.add(_stopCoordinates!.longitude);
      }

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              allLatitudes.reduce(math.min),
              allLongitudes.reduce(math.min),
            ),
            northeast: LatLng(
              allLatitudes.reduce(math.max),
              allLongitudes.reduce(math.max),
            ),
          ),
          100.0,
        ),
      );
    }
  }

  void _showVehicleSelection() async {
    // Get estimate data first
    try {
      await _estimateRide();
    } catch (e) {
      AppLogger.log('Failed to get estimate: $e');
      return;
    }

    if (_currentEstimate == null) return;

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
                ..._buildVehicleOptions(setModalState),
                SizedBox(height: 30.h),
                Container(
                  width: 353.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: selectedVehicle != null
                        ? Color(ConstColors.mainColor)
                        : Color(ConstColors.fieldColor),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: GestureDetector(
                    onTap: selectedVehicle != null
                        ? () {
                            Navigator.pop(context);
                            _showBookingDetails();
                          }
                        : null,
                    child: Center(
                      child: Text(
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

  List<Widget> _buildVehicleOptions(StateSetter setModalState) {
    if (_currentEstimate?.priceList == null) return [];

    List<Widget> options = [];

    for (int i = 0; i < _currentEstimate!.priceList.length; i++) {
      final priceData = _currentEstimate!.priceList[i];
      final vehicleType = priceData['vehicle_type'];
      final totalFare = priceData['total_fare'];

      String title = '';
      switch (vehicleType) {
        case 'regular':
          title = 'Regular vehicle';
          break;
        case 'fancy':
          title = 'Fancy vehicle';
          break;
        case 'vip':
          title = 'VIP';
          break;
      }

      final isSelected = selectedVehicle == i;

      options.add(
        GestureDetector(
          onTap: () {
            setState(() {
              selectedVehicle = i;
            });
            setModalState(() {});
          },
          child: Container(
            width: 353.w,
            height: 65.h,
            margin: EdgeInsets.only(bottom: 15.h),
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            decoration: BoxDecoration(
              color: isSelected
                  ? Color(ConstColors.mainColor)
                  : Colors.transparent,
              border: Border.all(
                color: isSelected
                    ? Color(ConstColors.mainColor)
                    : Colors.grey.shade300,
                width: 0.7,
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Image.asset(ConstImages.car, width: 55.w, height: 26.h),
                SizedBox(width: 15.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: ConstTextStyles.vehicleTitle.copyWith(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        '${_currentEstimate!.durationMin.round()} min | 4 passengers',
                        style: ConstTextStyles.vehicleSubtitle.copyWith(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_currentEstimate!.currency}${totalFare.toStringAsFixed(0)}',
                  style: ConstTextStyles.vehicleTitle.copyWith(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return options;
  }

  void _showBookingDetails() async {
    // Reset booking state
    _isBookingRide = false;

    // Get estimate data first
    try {
      await _estimateRide();
    } catch (e) {
      AppLogger.log('Failed to get estimate: $e');
      return;
    }

    if (_currentEstimate == null) return;

    // Set default vehicle if none selected
    if (selectedVehicle == null) {
      setState(() {
        selectedVehicle = 0; // Default to first vehicle (Regular vehicle)
      });
    }

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
                    selectedVehicle != null
                        ? ConstImages.car
                        : ConstImages.bike,
                    width: 55.w,
                    height: 26.h,
                  ),
                  SizedBox(width: 15.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedOption,
                          style: ConstTextStyles.vehicleTitle,
                        ),
                        Text(
                          '4 passengers',
                          style: ConstTextStyles.vehicleSubtitle,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _currentEstimate != null && selectedVehicle != null
                            ? '${_currentEstimate!.currency}${_currentEstimate!.priceList[selectedVehicle!]['total_fare'].toStringAsFixed(0)}'
                            : '₦12,000',
                        style: ConstTextStyles.vehicleTitle,
                      ),
                      Text(
                        _currentEstimate != null
                            ? '${_currentEstimate!.durationMin.round()} min'
                            : 'Fixed',
                        style: ConstTextStyles.fixedPrice.copyWith(
                          color: Color(ConstColors.recentLocationColor),
                        ),
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
                    Image.asset(ConstImages.wallet, width: 24.w, height: 24.h),
                    SizedBox(width: 15.w),
                    Expanded(
                      child: Text(
                        selectedPaymentMethod,
                        style: ConstTextStyles.vehicleTitle,
                      ),
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
                    onTap: !_isBookingRide
                        ? () async {
                            // Reset scheduled ride state when booking now
                            setState(() {
                              isScheduledRide = false;
                            });

                            if (selectedPaymentMethod == 'Pay with card') {
                              setBookingState(() {
                                _isBookingRide = true;
                              });

                              try {
                                AppLogger.log(
                                  '💳 BOOK NOW - CARD PAYMENT: Starting ride request...',
                                );
                                AppLogger.log(
                                  '💳 Selected Payment Method: $selectedPaymentMethod',
                                );
                                // Combine selected date and time into DateTime for scheduled rides
                                final scheduledDateTime = isScheduledRide
                                    ? DateTime(
                                        selectedDate.year,
                                        selectedDate.month,
                                        selectedDate.day,
                                        selectedTime.hour,
                                        selectedTime.minute,
                                      )
                                    : null;
                                _currentRideResponse = await _requestRide(
                                  isScheduled: isScheduledRide,
                                  scheduledDateTime: scheduledDateTime,
                                );

                                if (_currentRideResponse != null) {
                                  AppLogger.log(
                                    '✅ Ride request successful for card payment',
                                  );
                                  AppLogger.log(
                                    '🎫 Ride ID: ${_currentRideResponse!.id}',
                                  );
                                  AppLogger.log(
                                    '💰 Ride Price: ${_currentRideResponse!.price}',
                                  );

                                  final paymentData = await _paymentService
                                      .initializePayment(
                                        rideId: _currentRideResponse!.id,
                                        amount: _currentRideResponse!.price,
                                      );

                                  if (paymentData['authorization_url'] !=
                                      null) {
                                    AppLogger.log(
                                      '🌐 Opening payment webview',
                                      tag: 'BOOK_NOW',
                                    );

                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PaymentWebViewScreen(
                                          authorizationUrl:
                                              paymentData['authorization_url'],
                                          reference: paymentData['reference'],
                                          onPaymentSuccess: () {},
                                        ),
                                      ),
                                    );

                                    // Handle payment result
                                    if (result == true) {
                                      if (mounted) {
                                        // Clear form fields
                                        fromController.clear();
                                        toController.clear();
                                        setState(() {
                                          _showDestinationField = false;
                                        });

                                        // Close booking details sheet
                                        Navigator.pop(context);

                                        // Show booking request sheet
                                        // Show appropriate sheet based on ride type
                                        if (isScheduledRide) {
                                          // Store addresses before clearing
                                          final pickupAddress =
                                              fromController.text.isNotEmpty
                                              ? fromController.text
                                              : 'Current location';
                                          final destAddress =
                                              toController.text.isNotEmpty
                                              ? toController.text
                                              : 'Destination';
                                          _showTripScheduledSheet(
                                            pickupAddress: pickupAddress,
                                            destAddress: destAddress,
                                          );
                                          // Reset scheduled ride flag
                                          setState(() {
                                            isScheduledRide = false;
                                          });
                                        } else {
                                          _showBookingRequestSheet();
                                        }
                                      }
                                    } else {}
                                  }
                                }
                              } catch (e) {
                                AppLogger.error(
                                  '❌ Card payment failed',
                                  error: e,
                                  tag: 'BOOK_NOW',
                                );

                                if (mounted) {
                                  // Check if error is about active ride
                                  final errorMessage = e.toString();
                                  if (errorMessage.contains('active ride') ||
                                      errorMessage.contains(
                                        'complete it before',
                                      )) {
                                    // Show alert dialog for active ride error
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              15.r,
                                            ),
                                          ),
                                          title: Row(
                                            children: [
                                              Icon(
                                                Icons.warning_amber_rounded,
                                                color: Colors.orange,
                                                size: 28.sp,
                                              ),
                                              SizedBox(width: 10.w),
                                              Text(
                                                'Active Ride',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 18.sp,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          content: Text(
                                            'You already have an active ride. Please complete or cancel your current ride before requesting a new one.',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 14.sp,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: Text(
                                                'OK',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(
                                                    ConstColors.mainColor,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  } else {
                                    // Show generic error snackbar for other errors
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to book ride. Please try again.',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }

                              if (mounted) {
                                setBookingState(() {
                                  _isBookingRide = false;
                                });
                              }
                            } else {
                              AppLogger.log(
                                '🚗 OTHER PAYMENT METHOD: $selectedPaymentMethod',
                                tag: 'BOOK_NOW',
                              );

                              setBookingState(() {
                                _isBookingRide = true;
                              });
                              try {
                                AppLogger.log(
                                  '🚗 BOOK NOW - OTHER PAYMENT: Starting ride request...',
                                );
                                AppLogger.log(
                                  '💳 Selected Payment Method: $selectedPaymentMethod',
                                );
                                // Combine selected date and time into DateTime for scheduled rides
                                final scheduledDateTime = isScheduledRide
                                    ? DateTime(
                                        selectedDate.year,
                                        selectedDate.month,
                                        selectedDate.day,
                                        selectedTime.hour,
                                        selectedTime.minute,
                                      )
                                    : null;
                                _currentRideResponse = await _requestRide(
                                  isScheduled: isScheduledRide,
                                  scheduledDateTime: scheduledDateTime,
                                );

                                if (mounted) {
                                  AppLogger.log(
                                    '✅ Ride request successful for other payment method',
                                  );
                                  AppLogger.log(
                                    '🎫 Ride ID: ${_currentRideResponse!.id}',
                                  );
                                  AppLogger.log(
                                    '💰 Ride Price: ${_currentRideResponse!.price}',
                                  );
                                  fromController.clear();
                                  toController.clear();
                                  setState(() {
                                    _showDestinationField = false;
                                  });
                                  Navigator.pop(context);
                                  // Show appropriate sheet based on ride type
                                  if (isScheduledRide) {
                                    // Store addresses before clearing
                                    final pickupAddress =
                                        fromController.text.isNotEmpty
                                        ? fromController.text
                                        : 'Current location';
                                    final destAddress =
                                        toController.text.isNotEmpty
                                        ? toController.text
                                        : 'Destination';
                                    _showTripScheduledSheet(
                                      pickupAddress: pickupAddress,
                                      destAddress: destAddress,
                                    );
                                    // Reset scheduled ride flag
                                    setState(() {
                                      isScheduledRide = false;
                                    });
                                  } else {
                                    _showBookingRequestSheet();
                                  }
                                }
                              } catch (e) {
                                AppLogger.error(
                                  '❌ OTHER PAYMENT - Ride request failed',
                                  error: e,
                                  tag: 'BOOK_NOW',
                                );
                                if (mounted) {
                                  setBookingState(() {
                                    _isBookingRide = false;
                                  });

                                  // Check if error is about active ride
                                  final errorMessage = e.toString();
                                  if (errorMessage.contains('active ride') ||
                                      errorMessage.contains(
                                        'complete it before',
                                      )) {
                                    // Show alert dialog for active ride error
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              15.r,
                                            ),
                                          ),
                                          title: Row(
                                            children: [
                                              Icon(
                                                Icons.warning_amber_rounded,
                                                color: Colors.orange,
                                                size: 28.sp,
                                              ),
                                              SizedBox(width: 10.w),
                                              Text(
                                                'Active Ride',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 18.sp,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          content: Text(
                                            'You already have an active ride. Please complete or cancel your current ride before requesting a new one.',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 14.sp,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: Text(
                                                'OK',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(
                                                    ConstColors.mainColor,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  } else {
                                    // Show generic error snackbar for other errors
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to book ride. Please try again.',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            }
                          }
                        : null,
                    child: Container(
                      width: 170.w,
                      height: isScheduledRide ? 55.h : 47.h,
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : isScheduledRide
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Confirm Booking',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${selectedDate.day} ${_getMonth(selectedDate.month)} ${selectedTime.format(context)}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
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
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
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
            // Promo code container
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PromoCodeScreen(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Apply 20% off promo code',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '>>>',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
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
        AppLogger.log(
          '💳 Payment method selected: $method',
          tag: 'PAYMENT_METHOD',
        );
        AppLogger.log('💳 Previous payment method: $selectedPaymentMethod');
        setState(() {
          selectedPaymentMethod = method;
        });
        AppLogger.log('💳 New payment method set: $selectedPaymentMethod');
        Navigator.pop(context);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 15.h),
        child: Row(
          children: [
            Expanded(child: Text(method, style: ConstTextStyles.vehicleTitle)),
            if (isSelected) Icon(Icons.check, color: Colors.green, size: 20.sp),
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
        builder: (context, setNoteState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
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
                SizedBox(height: 20.h),
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
                    onTap: noteController.text.isNotEmpty
                        ? () {
                            Navigator.pop(context);
                          }
                        : null,
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
                    height: 24.h,
                  ),
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
                    selectedTime.format(context),
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
                          // Set the scheduled ride flag
                          setState(() {
                            isScheduledRide = true;
                          });
                          // Close prebook sheet
                          Navigator.pop(context);
                          // Show booking details sheet
                          _showBookingDetails();
                        },
                        child: Center(
                          child: Text(
                            'Set pickup date and time',
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
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[weekday - 1];
  }

  String _getMonth(int month) {
    const months = [
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
    return months[month - 1];
  }

  void _showDriverAcceptedSheet() {
    if (_isActiveRideSheetVisible) return;
    _isActiveRideSheetVisible = true;

    final bool hasArrived =
        _activeRide?['Status']?.toString().toLowerCase() == 'arrived';
    final bool hasStarted =
        _activeRide?['Status']?.toString().toLowerCase() == 'started';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
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
            Container(
              width: 69.w,
              height: 5.h,
              margin: EdgeInsets.only(bottom: 10.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.5.r),
              ),
            ),
            // Header with title and cancel button
            Row(
              children: [
                // Only show timer when driver is on the way (not arrived, not started)
                if (!hasStarted && !hasArrived) ...[
                  Stack(
                    children: [
                      Container(
                        width: 60.w,
                        height: 60.h,
                        decoration: BoxDecoration(
                          color: Color(ConstColors.mainColor),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _driverArrivalTime,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // White line decoration at top right
                      Positioned(
                        top: 0,
                        left: 11.w,
                        child: Image.asset(
                          'assets/images/whiteline.png',
                          width: 20.w,
                          height: 20.h,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 15.w),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasStarted
                            ? 'Enjoy your trip'
                            : hasArrived
                            ? 'Your driver has arrived'
                            : 'Driver is on the way',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Divider(thickness: 1, color: Colors.grey.shade300),
                    ],
                  ),
                ),
                if (hasArrived)
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      size: 24.sp,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
            // Driver Details
            Column(
              children: [
                if (_assignedDriver != null) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: _buildDriverDetail(
                      'Driver name:',
                      _assignedDriver!.name,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  if (!hasStarted) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Row(
                        children: [
                          Text(
                            'Driver rating:',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                              height: 1.0,
                              letterSpacing: -0.32,
                            ),
                          ),
                          Spacer(),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 16.sp,
                                color: Colors.amber,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                _assignedDriver!.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  height: 1.0,
                                  letterSpacing: -0.32,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10.h),
                  ],
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: _buildDriverDetail(
                      'Plate number:',
                      _assignedDriver!.plateNumber,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  if (!hasStarted) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: _buildDriverDetail(
                        'Car:',
                        _assignedDriver!.vehicleModel,
                      ),
                    ),
                    SizedBox(height: 10.h),
                  ],
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: _buildDriverDetail(
                      'Trip ID:',
                      _activeRide?['ID']?.toString() ?? 'N/A',
                    ),
                  ),
                  SizedBox(height: 20.h),
                  // Payment Method
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Container(
                      width: double.infinity,
                      height: 42.h,
                      padding: EdgeInsets.symmetric(
                        horizontal: 5.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.r),
                        border: Border.all(
                          width: 0.6,
                          color: Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.payment, size: 20.sp),
                              SizedBox(width: 8.w),
                              Text(
                                selectedPaymentMethod,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  // Action Buttons
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: SizedBox(
                      width: double.infinity,
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                if (hasStarted) {
                                  // SOS functionality
                                  if (_activeRide != null) {
                                    try {
                                      // Show loading indicator
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) => Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );

                                      // Get current location
                                      final position =
                                          await Geolocator.getCurrentPosition(
                                            desiredAccuracy:
                                                LocationAccuracy.high,
                                          );

                                      // Get address from coordinates
                                      String locationAddress =
                                          'Unknown location';
                                      try {
                                        final placemarks =
                                            await placemarkFromCoordinates(
                                              position.latitude,
                                              position.longitude,
                                            );
                                        if (placemarks.isNotEmpty) {
                                          final placemark = placemarks.first;
                                          locationAddress =
                                              '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}';
                                        }
                                      } catch (e) {
                                        AppLogger.log(
                                          'Failed to get address: $e',
                                          tag: 'SOS',
                                        );
                                      }

                                      // Format location as POINT
                                      final location =
                                          'POINT(${position.longitude} ${position.latitude})';

                                      // Get ride ID
                                      final rideId = _activeRide?['ID'] is int
                                          ? _activeRide!['ID']
                                          : int.parse(
                                              _activeRide?['ID']?.toString() ??
                                                  '0',
                                            );

                                      // Send SOS
                                      final result = await _rideService.sendSOS(
                                        location: location,
                                        locationAddress: locationAddress,
                                        rideId: rideId,
                                      );

                                      // Close loading dialog
                                      Navigator.pop(context);

                                      // Show result
                                      if (result['success'] == true) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '🆘 SOS alert sent successfully!',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to send SOS: ${result['message']}',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      // Close loading dialog if still open
                                      Navigator.pop(context);

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error sending SOS: $e',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      AppLogger.error(
                                        'SOS Error',
                                        error: e,
                                        tag: 'SOS',
                                      );
                                    }
                                  }
                                } else if (hasArrived) {
                                  // Cancel functionality - show dialog
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CallScreen(
                                        driverName: _assignedDriver!.name,
                                        rideId: _activeRide?['ID'] is int
                                            ? _activeRide!['ID']
                                            : int.parse(
                                                _activeRide?['ID']
                                                        ?.toString() ??
                                                    '0',
                                              ),
                                      ),
                                    ),
                                  );
                                } else {
                                  // Call Driver functionality
                                  if (_assignedDriver != null &&
                                      _activeRide != null) {
                                    _showCancelRideDialog();
                                  }
                                }
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    hasStarted
                                        ? Icons.sos
                                        : hasArrived
                                        ? Icons.call
                                        : Icons.cancel,
                                    size: 16.sp,
                                    color: Colors.black,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    hasStarted
                                        ? 'SOS'
                                        : hasArrived
                                        ? 'Call Driver'
                                        : 'Cancel',
                                    style: TextStyle(
                                      color: !hasArrived
                                          ? Colors.black
                                          : Colors.red,
                                      fontFamily: 'Inter',
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w400,
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
                              onTap: () async {
                                if (hasStarted) {
                                  // Share location functionality
                                  try {
                                    // Get current location
                                    final position =
                                        await Geolocator.getCurrentPosition(
                                          desiredAccuracy:
                                              LocationAccuracy.high,
                                        );

                                    // Create Google Maps link
                                    final lat = position.latitude;
                                    final lng = position.longitude;
                                    final mapsUrl =
                                        'https://www.google.com/maps?q=$lat,$lng';

                                    // Get address if possible
                                    String locationInfo = 'My current location';
                                    try {
                                      final placemarks =
                                          await placemarkFromCoordinates(
                                            lat,
                                            lng,
                                          );
                                      if (placemarks.isNotEmpty) {
                                        final placemark = placemarks.first;
                                        locationInfo =
                                            '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}';
                                      }
                                    } catch (e) {
                                      AppLogger.log(
                                        'Failed to get address: $e',
                                        tag: 'SHARE',
                                      );
                                    }

                                    // Share the location
                                    await Share.share(
                                      '📍 I\'m currently here:\n$locationInfo\n\n🗺️ View on map: $mapsUrl',
                                      subject: 'My Location',
                                    );
                                  } catch (e) {
                                    AppLogger.error(
                                      'Share location error',
                                      error: e,
                                      tag: 'SHARE',
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to share location: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } else {
                                  // Chat functionality
                                  if (_assignedDriver != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatScreen(
                                          rideId: _activeRide?['ID'] is int
                                              ? _activeRide!['ID']
                                              : int.parse(
                                                  _activeRide?['ID']
                                                          ?.toString() ??
                                                      '0',
                                                ),
                                          driverId: _assignedDriver?.id ?? '0',

                                          driverName:
                                              _assignedDriver?.name ?? 'Driver',
                                          driverImage:
                                              _assignedDriver?.profilePicture,
                                          driverPhone:
                                              _assignedDriver?.phoneNumber,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    hasStarted ? Icons.share : Icons.chat,
                                    size: 16.sp,
                                    color: Colors.black,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    hasStarted ? 'Share' : 'Chat Driver',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      _isActiveRideSheetVisible = false;
      _hasUserDismissedSheet = true;
    });
  }

  Widget _buildDriverDetail(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            height: 1.0,
            letterSpacing: -0.32,
          ),
        ),
        Spacer(),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            height: 1.0,
            letterSpacing: -0.32,
          ),
        ),
      ],
    );
  }

  void _showCancelRideDialog() {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Cancel Ride',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⚠️ Please note that charges may apply if you cancel the ride now.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.red[700],
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Please tell us why you want to cancel:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: reasonController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Enter your reason here...',
                  hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.sp,
                    color: Colors.grey[400],
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: Color(ConstColors.mainColor),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: Color(ConstColors.mainColor),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                reasonController.dispose();
              },
              child: Text(
                'Back',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final reason = reasonController.text.trim();

                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please provide a reason for cancellation'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Close dialog
                Navigator.of(context).pop();
                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Center(
                    child: CircularProgressIndicator(
                      color: Color(ConstColors.mainColor),
                    ),
                  ),
                );

                try {
                  // Get ride ID
                  final rideId = _activeRide?['ID'] is int
                      ? _activeRide!['ID']
                      : int.parse(_activeRide?['ID']?.toString() ?? '0');

                  // Call cancel API
                  final result = await _rideService.cancelRide(
                    rideId: rideId,
                    reason: reason,
                  );

                  // Close loading dialog using root navigator
                  if (mounted) {
                    Navigator.of(context, rootNavigator: true).pop();
                  }

                  if (result['success'] == true) {
                    if (mounted) {
                      // Clear active ride state
                      setState(() {
                        _activeRide = null;
                        _isDriverAssigned = false;
                        _isRideAccepted = false;
                        _isInCar = false;
                        _assignedDriver = null;
                        _mapMarkers = {};
                        _mapPolylines = {};
                      });

                      // Stop tracking
                      _stopDriverLocationTracking();

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Ride cancelled successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    if (mounted) {
                      // Show error
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            result['message'] ?? 'Failed to cancel ride',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  // Close loading dialog using root navigator
                  if (mounted) {
                    Navigator.of(context, rootNavigator: true).pop();
                  }

                  AppLogger.error('Cancel ride error', error: e, tag: 'CANCEL');

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error cancelling ride: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }

                reasonController.dispose();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(ConstColors.mainColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
              child: Text(
                'Submit',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
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
                          _currentRideResponse?.pickupAddress ??
                              'Pickup Location',
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
              'Booking Successful',
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
            SizedBox(
              width: 353.w,
              height: 10.h,
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(ConstColors.mainColor),
                ),
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
    final selectedOption =
        _currentRideResponse?.vehicleType ??
        (selectedVehicle != null
            ? ['Regular vehicle', 'Fancy vehicle', 'VIP'][selectedVehicle!]
            : ['Bicycle', 'Vehicle', 'Motor bike'][selectedDelivery!]);
    final currentDate =
        '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} at ${TimeOfDay.now().format(context)}';
    final paymentMethod =
        _currentRideResponse?.paymentMethod
            .replaceAll('_', ' ')
            .replaceAll('pay', 'Pay') ??
        selectedPaymentMethod;
    final pickupAddr = _currentRideResponse?.pickupAddress ?? 'Pickup Location';
    final destAddr = _currentRideResponse?.destAddress ?? 'Destination';
    final vehicleType = _currentRideResponse?.vehicleType ?? selectedOption;
    final ridePrice =
        _currentRideResponse?.price.toStringAsFixed(0) ?? '12,000';

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
                          pickupAddr,
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
                          destAddr,
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
                  currentDate,
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
                          paymentMethod,
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
                      '₦${_currentRideResponse?.price.toStringAsFixed(0) ?? '12,000'}',
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
              SizedBox(
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
                          if (_assignedDriver != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  driverId: _assignedDriver?.id ?? '0',
                                  rideId: _activeRide?['ID'] is int
                                      ? _activeRide!['ID']
                                      : int.parse(
                                          _activeRide?['ID']?.toString() ?? '0',
                                        ),
                                  driverName: _assignedDriver?.name ?? 'Driver',
                                  driverImage: _assignedDriver?.profilePicture,
                                  driverPhone: _assignedDriver?.phoneNumber,
                                  // rideId:
                                  //     .toString() ??_currentRideResponse?.id
                                  //     '12345',
                                  // currentUserId:
                                  //     'user_123', // This should come from auth service
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('No driver assigned yet')),
                            );
                          }
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

  void _showTripScheduledSheet({String? pickupAddress, String? destAddress}) {
    final selectedOption = selectedVehicle != null
        ? ['Regular vehicle', 'Fancy vehicle', 'VIP'][selectedVehicle!]
        : ['Bicycle', 'Vehicle', 'Motor bike'][selectedDelivery!];

    // Format the scheduled date and time
    final scheduledDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    final formattedDate =
        '${_getMonth(scheduledDateTime.month)} ${scheduledDateTime.day}, ${scheduledDateTime.year} at ${selectedTime.format(context)}';

    // Get the price from the current estimate
    final price = _currentEstimate != null && selectedVehicle != null
        ? '${_currentEstimate!.currency}${_currentEstimate!.priceList[selectedVehicle!]['total_fare'].toStringAsFixed(0)}'
        : '₦12,000';

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
                          pickupAddress ?? 'Current location',
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
                          destAddress ?? 'Destination',
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
                  formattedDate,
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
                      price,
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
    // Format the scheduled date and time
    final scheduledDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    final formattedDate =
        '${_getMonth(scheduledDateTime.month)} ${scheduledDateTime.day}, ${scheduledDateTime.year} at ${selectedTime.format(context)}';

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
              _buildEditField(
                'PICK UP',
                fromController.text.isNotEmpty
                    ? fromController.text
                    : 'Current location',
              ),
              SizedBox(height: 15.h),
              _buildEditField('DESTINATION', toController.text),
              SizedBox(height: 15.h),
              _buildEditField('WHEN', formattedDate),
              SizedBox(height: 15.h),
              _buildEditField('PAYMENT METHOD', selectedPaymentMethod),
              SizedBox(height: 15.h),
              _buildEditField(
                'VEHICLE',
                selectedVehicle != null
                    ? [
                        'Regular vehicle',
                        'Fancy vehicle',
                        'VIP',
                      ][selectedVehicle!]
                    : ['Bicycle', 'Vehicle', 'Motor bike'][selectedDelivery!],
              ),
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
              _buildCancelReason(
                0,
                'I am taking alternative transport',
                setCancelState,
              ),
              SizedBox(height: 10.h),
              _buildCancelReason(
                1,
                'It is taking too long to get a driver',
                setCancelState,
              ),
              SizedBox(height: 10.h),
              _buildCancelReason(
                2,
                'I have to attend to something',
                setCancelState,
              ),
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
                  onTap: selectedCancelReason != null
                      ? () {
                          Navigator.pop(context);
                          _showFeedbackSuccessSheet();
                        }
                      : null,
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

  Widget _buildCancelReason(
    int index,
    String reason,
    StateSetter setCancelState,
  ) {
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

  void _showTripCompletedSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
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
              'Trip completed',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20.h),
            Divider(thickness: 1, color: Colors.grey.shade300),
            SizedBox(height: 20.h),
            _buildDriverDetail(
              'Trip ID:',
              _activeRide?['ID']?.toString() ?? 'N/A',
            ),
            SizedBox(height: 10.h),
            _buildDriverDetail(
              'Fare:',
              '₦${_activeRide?['Price']?.toStringAsFixed(0) ?? '0'}',
            ),
            SizedBox(height: 10.h),
            _buildDriverDetail(
              'Tip:',
              '₦${_activeRide?['Tip']?.toStringAsFixed(0) ?? '0'}',
            ),
            SizedBox(height: 10.h),
            _buildDriverDetail(
              'Total:',
              '₦${((_activeRide?['Price'] ?? 0) + (_activeRide?['Tip'] ?? 0)).toStringAsFixed(0)}',
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
                  _showRatingSheet();
                },
                child: Center(
                  child: Text(
                    'Dismiss',
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

  // void _showIncomingCallNotification(Map<String, dynamic> callData) {
  //   final driverName = callData['caller_name'] ?? 'Driver';
  //   final sessionId = callData['session_id'];
  //   final rideId = callData['ride_id'];

  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) => AlertDialog(
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(20.r),
  //       ),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Icon(
  //             Icons.phone_in_talk,
  //             size: 60.sp,
  //             color: Color(ConstColors.mainColor),
  //           ),
  //           SizedBox(height: 20.h),
  //           Text(
  //             'Incoming Call',
  //             style: TextStyle(
  //               fontFamily: 'Inter',
  //               fontSize: 20.sp,
  //               fontWeight: FontWeight.w600,
  //             ),
  //           ),
  //           SizedBox(height: 10.h),
  //           Text(
  //             driverName,
  //             style: TextStyle(
  //               fontFamily: 'Inter',
  //               fontSize: 16.sp,
  //               fontWeight: FontWeight.w400,
  //             ),
  //           ),
  //           SizedBox(height: 30.h),
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //             children: [
  //               GestureDetector(
  //                 onTap: () async {
  //                   Navigator.pop(context);
  //                   await _rejectCall(sessionId);
  //                 },
  //                 child: Container(
  //                   width: 60.w,
  //                   height: 60.h,
  //                   decoration: BoxDecoration(
  //                     color: Colors.red,
  //                     shape: BoxShape.circle,
  //                   ),
  //                   child: Icon(
  //                     Icons.call_end,
  //                     color: Colors.white,
  //                     size: 30.sp,
  //                   ),
  //                 ),
  //               ),
  //               GestureDetector(
  //                 onTap: () {
  //                   Navigator.pop(context);
  //                   Navigator.push(
  //                     context,
  //                     MaterialPageRoute(
  //                       builder: (context) =>
  //                           CallScreen(driverName: driverName, rideId: rideId),
  //                     ),
  //                   );
  //                 },
  //                 child: Container(
  //                   width: 60.w,
  //                   height: 60.h,
  //                   decoration: BoxDecoration(
  //                     color: Colors.green,
  //                     shape: BoxShape.circle,
  //                   ),
  //                   child: Icon(Icons.call, color: Colors.white, size: 30.sp),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Future<void> _rejectCall(int sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      await http.post(
        Uri.parse('http://44.222.121.219/api/v1/calls/$sessionId/reject'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      AppLogger.log('❌ Call rejected', tag: 'CALL');
    } catch (e) {
      AppLogger.error('Failed to reject call', error: e, tag: 'CALL');
    }
  }

  void _showTripCompleteSheet(int rideId, String price) {
    AppLogger.log(
      '📊 Opening Trip Complete sheet for ride ID: $rideId',
      tag: 'RIDE',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
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
              'Trip Complete',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 30.h),

            // Trip ID
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trip ID',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16.sp,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '#$rideId',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 15.h),

            // Fare
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fare',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16.sp,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '₦$price',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 15.h),
            Divider(color: Colors.grey.shade300),
            SizedBox(height: 15.h),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '₦$price',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: Color(ConstColors.mainColor),
                  ),
                ),
              ],
            ),
            SizedBox(height: 40.h),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50.h,
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(ConstColors.mainColor)),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TipScreen(rideId: rideId),
                          ),
                        );
                      },
                      child: Text(
                        'Tip Driver',
                        style: TextStyle(
                          color: Color(ConstColors.mainColor),
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 15.w),
                Expanded(
                  child: Container(
                    height: 50.h,
                    decoration: BoxDecoration(
                      color: Color(ConstColors.mainColor),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: TextButton(
                      onPressed: () async {
                        try {
                          Navigator.pop(context); // Close trip sheet

                          // We can check if dismiss is needed or just proceed to rate
                          // Assuming dismiss marks it as 'Driver Reviewed' in backend logic or something
                          // But typically user dismisses the completion sheet to see rating.

                          // Call dismiss API
                          await _rideService.dismissRide(rideId);

                          if (mounted) {
                            _showRatingSheet();
                          }
                        } catch (e) {
                          AppLogger.error(
                            'Failed to dismiss ride',
                            error: e,
                            tag: 'RIDE',
                          );
                          // Proceed to rating anyway as fallback
                          if (mounted) {
                            _showRatingSheet();
                          }
                        }
                      },
                      child: Text(
                        'Dismiss',
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
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  void _showRatingSheet() {
    int selectedRating = 0;
    final reviewController = TextEditingController();
    bool isSubmitting = false;
    final currentRideId = _lastCompletedRideId;

    AppLogger.log(
      '📊 Opening rating sheet for ride ID: $currentRideId',
      tag: 'RATING',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setRatingState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: SingleChildScrollView(
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
                  Text(
                    'Rate your trip with ${_assignedDriver?.name ?? "Driver"}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Divider(thickness: 1, color: Colors.grey.shade300),
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setRatingState(() {
                            selectedRating = index + 1;
                          });
                        },
                        child: Icon(
                          index < selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          size: 40.sp,
                          color: Colors.amber,
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 20.h),
                  Container(
                    width: 353.w,
                    height: 111.h,
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Color(0xFFB1B1B1).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: TextField(
                      controller: reviewController,
                      maxLines: null,
                      expands: true,
                      onChanged: (value) {
                        setRatingState(() {});
                      },
                      decoration: InputDecoration(
                        hintText: 'Write a review...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Container(
                    width: 353.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: selectedRating > 0
                          ? Color(ConstColors.mainColor)
                          : Color(ConstColors.fieldColor),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: GestureDetector(
                      onTap: selectedRating > 0 && !isSubmitting
                          ? () async {
                              AppLogger.log(
                                '🔘 Submit button pressed',
                                tag: 'RATING',
                              );
                              AppLogger.log(
                                'Rating: $selectedRating',
                                tag: 'RATING',
                              );
                              AppLogger.log(
                                'Comment: ${reviewController.text}',
                                tag: 'RATING',
                              );
                              AppLogger.log(
                                'Current Ride ID: $currentRideId',
                                tag: 'RATING',
                              );

                              if (currentRideId == null) {
                                AppLogger.log(
                                  '❌ No ride ID available!',
                                  tag: 'RATING',
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: No ride ID found'),
                                    ),
                                  );
                                }
                                return;
                              }

                              setRatingState(() {
                                isSubmitting = true;
                              });

                              try {
                                AppLogger.log(
                                  '📤 Calling rateRide API with ID: $currentRideId',
                                  tag: 'RATING',
                                );

                                final result = await _rideService.rateRide(
                                  rideId: currentRideId,
                                  score: selectedRating,
                                  comment: reviewController.text,
                                );

                                AppLogger.log(
                                  '📥 API Response: $result',
                                  tag: 'RATING',
                                );

                                if (result['success'] == true) {
                                  // Mark ride as rated
                                  _dismissedRatingRides.add(currentRideId);

                                  // Schedule the navigation and state update properly
                                  // First, close the dialog
                                  if (mounted) {
                                    Navigator.pop(context);
                                  }

                                  // Then schedule the state update for the next frame
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (mounted) {
                                      setState(() {
                                        _activeRide = null;
                                        _isDriverAssigned = false;
                                        _isRideAccepted = false;
                                        _isInCar = false;
                                        _assignedDriver = null;
                                        _mapMarkers = {};
                                        _mapPolylines = {};
                                      });

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Thank you for your rating!',
                                          ),
                                        ),
                                      );
                                    }
                                  });
                                } else {
                                  if (mounted) {
                                    setRatingState(() {
                                      isSubmitting = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to submit rating',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                AppLogger.log(
                                  '❌ Error submitting rating: $e',
                                  tag: 'RATING',
                                );
                                if (mounted) {
                                  setRatingState(() {
                                    isSubmitting = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            }
                          : null,
                      child: Center(
                        child: isSubmitting
                            ? SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
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
        ),
      ),
    ).whenComplete(() {
      // Schedule controller disposal after the current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        reviewController.dispose();
      });

      // Mark ride as dismissed if user closes without rating
      if (currentRideId != null && selectedRating == 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _dismissedRatingRides.add(currentRideId);
            });
          }
        });
      }
    });
  }

  Widget _buildPickupWidget() {
    // Show when there's an active ride
    if (_activeRide == null) return SizedBox.shrink();

    return Container(
      width: 247.w,
      height: 50.h,
      padding: EdgeInsets.only(right: 12.h, top: 4, bottom: 4),
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
                  'Pick up',
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
    // Show when there's an active ride
    if (_activeRide == null) return SizedBox.shrink();

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
          Image.asset(ConstImages.locationPin, width: 24.w, height: 24.h),
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

  Widget _buildRoutePickupWidget() {
    return Container(
      width: 247.w,
      height: 50.h,
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
              borderRadius: BorderRadius.circular(1000.r),
            ),
            child: Center(
              child: Text(
                _estimatedTime,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  height: 16 / 18,
                  letterSpacing: -0.41,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Pick up',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    height: 22 / 14,
                    letterSpacing: -0.41,
                  ),
                ),
                Text(
                  fromController.text.isNotEmpty
                      ? fromController.text
                      : 'Current location',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    height: 22 / 14,
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

  Widget _buildRouteDropoffWidget() {
    return Container(
      width: 247.w,
      height: 50.h,
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(1000.r),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Center(
              child: Image.asset(
                ConstImages.locationIconPin,
                width: 24.w,
                height: 24.h,
              ),
            ),
          ),
          SizedBox(width: 10.w),
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
                    height: 22 / 14,
                    letterSpacing: -0.41,
                  ),
                ),
                Text(
                  toController.text.isNotEmpty
                      ? toController.text
                      : 'Destination',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    height: 22 / 14,
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

  Future<RideResponse> _requestRide({
    bool isScheduled = false,
    DateTime? scheduledDateTime,
  }) async {
    AppLogger.log('🚗 === STARTING RIDE REQUEST ===');

    if (_currentEstimate == null || selectedVehicle == null) {
      AppLogger.log('❌ Missing estimate or vehicle selection');
      throw Exception('No estimate or vehicle selected');
    }

    final selectedPriceData = _currentEstimate!.priceList[selectedVehicle!];
    final vehicleType = selectedPriceData['vehicle_type'];

    AppLogger.log('🚙 Selected Vehicle Type: $vehicleType');
    AppLogger.log('💰 Selected Price Data: $selectedPriceData');

    // Use actual selected coordinates for pickup and destination
    final pickupLatLng = _pickupCoordinates ?? _currentLocation;
    final destLatLng =
        _destinationCoordinates ??
        LatLng(
          _currentLocation.latitude + 0.01,
          _currentLocation.longitude + 0.01,
        );

    final pickupCoords =
        "POINT(${pickupLatLng.longitude} ${pickupLatLng.latitude})";
    final destCoords = "POINT(${destLatLng.longitude} ${destLatLng.latitude})";

    AppLogger.log(
      '📍 Pickup Coordinates: $pickupCoords (${pickupLatLng.latitude}, ${pickupLatLng.longitude})',
    );
    AppLogger.log(
      '🎯 Destination Coordinates: $destCoords (${destLatLng.latitude}, ${destLatLng.longitude})',
    );
    AppLogger.log('💳 Original Payment Method: "$selectedPaymentMethod"');

    // Fix payment method conversion - "Pay in car" should become "in_car"
    String convertedPaymentMethod;
    if (selectedPaymentMethod == 'Pay in car') {
      convertedPaymentMethod = 'in_car';
    } else {
      convertedPaymentMethod = selectedPaymentMethod.toLowerCase().replaceAll(
        ' ',
        '_',
      );
    }

    AppLogger.log('💳 Converted Payment Method: "$convertedPaymentMethod"');

    // Log scheduled ride information
    if (isScheduled && scheduledDateTime != null) {
      AppLogger.log('📅 Scheduled Ride: true');
      AppLogger.log('⏰ Scheduled At: ${scheduledDateTime.toIso8601String()}');
    }

    // Get destination address - use toController text or reverse geocode
    String destAddress = toController.text;
    if (destAddress.isEmpty && _destinationCoordinates != null) {
      try {
        final placemarks = await placemarkFromCoordinates(
          _destinationCoordinates!.latitude,
          _destinationCoordinates!.longitude,
        );
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          destAddress =
              '${placemark.street}, ${placemark.locality}${placemark.administrativeArea != null ? ', ${placemark.administrativeArea}' : ''}';
          AppLogger.log('📍 Reverse geocoded destination: $destAddress');
        }
      } catch (e) {
        AppLogger.log('⚠️ Failed to reverse geocode destination: $e');
        destAddress = "Destination"; // Fallback only if reverse geocoding fails
      }
    }
    if (destAddress.isEmpty) {
      destAddress = "Destination"; // Final fallback
    }

    final request = RideRequest(
      pickup: pickupCoords,
      dest: destCoords,
      pickupAddress: fromController.text.isNotEmpty
          ? fromController.text
          : "Current location",
      destAddress: destAddress,
      serviceType: _currentEstimate!.serviceType,
      vehicleType: vehicleType,
      paymentMethod: convertedPaymentMethod,
      scheduled: isScheduled ? true : null,
      scheduledAt: isScheduled && scheduledDateTime != null
          ? scheduledDateTime.toUtc().toIso8601String()
          : null,
      stopAddress: stopController.text.isNotEmpty ? stopController.text : null,
      note: noteController.text.isNotEmpty ? noteController.text : null,
    );

    AppLogger.log('📋 Final Ride Request Object:');
    AppLogger.log('  - Pickup: ${request.pickup}');
    AppLogger.log('  - Destination: ${request.dest}');
    AppLogger.log('  - Pickup Address: ${request.pickupAddress}');
    AppLogger.log('  - Destination Address: ${request.destAddress}');
    AppLogger.log('  - Service Type: ${request.serviceType}');
    AppLogger.log('  - Vehicle Type: ${request.vehicleType}');
    AppLogger.log('  - Payment Method: ${request.paymentMethod}');
    if (request.scheduled == true) {
      AppLogger.log('  - Scheduled: ${request.scheduled}');
      AppLogger.log('  - Scheduled At: ${request.scheduledAt}');
    }

    return await _rideService.requestRide(request);
  }

  void _showActiveRideSheet() {
    if (_activeRide == null || _isActiveRideSheetVisible) return;

    _isActiveRideSheetVisible = true;

    final status = _activeRide!['Status']?.toString().toLowerCase() ?? '';
    final rideId = _activeRide!['ID']?.toString() ?? 'Unknown';
    final pickupAddress = _activeRide!['PickupAddress'] ?? 'Pickup location';
    final destAddress = _activeRide!['DestAddress'] ?? 'Destination';
    final price = _activeRide!['Price']?.toString() ?? '0';

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
              margin: EdgeInsets.only(bottom: 20.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.5.r),
              ),
            ),
            Text(
              'Active Ride',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'ID: #$rideId',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              '₦$price',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 36.sp,
                height: 1.0,
                letterSpacing: -0.32,
              ),
            ),
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
                      Expanded(
                        child: Text(
                          'Pickup: $pickupAddress',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
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
                      Expanded(
                        child: Text(
                          'Destination: $destAddress',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: _getStatusColor(status),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'Status: ${status.toUpperCase()}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Spacer(),
            if (_assignedDriver != null)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Color(ConstColors.mainColor)),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                driverId: _assignedDriver?.id ?? '0',
                                rideId: _activeRide?['ID'] is int
                                    ? _activeRide!['ID']
                                    : int.parse(
                                        _activeRide?['ID']?.toString() ?? '0',
                                      ),
                                driverName: _assignedDriver?.name ?? 'Driver',
                                driverImage: _assignedDriver?.profilePicture,
                                driverPhone: _assignedDriver?.phoneNumber,
                              ),
                            ),
                          );
                        },
                        child: Center(
                          child: Text(
                            'Chat Driver',
                            style: TextStyle(
                              color: Color(ConstColors.mainColor),
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Container(
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: Color(ConstColors.mainColor),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          _isActiveRideSheetVisible = false;
                          Navigator.pop(context);
                        },
                        child: Center(
                          child: Text(
                            'Track Ride',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
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
    ).whenComplete(() {
      _isActiveRideSheetVisible = false;
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.blue;
      case 'arrived':
        return Colors.orange;
      case 'started':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  List<LatLng> _generateCurvedPath(LatLng start, LatLng end) {
    List<LatLng> points = [];

    // Calculate midpoint with offset for curve
    double midLat = (start.latitude + end.latitude) / 2;
    double midLng = (start.longitude + end.longitude) / 2;

    // Add curve offset (perpendicular to the line)
    double offsetLat = (end.longitude - start.longitude) * 0.002;
    double offsetLng = (start.latitude - end.latitude) * 0.002;

    LatLng curvePoint = LatLng(midLat + offsetLat, midLng + offsetLng);

    // Generate points along the curve
    for (int i = 0; i <= 20; i++) {
      double t = i / 20.0;
      double lat = _quadraticBezier(
        start.latitude,
        curvePoint.latitude,
        end.latitude,
        t,
      );
      double lng = _quadraticBezier(
        start.longitude,
        curvePoint.longitude,
        end.longitude,
        t,
      );
      points.add(LatLng(lat, lng));
    }

    return points;
  }

  double _quadraticBezier(double p0, double p1, double p2, double t) {
    return (1 - t) * (1 - t) * p0 + 2 * (1 - t) * t * p1 + t * t * p2;
  }

  Map<String, double>? _parsePostGISLocation(String location) {
    try {
      if (location.length >= 50) {
        final hexData = location.substring(18); // Skip SRID part
        final lngHex = hexData.substring(0, 16);
        final latHex = hexData.substring(16, 32);

        final lngBytes = _hexToBytes(lngHex);
        final latBytes = _hexToBytes(latHex);

        final lng = _bytesToDouble(lngBytes);
        final lat = _bytesToDouble(latBytes);

        if (lat != null && lng != null) {
          return {'lat': lat, 'lng': lng};
        }
      }
    } catch (e) {
      AppLogger.log('Error parsing PostGIS location: $e');
    }
    return null;
  }

  List<int> _hexToBytes(String hex) {
    final bytes = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return bytes.reversed.toList(); // Reverse for little-endian
  }

  double? _bytesToDouble(List<int> bytes) {
    if (bytes.length != 8) return null;
    final buffer = Uint8List.fromList(bytes).buffer;
    return ByteData.view(buffer).getFloat64(0, Endian.big);
  }

  /// Get icon for favorite location based on type
  Widget _getFavoriteLocationIcon(String name) {
    final nameLower = name.toLowerCase();

    if (nameLower.contains('home')) {
      return Icon(Icons.home, size: 24.sp, color: Color(ConstColors.mainColor));
    } else if (nameLower.contains('work')) {
      return Icon(Icons.work, size: 24.sp, color: Color(ConstColors.mainColor));
    } else {
      return Icon(Icons.star, size: 24.sp, color: Colors.amber);
    }
  }

  @override
  void dispose() {
    // Stop all timers
    _driverLocationTimer?.cancel();
    _etaUpdateTimer?.cancel();
    _activeRideCheckTimer?.cancel();
    _webSocketService.disconnect();
    _activeRideCheckTimer?.cancel();

    _callService.dispose(); // Add this line

    // Dispose controllers
    fromController.dispose();
    toController.dispose();
    stopController.dispose();
    noteController.dispose();

    super.dispose();
  }
}
