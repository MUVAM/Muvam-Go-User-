import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/app_routes.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/url_constants.dart';
import 'package:muvam/core/services/call_service.dart';
import 'package:muvam/core/services/directions_service.dart';
import 'package:muvam/core/services/favourite_location_service.dart';
import 'package:muvam/core/services/message_notification_handler.dart';
import 'package:muvam/core/services/payment_service.dart';
import 'package:muvam/core/services/places_service.dart';
import 'package:muvam/core/services/ride_service.dart';
import 'package:muvam/core/services/websocket_service.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/core/utils/currency_formatter.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/chat/data/models/chat_model.dart';
import 'package:muvam/features/chat/data/providers/chat_provider.dart';
import 'package:muvam/features/home/data/models/favourite_location_models.dart';
import 'package:muvam/features/home/data/models/ride_models.dart';
import 'package:muvam/features/home/presentation/widgets/active_ride_button.dart';
import 'package:muvam/features/home/presentation/widgets/add_location_tile.dart';
import 'package:muvam/features/home/presentation/widgets/active_ride_marker_helpers.dart';
import 'package:muvam/features/home/presentation/widgets/cancel_reason_option.dart';
import 'package:muvam/features/home/presentation/widgets/delete_location_dialog.dart';
import 'package:muvam/features/home/presentation/widgets/driver_detail_row.dart';
import 'package:muvam/features/home/presentation/widgets/dropoff_marker_widget.dart';
import 'package:muvam/features/home/presentation/widgets/favorite_location_item.dart';
import 'package:muvam/features/home/presentation/widgets/location_suggestions_list.dart';
import 'package:muvam/features/home/presentation/widgets/pickup_marker_widget.dart';
import 'package:muvam/features/home/presentation/widgets/quick_pickup_button.dart';
import 'package:muvam/features/home/presentation/widgets/recent_location_item.dart';
import 'package:muvam/features/home/presentation/widgets/stop_marker_widget.dart';
import 'package:muvam/features/home/presentation/widgets/app_drawer.dart';
import 'package:muvam/features/profile/data/providers/user_profile_provider.dart';
import 'package:muvam/features/wallet/data/providers/wallet_provider.dart';
import 'package:muvam/layouts/providers/location_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isBottomSheetVisible = true;
  bool _showDestinationField = false;
  bool _showStopField = false;
  String? _lastKnownRideStatus;
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
  final PanelController _panelController = PanelController();
  DateTime selectedDate = DateTime.now().add(Duration(days: 1));
  TimeOfDay selectedTime = TimeOfDay.now();
  int? selectedCancelReason;
  bool isScheduledRide = false;
  GoogleMapController? _mapController;
  LatLng _currentLocation = LatLng(6.8720015, 7.4069943);
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
  String _pickupLocation = "Your current location";
  String _dropoffLocation = "Destination";
  String _currentLocationAddress = "Current location";
  LatLng? _driverLocation;
  Timer? _driverLocationTimer;
  Timer? _nearbyDriverTrackingTimer;
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
  Timer? _nearbyDriversTimer;
  bool _hasNearbyDriver = false;
  Map<String, dynamic>? _nearbyDriverData;
  LatLng? _nearbyDriverLocation;
  bool _isActiveRideSheetVisible = false;
  bool _isDriverFoundSheetVisible = false;
  bool _hasUserDismissedSheet = false;
  int? _lastCompletedRideId;
  final Set<int> _dismissedRatingRides = {};
  Timer? _etaUpdateTimer;
  bool _hasInitializedMapCamera = false;
  final bool _userIsInteractingWithMap = false;
  late DraggableScrollableController _sheetController;
  double _currentSheetSize = 0.4;

  @override
  void initState() {
    super.initState();
    _webSocketService = WebSocketService.instance;

    fromController.addListener(_onTextFieldChanged);
    toController.addListener(_onTextFieldChanged);
    stopController.addListener(_onTextFieldChanged);

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

      final screenHeight = MediaQuery.of(context).size.height;
      final targetPosition =
          (screenHeight * 0.42 - 80.h) / (screenHeight * 0.85 - 80.h);
      _panelController.animatePanelToPosition(
        targetPosition.clamp(0.0, 1.0),
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );

      AppLogger.log(
        'Call handler set BEFORE connect: ${_webSocketService.onIncomingCall != null}',
        tag: 'HOME_INIT',
      );
      AppLogger.log(
        'Connecting WebSocket from HomeScreen...',
        tag: 'HOME_INIT',
      );

      _webSocketService.connect().then((_) {
        AppLogger.log('WebSocket connected', tag: 'HOME_INIT');
        _setupOtherWebSocketListeners();
      });

      _checkActiveRides();
      _startActiveRideChecking();
      _startNearbyDriverChecking();
    });
  }

  void _onPanelSlide(double position) {
    final screenHeight = MediaQuery.of(context).size.height;
    final panelHeight = 80.h + position * (screenHeight * 0.85 - 80.h);
    final sheetSize = panelHeight / screenHeight;

    if (sheetSize > 0.45 && !_showDestinationField) {
      setState(() => _showDestinationField = true);
    } else if (sheetSize <= 0.3 && _showDestinationField) {
      setState(() => _showDestinationField = false);
    }
  }

  Map<String, dynamic>? _incomingOffer;

  void _setupOtherWebSocketListeners() {
    AppLogger.log(
      'Setting up other WebSocket listeners...',
      tag: 'HOME_WEBSOCKET',
    );

    AppLogger.log(
      'Verifying call handler still exists: ${_webSocketService.onIncomingCall != null}',
      tag: 'HOME_WEBSOCKET',
    );

    _webSocketService.onChatMessage = (chatData) {
      AppLogger.log('Global chat handler called in HomeScreen');
      _handleGlobalChatMessage(chatData);
    };

    _webSocketService.onRideAccepted = (data) {
      AppLogger.log('Ride accepted callback triggered!');

      if (_isDriverFoundSheetVisible && mounted) {
        Navigator.pop(context);
        _isDriverFoundSheetVisible = false;
      }

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

      final rawEta = data['estimated_arrival']?.toString() ?? '5';
      double etaValue = double.tryParse(rawEta) ?? 5.0;
      int roundedEta = etaValue.round();

      setState(() {
        _isDriverAssigned = true;
        _isRideAccepted = true;
        _driverArrivalTime = roundedEta.toString();
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

    _webSocketService.onRideCompleted = (data) {
      AppLogger.log(
        'Ride completed callback triggered!',
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
          if (_activeRide != null &&
              (_activeRide!['ID'] == rideId ||
                  _activeRide!['ID'].toString() == rideId.toString())) {
            price = _activeRide!['Price']?.toString() ?? '0.00';
          } else if (data['amount'] != null) {
            price = data['amount'].toString();
          } else if (data['data'] != null && data['data']['amount'] != null) {
            price = data['data']['amount'].toString();
          }

          if (mounted) {
            _showTripCompleteSheet(rideId, price);
          }
        }
      } catch (e) {
        AppLogger.log('Error processing ride_completed message: $e');
      }
    };

    _webSocketService.onDriverAvailability = (data) {
      AppLogger.log(
        'Driver availability callback triggered!',
        tag: 'DRIVER_AVAILABILITY',
      );

      try {
        final availabilityData = data['data'] as Map<String, dynamic>?;

        if (availabilityData != null) {
          final hasDrivers = availabilityData['has_drivers'] as bool? ?? false;
          final driversFound = availabilityData['drivers_found'] as int? ?? 0;
          final driversNotified =
              availabilityData['drivers_notified'] as int? ?? 0;
          final message = availabilityData['message'] as String? ?? '';

          AppLogger.log(
            'Has drivers: $hasDrivers, Found: $driversFound, Notified: $driversNotified',
            tag: 'DRIVER_AVAILABILITY',
          );

          if (!hasDrivers && driversFound == 0) {
            if (mounted) {
              _showDriverAvailabilitySheet();
            }
          } else {
            AppLogger.log(
              'Drivers available: $message',
              tag: 'DRIVER_AVAILABILITY',
            );
          }
        }
      } catch (e) {
        AppLogger.error(
          'Error processing driver_availability message',
          error: e,
          tag: 'DRIVER_AVAILABILITY',
        );
      }
    };

    AppLogger.log(
      'Non-call WebSocket listeners setup complete',
      tag: 'HOME_WEBSOCKET',
    );
    AppLogger.log(
      'Final handler check: ${_webSocketService.onIncomingCall != null}',
      tag: 'HOME_WEBSOCKET',
    );
  }

  void _navigateToWallet() async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final hasAccount = await walletProvider.checkVirtualAccount();

    if (!mounted) return;

    if (hasAccount) {
      context.pushNamed('wallet');
    } else {
      context.pushNamed('walletEmpty');
    }
  }

  Future<void> _createDriverIcon() async {
    _driverIcon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(48, 48)),
      ConstImages.locationPin,
    );
    setState(() {});
  }

  Future<void> _createCarIcon() async {
    AppLogger.log('=== CREATING CAR ICON ===', tag: 'CAR_ICON');
    try {
      _carIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(150, 150)),
        'assets/images/car.png',
      );
      AppLogger.log('Car icon created successfully', tag: 'CAR_ICON');
      setState(() {});
    } catch (e) {
      AppLogger.error('Failed to create car icon', error: e, tag: 'CAR_ICON');
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

    late OverlayEntry overlayEntry;
    final Completer<BitmapDescriptor> completer = Completer<BitmapDescriptor>();

    overlayEntry = OverlayEntry(
      builder: (context) =>
          Positioned(left: -1000, top: -1000, child: wrappedWidget),
    );

    Overlay.of(context).insert(overlayEntry);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await Future.delayed(Duration(milliseconds: 100));

        final RenderRepaintBoundary boundary =
            globalKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary;

        final ui.Image capturedImage = await boundary.toImage(pixelRatio: 2.0);
        final ByteData? byteData = await capturedImage.toByteData(
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

  Future<void> _loadFavouriteLocations() async {
    AppLogger.log('Loading favourite locations on home screen...');
    try {
      _favouriteLocations = await _favouriteService.getFavouriteLocations();
      AppLogger.log(
        'Loaded ${_favouriteLocations.length} favourite locations:',
      );
      for (final fav in _favouriteLocations) {
        AppLogger.log('  - ${fav.name}: ${fav.destAddress}');
      }
      setState(() {});
    } catch (e) {
      AppLogger.log('Error loading favourite locations: $e');
    }
  }

  void _handleGlobalChatMessage(Map<String, dynamic> chatData) async {
    try {
      AppLogger.log('Processing global chat message');
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
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('user_id');
      AppLogger.log('   Current User ID: $currentUserId');
      AppLogger.log('   Sender ID: $senderId');
      if (mounted && rideId > 0) {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        final message = ChatMessageModel(
          message: messageText,
          timestamp: timestamp,
          rideId: rideId,
          userId: senderId,
        );
        chatProvider.addMessage(rideId, message);
        AppLogger.log('Message added to ChatProvider');
        if (senderId != currentUserId &&
            senderId.isNotEmpty &&
            currentUserId != null) {
          AppLogger.log('Showing notification (message from other user)');
          ChatNotificationService.showChatNotification(
            context,
            senderName: senderName,
            message: messageText,
            senderImage: senderImage,
            onTap: () {
              AppLogger.log('Notification tapped, navigating to chat');
              if (_activeRide != null) {
                final passengerName = _assignedDriver!.name;
                final passengerImage = _assignedDriver!.profilePicture;
                final passengerId = _assignedDriver!.id;
                context.pushNamed(
                  AppRoutes.chat.name,
                  extra: {
                    'rideId': rideId,
                    'driverName': passengerName,
                    'driverImage': passengerImage,
                    'driverId': passengerId,
                    'driverPhone': _assignedDriver?.phoneNumber,
                  },
                );
              } else {
                context.pushNamed(
                  AppRoutes.chat.name,
                  extra: {
                    'rideId': rideId,
                    'driverId': senderId,
                    'driverName': senderName,
                    'driverImage': senderImage,
                    'driverPhone': _assignedDriver?.phoneNumber,
                  },
                );
              }
            },
          );
        } else {
          AppLogger.log('Skipping notification (message from current user)');
        }
      }
    } catch (e, stack) {
      AppLogger.log('Error handling global chat message: $e');
      AppLogger.log('Stack: $stack');
    }
  }

  void _startNearbyDriverChecking() {
    _checkNearbyDrivers();
    _nearbyDriversTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _checkNearbyDrivers();
    });
  }

  Future<void> _checkNearbyDrivers() async {
    if (_activeRide != null || _isDriverAssigned) {
      setState(() {
        _hasNearbyDriver = false;
        _nearbyDriverData = null;
        _nearbyDriverLocation = null;
      });
      return;
    }

    AppLogger.log('=== CHECKING NEARBY DRIVERS ===', tag: 'NEARBY_DRIVER');
    try {
      final driverData = await _rideService.getNearbyDrivers(
        latitude: _currentLocation.latitude,
        longitude: _currentLocation.longitude,
      );

      if (driverData != null) {
        AppLogger.log('Nearby driver found: $driverData', tag: 'NEARBY_DRIVER');
        final locationData = driverData['location'];
        final latitude = locationData['latitude'] is double
            ? locationData['latitude']
            : double.tryParse(locationData['latitude'].toString()) ?? 0.0;
        final longitude = locationData['longitude'] is double
            ? locationData['longitude']
            : double.tryParse(locationData['longitude'].toString()) ?? 0.0;
        final eta = driverData['eta_minutes']?.toString() ?? '1';
        double etaValue = double.tryParse(eta) ?? 1.0;
        int roundedEta = etaValue.round();
        setState(() {
          _driverArrivalTime = roundedEta.toString();
          _hasNearbyDriver = true;
          _nearbyDriverData = driverData;
          _nearbyDriverLocation = LatLng(latitude, longitude);
        });
        _updateNearbyDriverMarker(LatLng(latitude, longitude), eta);
        if (!(_nearbyDriverTrackingTimer?.isActive ?? false)) {
          _startNearbyDriverTracking();
        }
      } else {
        AppLogger.log('No nearby drivers found', tag: 'NEARBY_DRIVER');
        setState(() {
          _hasNearbyDriver = false;
          _nearbyDriverData = null;
          _nearbyDriverLocation = null;
        });
        setState(() {
          _mapMarkers.removeWhere((m) => m.markerId.value == 'nearby_driver');
        });
      }
    } catch (e) {
      AppLogger.log('Error checking nearby drivers: $e', tag: 'NEARBY_DRIVER');
      setState(() {
        _hasNearbyDriver = false;
        _nearbyDriverData = null;
        _nearbyDriverLocation = null;
      });
    }
  }

  void _startNearbyDriverTracking() {
    _nearbyDriverTrackingTimer?.cancel();
    _nearbyDriverTrackingTimer = Timer.periodic(Duration(seconds: 5), (
      timer,
    ) async {
      if (_activeRide != null || _isDriverAssigned) {
        timer.cancel();
        return;
      }

      try {
        final driverData = await _rideService.getNearbyDrivers(
          latitude: _currentLocation.latitude,
          longitude: _currentLocation.longitude,
        );

        if (driverData != null && mounted) {
          final locationData = driverData['location'];
          final latitude = locationData['latitude'] is double
              ? locationData['latitude']
              : double.tryParse(locationData['latitude'].toString()) ?? 0.0;
          final longitude = locationData['longitude'] is double
              ? locationData['longitude']
              : double.tryParse(locationData['longitude'].toString()) ?? 0.0;
          final eta = driverData['eta_minutes']?.toString() ?? '1';
          double etaValue = double.tryParse(eta) ?? 1.0;
          int roundedEta = etaValue.round();
          final newLocation = LatLng(latitude, longitude);
          setState(() {
            _driverArrivalTime = roundedEta.toString();
            _nearbyDriverLocation = newLocation;
          });
          _updateNearbyDriverMarker(newLocation, roundedEta.toString());
          if (!(_nearbyDriverTrackingTimer?.isActive ?? false)) {
            _startNearbyDriverTracking();
          }
        } else if (mounted) {
          setState(() {
            _hasNearbyDriver = false;
            _nearbyDriverData = null;
            _nearbyDriverLocation = null;
            _mapMarkers.removeWhere((m) => m.markerId.value == 'nearby_driver');
          });
          timer.cancel();
        }
      } catch (e) {
        AppLogger.log('Error tracking nearby driver: $e', tag: 'NEARBY_DRIVER');
      }
    });
  }

  void _animateDriverMarker({
    required String markerId,
    required LatLng from,
    required LatLng to,
    String eta = '',
  }) {
    const int steps = 20;
    const duration = Duration(milliseconds: 1500);
    final stepDuration = Duration(
      milliseconds: duration.inMilliseconds ~/ steps,
    );

    int step = 0;
    Timer.periodic(stepDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      step++;
      final t = step / steps;

      final lat = from.latitude + (to.latitude - from.latitude) * t;
      final lng = from.longitude + (to.longitude - from.longitude) * t;
      final interpolated = LatLng(lat, lng);

      setState(() {
        _mapMarkers.removeWhere((m) => m.markerId.value == markerId);
        _mapMarkers.add(
          Marker(
            markerId: MarkerId(markerId),
            position: interpolated,
            icon: _carIcon!,
            anchor: Offset(0.5, 0.5),
            infoWindow: InfoWindow(
              title: 'Nearby Driver',
              snippet: '$eta min away',
            ),
          ),
        );
      });

      if (step >= steps) {
        timer.cancel();
      }
    });
  }

  void _updateNearbyDriverMarker(LatLng newLocation, String eta) {
    if (_carIcon == null) return;

    final oldMarker = _mapMarkers
        .where((m) => m.markerId.value == 'nearby_driver')
        .firstOrNull;

    if (oldMarker != null) {
      _animateDriverMarker(
        markerId: 'nearby_driver',
        from: oldMarker.position,
        to: newLocation,
        eta: eta,
      );
    } else {
      setState(() {
        _mapMarkers.removeWhere((m) => m.markerId.value == 'nearby_driver');
        _mapMarkers.add(
          Marker(
            markerId: MarkerId('nearby_driver'),
            position: newLocation,
            icon: _carIcon!,
            anchor: Offset(0.5, 0.5),
            infoWindow: InfoWindow(
              title: 'Nearby Driver',
              snippet: '$eta min away',
            ),
          ),
        );
      });
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
    _activeRideCheckTimer = Timer.periodic(Duration(seconds: 8), (timer) {
      _checkActiveRides();
    });
  }

  void _handleActiveRideStatus(Map<String, dynamic> ride) {
    final status = ride['Status']?.toString().toLowerCase() ?? '';
    final rideId = ride['ID'] as int?;
    AppLogger.log('Handling active ride with status: $status');

    if (rideId != null &&
        (status == 'accepted' || status == 'arrived' || status == 'started')) {
      _lastCompletedRideId = rideId;
    }

    switch (status) {
      case 'accepted':
      case 'arrived':
      case 'started':
        final driverData = ride['Driver'] ?? {};
        if (driverData.isNotEmpty) {
          final vehicles = driverData['Vehicles'] as List?;
          final vehicleData = (vehicles != null && vehicles.isNotEmpty)
              ? vehicles[0]
              : null;

          String vehicleModel = 'Vehicle';
          if (vehicleData != null) {
            final make = vehicleData['Make']?.toString().trim() ?? '';
            final modelType = vehicleData['ModelType']?.toString().trim() ?? '';
            final year = vehicleData['Year']?.toString() ?? '';
            final color = vehicleData['Color']?.toString().trim() ?? '';

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
        AppLogger.log('Parsing PostGIS locations...');
        AppLogger.log('PickupLocation: ${ride['PickupLocation']}');
        AppLogger.log('DestLocation: ${ride['DestLocation']}');
        _addActiveRideMarkers(ride);
        AppLogger.log(
          'Checking ride status for tracking: $status',
          tag: 'RIDE_STATUS',
        );
        if (status == 'accepted') {
          AppLogger.log(
            'Status is ACCEPTED - Starting driver location tracking',
            tag: 'RIDE_STATUS',
          );
          _startDriverLocationTracking();
        } else if (status == 'arrived' || status == 'started') {
          AppLogger.log(
            'Status is $status - Stopping driver location tracking',
            tag: 'RIDE_STATUS',
          );
          _stopDriverLocationTracking();
        } else {
          AppLogger.log(
            'Unexpected status: $status - No tracking action taken',
            tag: 'RIDE_STATUS',
          );
        }
        if (status != _lastKnownRideStatus) {
          AppLogger.log(
            'Status changed from $_lastKnownRideStatus to $status',
            tag: 'RIDE_STATUS',
          );
          _lastKnownRideStatus = status;
          if (_isActiveRideSheetVisible) {
            Navigator.pop(context);
            _isActiveRideSheetVisible = false;
            Future.delayed(Duration(milliseconds: 300), () {
              if (mounted) {
                _showDriverAcceptedSheet();
              }
            });
          } else if (!_hasUserDismissedSheet) {
            _showDriverAcceptedSheet();
          }
        } else {
          AppLogger.log(
            'Status unchanged ($status), skipping sheet update',
            tag: 'RIDE_STATUS',
          );
        }
        break;
      case 'completed':
        if (_lastCompletedRideId != null &&
            !_dismissedRatingRides.contains(_lastCompletedRideId)) {
          _checkAndShowRating(_lastCompletedRideId!);
        }
        break;
      case 'cancelled':
        if (_isActiveRideSheetVisible) {
          Navigator.pop(context);
          _isActiveRideSheetVisible = false;
        }
        _lastKnownRideStatus = null;
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

  void _startDriverLocationTracking() {
    _driverLocationTimer?.cancel();
    _etaUpdateTimer?.cancel();
    _driverLocationTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _updateDriverLocation();
    });
    _updateDriverLocation();
  }

  void _stopDriverLocationTracking() {
    _driverLocationTimer?.cancel();
    _etaUpdateTimer?.cancel();
    _driverLocationTimer = null;
    _etaUpdateTimer = null;
  }

  Future<void> _updateDriverLocation() async {
    if (_activeRide == null) {
      _stopDriverLocationTracking();
      return;
    }
    try {
      final response = await _rideService.getActiveRides();
      List? rides;
      if (response['rides'] != null) {
        rides = response['rides'] as List;
      } else if (response['data'] != null &&
          response['data']['rides'] != null) {
        rides = response['data']['rides'] as List;
      }
      if (response['success'] == true && rides != null) {
        if (rides.isNotEmpty) {
          final ride = rides[0];
          final status = ride['Status']?.toString().toLowerCase() ?? '';
          if (status == 'accepted') {
            final driverData = ride['Driver'];
            if (driverData != null && driverData['Location'] != null) {
              final driverLocationStr = driverData['Location'].toString();
              final driverCoords = parsePostGISPoint(driverLocationStr);
              if (driverCoords != null) {
                AppLogger.log(
                  'Driver coords parsed: lat=${driverCoords.latitude}, lng=${driverCoords.longitude}',
                  tag: 'DRIVER_LOCATION',
                );
                setState(() {
                  _driverLocation = driverCoords;
                });
                AppLogger.log(
                  'Updating driver marker on map...',
                  tag: 'DRIVER_LOCATION',
                );
                _updateDriverMarker(driverCoords);
                AppLogger.log('Calculating ETA...', tag: 'DRIVER_LOCATION');
                await _calculateAndUpdateETA(driverCoords);
              } else {
                AppLogger.log(
                  'Failed to parse driver coordinates',
                  tag: 'DRIVER_LOCATION',
                );
              }
            } else {
              AppLogger.log(
                'Driver data or location is null. DriverData: ${driverData != null}, Location: ${driverData?['Location']}',
                tag: 'DRIVER_LOCATION',
              );
            }
          } else if (status == 'arrived' || status == 'started') {
            AppLogger.log(
              'Driver has arrived or trip started, stopping tracking',
              tag: 'DRIVER_LOCATION',
            );
            _stopDriverLocationTracking();
          } else {
            AppLogger.log('Unexpected status: $status', tag: 'DRIVER_LOCATION');
          }
        } else {
          AppLogger.log('Rides array is empty', tag: 'DRIVER_LOCATION');
        }
      } else {
        AppLogger.log(
          'Response unsuccessful or no rides. Success: ${response['success']}, Rides: $rides',
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

  void _updateDriverMarker(LatLng driverLocation) {
    AppLogger.log('=== UPDATING DRIVER MARKER ===', tag: 'DRIVER_MARKER');

    if (_carIcon == null) {
      AppLogger.log(
        'Car icon is null! Cannot add driver marker.',
        tag: 'DRIVER_MARKER',
      );
      return;
    }
    AppLogger.log(
      'Car icon loaded, refreshing map with driver at: ${driverLocation.latitude}, ${driverLocation.longitude}',
      tag: 'DRIVER_MARKER',
    );
    if (_activeRide != null) {
      AppLogger.log(
        'Refreshing all markers and polylines with updated driver location',
        tag: 'DRIVER_MARKER',
      );
      _addActiveRideMarkers(_activeRide!);
    }
    setState(() {
      _mapMarkers.removeWhere(
        (marker) => marker.markerId.value == 'driver_location',
      );
      _mapMarkers.add(
        Marker(
          markerId: MarkerId('driver_location'),
          position: driverLocation,
          icon: _carIcon!,
          anchor: Offset(0.5, 0.5),
          rotation: 0,
          infoWindow: InfoWindow(
            title: 'Driver',
            snippet: _assignedDriver?.name ?? 'Your driver',
          ),
        ),
      );
    });
  }

  Future<void> _calculateAndUpdateETA(LatLng driverLocation) async {
    AppLogger.log('=== CALCULATING ETA ===', tag: 'ETA');

    if (_activeRide == null) {
      AppLogger.log('No active ride', tag: 'ETA');
      return;
    }

    try {
      final pickupLocationStr = _activeRide!['PickupLocation']?.toString();
      if (pickupLocationStr == null) {
        AppLogger.log('Pickup location is null', tag: 'ETA');
        return;
      }
      AppLogger.log('Pickup location (raw): $pickupLocationStr', tag: 'ETA');
      final pickupCoords = parsePostGISPoint(pickupLocationStr);
      if (pickupCoords == null) {
        AppLogger.log('Failed to parse pickup coordinates', tag: 'ETA');
        return;
      }
      AppLogger.log(
        'Pickup coords: lat=${pickupCoords.latitude}, lng=${pickupCoords.longitude}',
        tag: 'ETA',
      );
      AppLogger.log('Calling Google Directions API...', tag: 'ETA');
      final routeDetails = await _directionsService.getRouteDetails(
        origin: driverLocation,
        destination: pickupCoords,
      );
      if (routeDetails != null) {
        if (routeDetails['duration_value'] != null) {
          final durationInSeconds = routeDetails['duration_value'];
          AppLogger.log("this is the duration in seconds $durationInSeconds");
          final durationInMinutes = (durationInSeconds / 60).ceil();
          setState(() {
            _driverArrivalTime = durationInMinutes.toString();
          });
        }
      } else {
        AppLogger.log(
          'API returned null, using fallback calculation',
          tag: 'ETA',
        );
        final distanceKm = _calculateDistance(driverLocation, pickupCoords);
        final estimatedMinutes = (distanceKm / 0.5).ceil();
        AppLogger.log(
          'Distance: ${distanceKm.toStringAsFixed(2)} km, Estimated: $estimatedMinutes mins',
          tag: 'ETA',
        );
        setState(() {
          _driverArrivalTime = estimatedMinutes.toString();
        });
        AppLogger.log(
          'ETA ESTIMATED (fallback): $estimatedMinutes mins',
          tag: 'ETA',
        );
      }
    } catch (e, stack) {
      AppLogger.error('Error calculating ETA', error: e, tag: 'ETA');
      log("eta stack $stack");
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

  void _selectLocation(PlacePrediction prediction, bool isFrom) async {
    final placeDetails = await _placesService.getPlaceDetails(
      prediction.placeId,
      sessionToken: _sessionToken,
    );

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
      _sessionToken = null;
    });

    Provider.of<LocationProvider>(
      context,
      listen: false,
    ).addRecentLocation(prediction.description, prediction.description);

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

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever)
        return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      String currentAddress = '';
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        final street = place.street?.trim() ?? '';
        final locality = place.locality?.trim() ?? '';
        final subLocality = place.subLocality?.trim() ?? '';
        final adminArea = place.administrativeArea?.trim() ?? '';
        if (street.isNotEmpty && street != locality) {
          currentAddress = locality.isNotEmpty ? '$street, $locality' : street;
        } else if (locality.isNotEmpty) {
          currentAddress = adminArea.isNotEmpty
              ? '$locality, $adminArea'
              : locality;
        } else if (subLocality.isNotEmpty) {
          currentAddress = adminArea.isNotEmpty
              ? '$subLocality, $adminArea'
              : subLocality;
        } else if (adminArea.isNotEmpty) {
          currentAddress = adminArea;
        }
        currentAddress = currentAddress
            .replaceAll(RegExp(r'^,\s*|,\s*$'), '')
            .trim();
      }
      if (currentAddress.isEmpty) {
        currentAddress =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      }
      final coords = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _currentLocation = coords;
          _userCurrentLocation = position;
          _currentLocationAddress = currentAddress;
          _isLocationLoaded = true;
          _pickupCoordinates = coords;
          if (fromController.text.isEmpty ||
              fromController.text == 'Current location' ||
              fromController.text == 'Loading...') {
            _isFromFieldEditable = true;
          }
        });
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: coords, zoom: 16.0),
          ),
        );
      }
      _checkNearbyDrivers();
    } catch (e) {
      AppLogger.error('Error getting location: $e', tag: 'LOCATION');
      if (mounted) {
        setState(() {
          _isFromFieldEditable = true;
        });
      }
    }
  }

  double _calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
          start.latitude,
          start.longitude,
          end.latitude,
          end.longitude,
        ) /
        1000;
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
          AppLogger.log('Showing rating sheet');
          _showRatingSheet();
        } else {
          AppLogger.log(
            'Not showing rating sheet - hasRated: $hasRated, mounted: $mounted',
          );
        }
      } else {
        AppLogger.log('getRideDetails failed: ${result['message']}');
      }
      AppLogger.log('=== END CHECKING RATING STATUS ===');
    } catch (e) {
      AppLogger.log('Error checking rating status: $e');
    }
  }

  Future<void> _estimateRide() async {
    AppLogger.log('=== ESTIMATING RIDE ===', tag: 'ESTIMATE');

    if (_pickupCoordinates == null || _destinationCoordinates == null) {
      AppLogger.log('Missing coordinates', tag: 'ESTIMATE');
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
      vehicleType: 'regular',
    );
    AppLogger.log('Estimate Request:', tag: 'ESTIMATE');
    AppLogger.log('  Pickup: ${request.pickup}', tag: 'ESTIMATE');
    AppLogger.log('  Dest: ${request.dest}', tag: 'ESTIMATE');
    AppLogger.log('  Service Type: ${request.serviceType}', tag: 'ESTIMATE');
    try {
      _currentEstimate = await _rideService.estimateRide(request);
      AppLogger.log('=== ESTIMATE RESPONSE RECEIVED ===', tag: 'ESTIMATE');
      AppLogger.log('Currency: ${_currentEstimate!.currency}', tag: 'ESTIMATE');
      AppLogger.log(
        'Distance KM: ${_currentEstimate!.distanceKm}',
        tag: 'ESTIMATE',
      );
      AppLogger.log(
        'DURATION MIN: ${_currentEstimate!.durationMin}',
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
      rethrow;
    }
  }

  void _addActiveRideMarkers(Map<String, dynamic> ride) async {
    final status = ride['Status']?.toString().toLowerCase() ?? '';
    final pickupLocation = ride['PickupLocation']?.toString();
    final destLocation = ride['DestLocation']?.toString();
    final stopLocation = ride['StopLocation']?.toString();
    LatLng? pickupCoords;
    LatLng? destCoords;
    LatLng? stopCoords;
    if (pickupLocation != null &&
        (pickupLocation.startsWith('0101000020') ||
            pickupLocation.contains('POINT'))) {
      final coords = parsePostGISPoint(pickupLocation);
      if (coords != null) {
        pickupCoords = coords;
        AppLogger.log('Pickup coords parsed: $coords', tag: 'MARKERS');
      } else {
        AppLogger.log('Failed to parse pickup coords', tag: 'MARKERS');
      }
    } else {
      AppLogger.log(
        'Pickup location is null or not in recognized format',
        tag: 'MARKERS',
      );
    }
    if (destLocation != null &&
        (destLocation.startsWith('0101000020') ||
            destLocation.contains('POINT'))) {
      final coords = parsePostGISPoint(destLocation);
      if (coords != null) {
        destCoords = coords;
        AppLogger.log('Dest coords parsed: $coords', tag: 'MARKERS');
      } else {
        AppLogger.log('Failed to parse dest coords', tag: 'MARKERS');
      }
    } else {
      AppLogger.log(
        'Dest location is null or not in recognized format',
        tag: 'MARKERS',
      );
    }
    final stopAddress = ride['StopAddress']?.toString() ?? '';
    if (stopAddress == 'No stops' &&
        pickupCoords != null &&
        destCoords != null) {
      stopCoords = LatLng(
        (pickupCoords.latitude + destCoords.latitude) / 2,
        (pickupCoords.longitude + destCoords.longitude) / 2,
      );
      AppLogger.log(
        'Stop coords calculated as midpoint: $stopCoords',
        tag: 'MARKERS',
      );
    } else if (stopLocation != null &&
        (stopLocation.startsWith('0101000020') ||
            stopLocation.contains('POINT'))) {
      final coords = parsePostGISPoint(stopLocation);
      if (coords != null) {
        stopCoords = coords;
        AppLogger.log('Stop coords parsed: $coords', tag: 'MARKERS');
      } else {
        AppLogger.log('Failed to parse stop coords', tag: 'MARKERS');
      }
    } else {
      AppLogger.log(
        'Stop location is null or not in recognized format',
        tag: 'MARKERS',
      );
    }

    final markers = <Marker>{};

    if (pickupCoords != null) {
      AppLogger.log('Creating pickup marker widget...', tag: 'MARKERS');
      try {
        final pickupIcon = await _createBitmapDescriptorFromWidget(
          PickupMarkerWidget(
            driverArrivalTime: _driverArrivalTime,
            hasNearbyDriver: _hasNearbyDriver,
            isDriverAssigned: _isDriverAssigned,
            pickupAddress: _activeRide?['PickupAddress']?.toString(),
            fromText: fromController.text,
            currentLocationAddress: _currentLocationAddress,
          ),
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
        AppLogger.log('Pickup marker added with custom icon', tag: 'MARKERS');
      } catch (e) {
        AppLogger.log(
          'Failed to create custom pickup marker, using default: $e',
          tag: 'MARKERS',
        );
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

    if (status == 'started' && destCoords != null) {
      AppLogger.log(
        'Creating dropoff marker widget (ride started)...',
        tag: 'MARKERS',
      );
      try {
        final dropoffIcon = await _createBitmapDescriptorFromWidget(
          DropoffMarkerWidget(
            destAddress: _activeRide?['DestAddress']?.toString(),
            toText: toController.text,
          ),
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
        AppLogger.log('Dropoff marker added with custom icon', tag: 'MARKERS');
      } catch (e) {
        AppLogger.log(
          'Failed to create custom dropoff marker, using default: $e',
          tag: 'MARKERS',
        );
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
        'Skipping dropoff marker (ride not started yet)',
        tag: 'MARKERS',
      );
    }

    if (status == 'started' && stopCoords != null) {
      AppLogger.log('Creating stop marker widget...', tag: 'MARKERS');
      try {
        final stopIcon = await _createBitmapDescriptorFromWidget(
          StopMarkerWidget(
            stopAddress: _activeRide?['StopAddress']?.toString(),
          ),
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
        AppLogger.log('Stop marker added with custom icon', tag: 'MARKERS');
      } catch (e) {
        AppLogger.log(
          'Failed to create custom stop marker, using default: $e',
          tag: 'MARKERS',
        );
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

    AppLogger.log('Total markers created: ${markers.length}', tag: 'MARKERS');

    final polylines = <Polyline>{};

    if (status == 'accepted') {
      if (pickupCoords != null && _driverLocation != null) {
        AppLogger.log(
          'Drawing route from PICKUP to DRIVER (accepted status)...',
          tag: 'MARKERS',
        );

        try {
          PolylinePoints polylinePoints = PolylinePoints();
          PolylineResult result = await polylinePoints
              .getRouteBetweenCoordinates(
                googleApiKey: UrlConstants.googleMapsApiKey,
                request: PolylineRequest(
                  origin: PointLatLng(
                    pickupCoords.latitude,
                    pickupCoords.longitude,
                  ),
                  destination: PointLatLng(
                    _driverLocation!.latitude,
                    _driverLocation!.longitude,
                  ),
                  mode: TravelMode.driving,
                  optimizeWaypoints: true,
                ),
              );

          List<LatLng> routePoints = [];
          if (result.points.isNotEmpty) {
            for (var point in result.points) {
              routePoints.add(LatLng(point.latitude, point.longitude));
            }
            AppLogger.log(
              'Got ${routePoints.length} route points (pickup to driver)',
              tag: 'MARKERS',
            );
          } else {
            AppLogger.log(
              'Directions API returned empty. Error: ${result.errorMessage}',
              tag: 'MARKERS',
            );
            routePoints = generateCurvedPath(pickupCoords, _driverLocation!);
            AppLogger.log(
              'Using curved path fallback with ${routePoints.length} points',
              tag: 'MARKERS',
            );
          }

          polylines.add(
            Polyline(
              polylineId: PolylineId('driver_to_pickup_route'),
              points: routePoints,
              color: Color(ConstColors.mainColor),
              width: 5,
              geodesic: true,
            ),
          );

          AppLogger.log('Polyline created (pickup to driver)', tag: 'MARKERS');
        } catch (e) {
          AppLogger.log('Failed to get route polyline: $e', tag: 'MARKERS');
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
          'Cannot draw pickup-to-driver route: pickupCoords=${pickupCoords != null}, driverLocation=${_driverLocation != null}',
          tag: 'MARKERS',
        );
      }
    } else if (status == 'started') {
      if (pickupCoords != null && destCoords != null) {
        AppLogger.log(
          'Drawing route from PICKUP to DESTINATION (started status)...',
          tag: 'MARKERS',
        );

        try {
          PolylinePoints polylinePoints = PolylinePoints();
          PolylineResult result = await polylinePoints
              .getRouteBetweenCoordinates(
                googleApiKey: UrlConstants.googleMapsApiKey,
                request: PolylineRequest(
                  origin: PointLatLng(
                    pickupCoords.latitude,
                    pickupCoords.longitude,
                  ),
                  destination: PointLatLng(
                    destCoords.latitude,
                    destCoords.longitude,
                  ),
                  mode: TravelMode.driving,
                  optimizeWaypoints: true,
                ),
              );

          List<LatLng> routePoints = [];
          if (result.points.isNotEmpty) {
            for (var point in result.points) {
              routePoints.add(LatLng(point.latitude, point.longitude));
            }
            AppLogger.log(
              'Got ${routePoints.length} route points (pickup to destination)',
              tag: 'MARKERS',
            );
          } else {
            AppLogger.log(
              'Directions API returned empty. Error: ${result.errorMessage}',
              tag: 'MARKERS',
            );
            routePoints = generateCurvedPath(pickupCoords, destCoords);
            AppLogger.log(
              'Using curved path fallback with ${routePoints.length} points',
              tag: 'MARKERS',
            );
          }

          polylines.add(
            Polyline(
              polylineId: PolylineId('active_route'),
              points: routePoints,
              color: Color(ConstColors.mainColor),
              width: 5,
              geodesic: true,
            ),
          );
        } catch (e) {
          AppLogger.log('Failed to get route polyline: $e', tag: 'MARKERS');
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

    AppLogger.log('Markers and polylines set in state', tag: 'MARKERS');

    if (!_hasInitializedMapCamera &&
        markers.isNotEmpty &&
        _mapController != null) {
      final positions = markers.map((m) => m.position).toList();
      final bounds = calculateBounds(positions);
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
      _hasInitializedMapCamera = true;
      AppLogger.log(
        'Camera adjusted to fit markers (first time only)',
        tag: 'MARKERS',
      );
    } else if (_hasInitializedMapCamera) {
      AppLogger.log(
        'Skipping camera adjustment - user can control map freely',
        tag: 'MARKERS',
      );
    } else {
      AppLogger.log(
        'Cannot adjust camera: markers=${markers.length}, controller=${_mapController != null}',
        tag: 'MARKERS',
      );
    }

    AppLogger.log('=== MARKERS SETUP COMPLETE ===', tag: 'MARKERS');
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
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever)
        return;

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
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 16.0,
            ),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error in forceUpdateLocation: $e', tag: 'LOCATION');
    }
  }

  void _onTextFieldChanged() {
    final hasContent =
        toController.text.isNotEmpty || stopController.text.isNotEmpty;
    if (hasContent) {
      final screenHeight = MediaQuery.of(context).size.height;
      final targetPosition =
          (screenHeight * 0.9 - 80.h) / (screenHeight * 0.85 - 80.h);
      _panelController.animatePanelToPosition(
        targetPosition.clamp(0.0, 1.0),
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      if (fromController.text.isNotEmpty && !_showDestinationField) {
        setState(() => _showDestinationField = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final targetPosition =
        (screenHeight * 0.42 - 80.h) / (screenHeight * 0.85 - 80.h);
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
            CustomFlushbar.showInfo(
              context: context,
              message: 'Press back again to exit',
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
          drawer: AppDrawer(
            onNavigateToTab: (index) {
              context.pop();
              setState(() => _currentIndex = index);
            },
          ),
          body: Stack(
            children: [
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
              Positioned(
                top: 50.h,
                left: 20.w,
                child: GestureDetector(
                  onTap: () {
                    Scaffold.of(context).openDrawer();
                  },
                  child: Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25.r),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.menu, size: 20.sp),
                  ),
                ),
              ),
              if (_activeRide != null)
                Positioned(
                  top: 66.h,
                  right: 30.w,
                  child: ActiveRideButton(
                    onTap: () {
                      if (_activeRide != null) {
                        _hasUserDismissedSheet = false;
                        _showDriverAcceptedSheet();
                      }
                    },
                  ),
                ),
              if (_activeRide == null && !_isDriverAssigned)
                Positioned(
                  top: 120.h,
                  left: 35.w,
                  right: 35.w,
                  child: QuickPickupButton(
                    hasNearbyDriver: _hasNearbyDriver,
                    driverArrivalTime: _driverArrivalTime,
                    fromText: fromController.text,
                    currentLocationAddress: _currentLocationAddress,
                    onTap: () {
                      setState(() {
                        fromController.text = _currentLocationAddress;
                        _pickupCoordinates = _currentLocation;
                        _isFromFieldEditable = true;
                        _showDestinationField = true;
                        _isFromFieldFocused = false;
                      });
                      final screenHeight = MediaQuery.of(context).size.height;
                      final targetPosition =
                          (screenHeight * 0.9 - 80.h) /
                          (screenHeight * 0.85 - 80.h);
                      _panelController.animatePanelToPosition(
                        targetPosition.clamp(0.0, 1.0),
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
              if (_isBottomSheetVisible)
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: _currentSheetSize <= 0.4,
                    child: GestureDetector(
                      onTap: () {
                        if (_sheetController.isAttached) {
                          _panelController.animatePanelToPosition(
                            0.0,
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                        _dismissSuggestions();
                      },
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        color: Colors.black.withOpacity(
                          ((_currentSheetSize - 0.4) / 0.5).clamp(0.0, 1.0) *
                              0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              if (_isBottomSheetVisible)
                SlidingUpPanel(
                  controller: _panelController,
                  minHeight: 80.h,
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                  panelSnapping: false,
                  onPanelSlide: _onPanelSlide,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20.r),
                  ),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                  panelBuilder: (ScrollController scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20.r),
                          topRight: Radius.circular(20.r),
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 10.h),
                            child: Center(
                              child: Container(
                                width: 69.w,
                                height: 5.h,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(2.5.r),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
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
                                          color: Color(ConstColors.mainColor),
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
                                                    BorderRadius.circular(8.r),
                                              ),
                                              child: TextField(
                                                controller: fromController,
                                                readOnly: _showDestinationField
                                                    ? !_isFromFieldEditable
                                                    : false,
                                                onTap: () {
                                                  if (!_showDestinationField) {
                                                    setState(() {
                                                      _showDestinationField =
                                                          true;
                                                      _isFromFieldFocused =
                                                          true;
                                                      _showSuggestions = false;
                                                      fromController.text =
                                                          _currentLocationAddress;
                                                      _panelController
                                                          .animatePanelToPosition(
                                                            targetPosition
                                                                .clamp(
                                                                  0.0,
                                                                  1.0,
                                                                ),
                                                            duration: Duration(
                                                              milliseconds: 300,
                                                            ),
                                                            curve: Curves
                                                                .easeInOut,
                                                          );
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
                                                    setState(
                                                      () =>
                                                          _isFromFieldFocused =
                                                              true,
                                                    );
                                                  }
                                                },
                                                onChanged: (value) {
                                                  if (_isFromFieldFocused ||
                                                      !_showDestinationField) {
                                                    _searchLocations(value);
                                                  }
                                                },
                                                decoration: InputDecoration(
                                                  hintText:
                                                      _showDestinationField
                                                      ? 'From'
                                                      : 'Where to',
                                                  hintStyle: TextStyle(
                                                    fontSize: 16.sp,
                                                    color: Colors.grey[400],
                                                  ),
                                                  prefixIcon: Padding(
                                                    padding: EdgeInsets.only(
                                                      left: 16.w,
                                                      right: 12.w,
                                                    ),
                                                    child: SvgPicture.asset(
                                                      ConstImages.search,
                                                      width: 20.w,
                                                      height: 20.h,
                                                      color: Colors.grey,
                                                      fit: BoxFit.scaleDown,
                                                    ),
                                                  ),
                                                  prefixIconConstraints:
                                                      BoxConstraints(
                                                        minWidth: 48.w,
                                                        minHeight: 20.h,
                                                      ),
                                                  suffixIcon:
                                                      _showDestinationField
                                                      ? Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
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
                                                                final result = await context.pushNamed(
                                                                  AppRoutes
                                                                      .mapSelection
                                                                      .name,
                                                                  extra: {
                                                                    'isFromField':
                                                                        true,
                                                                    'initialLocation':
                                                                        _currentLocation,
                                                                  },
                                                                );
                                                                if (result !=
                                                                    null) {
                                                                  final data =
                                                                      result
                                                                          as Map<
                                                                            String,
                                                                            dynamic
                                                                          >;
                                                                  setState(() {
                                                                    fromController
                                                                            .text =
                                                                        data['address'];
                                                                    _pickupCoordinates =
                                                                        data['location'];
                                                                    _currentLocation =
                                                                        data['location'];
                                                                  });
                                                                  if (toController
                                                                      .text
                                                                      .isNotEmpty)
                                                                    _checkBothFields();
                                                                }
                                                              },
                                                              child: Container(
                                                                width: 24.w,
                                                                height: 24.h,
                                                                margin:
                                                                    EdgeInsets.only(
                                                                      right:
                                                                          16.w,
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
                                                            ),
                                                          ],
                                                        )
                                                      : null,
                                                  border: InputBorder.none,
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                        horizontal: 0,
                                                        vertical: 15.h,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => setState(
                                              () => _showStopField =
                                                  !_showStopField,
                                            ),
                                            child: Icon(
                                              _showStopField
                                                  ? Icons.close
                                                  : Icons.add,
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
                                                  BorderRadius.circular(8.r),
                                            ),
                                            child: TextField(
                                              controller: stopController,
                                              onTap: () => setState(
                                                () =>
                                                    _isFromFieldFocused = false,
                                              ),
                                              onChanged: (value) {
                                                if (!_isFromFieldFocused)
                                                  _searchLocations(value);
                                              },
                                              decoration: InputDecoration(
                                                hintText: 'Add stop',
                                                hintStyle: TextStyle(
                                                  fontSize: 16.sp,
                                                  color: Colors.grey[400],
                                                ),
                                                prefixIcon: Padding(
                                                  padding: EdgeInsets.only(
                                                    left: 16.w,
                                                    right: 12.w,
                                                  ),
                                                  child: SvgPicture.asset(
                                                    ConstImages.search,
                                                    width: 20.w,
                                                    height: 20.h,
                                                    color: Colors.grey,
                                                    fit: BoxFit.scaleDown,
                                                  ),
                                                ),
                                                prefixIconConstraints:
                                                    BoxConstraints(
                                                      minWidth: 48.w,
                                                      minHeight: 20.h,
                                                    ),
                                                suffixIcon: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    if (stopController
                                                        .text
                                                        .isNotEmpty)
                                                      GestureDetector(
                                                        onTap: () => setState(
                                                          () => stopController
                                                              .clear(),
                                                        ),
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
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                      ),
                                                    GestureDetector(
                                                      onTap: () async {
                                                        final result = await context
                                                            .pushNamed(
                                                              AppRoutes
                                                                  .mapSelection
                                                                  .name,
                                                              extra: {
                                                                'isFromField':
                                                                    false,
                                                                'initialLocation':
                                                                    _currentLocation,
                                                              },
                                                            );
                                                        if (result != null &&
                                                            result
                                                                is Map<
                                                                  String,
                                                                  dynamic
                                                                >) {
                                                          setState(() {
                                                            stopController
                                                                    .text =
                                                                result['address'];
                                                            _stopCoordinates =
                                                                result['location'];
                                                          });
                                                        }
                                                      },
                                                      child: Container(
                                                        width: 24.w,
                                                        height: 24.h,
                                                        margin: EdgeInsets.only(
                                                          right: 16.w,
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
                                                    ),
                                                  ],
                                                ),
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 0,
                                                      vertical: 15.h,
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
                                            borderRadius: BorderRadius.circular(
                                              8.r,
                                            ),
                                          ),
                                          child: TextField(
                                            controller: toController,
                                            onTap: () => setState(
                                              () => _isFromFieldFocused = false,
                                            ),
                                            onChanged: (value) {
                                              if (!_isFromFieldFocused)
                                                _searchLocations(value);
                                            },
                                            decoration: InputDecoration(
                                              hintText: 'Where to',
                                              hintStyle: TextStyle(
                                                fontSize: 16.sp,
                                                color: Colors.grey[400],
                                              ),
                                              prefixIcon: Padding(
                                                padding: EdgeInsets.only(
                                                  left: 16.w,
                                                  right: 12.w,
                                                ),
                                                child: SvgPicture.asset(
                                                  ConstImages.search,
                                                  width: 20.w,
                                                  height: 20.h,
                                                  color: Colors.grey,
                                                  fit: BoxFit.scaleDown,
                                                ),
                                              ),
                                              prefixIconConstraints:
                                                  BoxConstraints(
                                                    minWidth: 48.w,
                                                    minHeight: 20.h,
                                                  ),
                                              suffixIcon: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (toController
                                                      .text
                                                      .isNotEmpty)
                                                    GestureDetector(
                                                      onTap: () => setState(
                                                        () => toController
                                                            .clear(),
                                                      ),
                                                      child: Container(
                                                        width: 24.w,
                                                        height: 24.h,
                                                        margin: EdgeInsets.only(
                                                          right: 8.w,
                                                        ),
                                                        child: Icon(
                                                          Icons.clear,
                                                          size: 16.sp,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ),
                                                  GestureDetector(
                                                    onTap: () async {
                                                      final result = await context
                                                          .pushNamed(
                                                            'mapSelection',
                                                            extra: {
                                                              'isFromField':
                                                                  false,
                                                              'initialLocation':
                                                                  _currentLocation,
                                                            },
                                                          );
                                                      if (result != null) {
                                                        final data =
                                                            result
                                                                as Map<
                                                                  String,
                                                                  dynamic
                                                                >;
                                                        setState(() {
                                                          toController.text =
                                                              data['address'];
                                                          _destinationCoordinates =
                                                              data['location'];
                                                        });
                                                        if (fromController
                                                            .text
                                                            .isNotEmpty)
                                                          _checkBothFields();
                                                      }
                                                    },
                                                    child: Container(
                                                      width: 24.w,
                                                      height: 24.h,
                                                      margin: EdgeInsets.only(
                                                        right: 16.w,
                                                      ),
                                                      child: Icon(
                                                        Icons.map,
                                                        size: 16.sp,
                                                        color: Color(
                                                          ConstColors.mainColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              border: InputBorder.none,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 0,
                                                    vertical: 15.h,
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
                          Expanded(
                            child: ListView(
                              controller: scrollController,
                              padding: EdgeInsets.zero,
                              children: [
                                if (_showSuggestions &&
                                    _locationSuggestions.isNotEmpty)
                                  LocationSuggestionsList(
                                    suggestions: _locationSuggestions,
                                    onSelect: (prediction) => _selectLocation(
                                      prediction,
                                      _isFromFieldFocused,
                                    ),
                                  ),
                                if (!_showSuggestions ||
                                    _locationSuggestions.isEmpty) ...[
                                  SizedBox(height: 15.h),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20.w,
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Saved location',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Inter',
                                          color: AppColors.kGreyColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 10.h),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20.w,
                                    ),
                                    child: Column(
                                      children: [
                                        Divider(
                                          thickness: 1,
                                          color: Colors.grey.shade300,
                                        ),
                                        AddLocationTile(
                                          title: 'Add home location',
                                          onTap: () async {
                                            final result = await context
                                                .pushNamed(
                                                  AppRoutes.addHome.name,
                                                  extra: {
                                                    'locationType': 'home',
                                                  },
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
                                        AddLocationTile(
                                          title: 'Add work location',
                                          onTap: () async {
                                            final result = await context
                                                .pushNamed(
                                                  AppRoutes.addHome.name,
                                                  extra: {
                                                    'locationType': 'work',
                                                  },
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
                                        AddLocationTile(
                                          title: 'Add favourite location',
                                          onTap: () async {
                                            final result = await context
                                                .pushNamed(
                                                  AppRoutes.addHome.name,
                                                  extra: {
                                                    'locationType': 'favourite',
                                                  },
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
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'Recent locations',
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w500,
                                              fontFamily: 'Inter',
                                              color: AppColors.kGreyColor,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 10.h),
                                        Divider(
                                          thickness: 1,
                                          color: Colors.grey.shade300,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Consumer<LocationProvider>(
                                    builder:
                                        (context, locationProvider, child) {
                                          final allLocations = <Widget>[];
                                          for (final fav
                                              in _favouriteLocations) {
                                            allLocations.add(
                                              FavoriteLocationItem(
                                                name: fav.name,
                                                address: fav.destAddress,
                                                id: fav.id,
                                                isFromFieldFocused:
                                                    _isFromFieldFocused,
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
                                                onLongPress: () {
                                                  _showDeleteLocationDialog(
                                                    fav.name,
                                                    fav.id,
                                                  );
                                                },
                                              ),
                                            );
                                          }
                                          for (final recent
                                              in locationProvider
                                                  .recentLocations) {
                                            if (!recent.isFavourite) {
                                              allLocations.add(
                                                RecentLocationItem(
                                                  recent: recent,
                                                  isFromFieldFocused:
                                                      _isFromFieldFocused,
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
                                              );
                                            }
                                          }
                                          return Column(children: allLocations);
                                        },
                                  ),
                                ],
                              ],
                            ),
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

  void _checkBothFields() async {
    if (fromController.text.length >= 3 && toController.text.length >= 3) {
      try {
        if (_pickupCoordinates == null && fromController.text.isNotEmpty) {
          AppLogger.log('Geocoding pickup address: ${fromController.text}');
          final pickupLocations = await locationFromAddress(
            fromController.text,
          );
          if (pickupLocations.isNotEmpty) {
            _pickupCoordinates = LatLng(
              pickupLocations.first.latitude,
              pickupLocations.first.longitude,
            );
            AppLogger.log(
              'Pickup geocoded to: ${_pickupCoordinates!.latitude}, ${_pickupCoordinates!.longitude}',
            );
          } else {
            AppLogger.log('No results found for pickup address');
          }
        }

        if (_destinationCoordinates == null && toController.text.isNotEmpty) {
          AppLogger.log('Geocoding destination address: ${toController.text}');
          final destLocations = await locationFromAddress(toController.text);
          if (destLocations.isNotEmpty) {
            _destinationCoordinates = LatLng(
              destLocations.first.latitude,
              destLocations.first.longitude,
            );
            AppLogger.log(
              'Destination geocoded to: ${_destinationCoordinates!.latitude}, ${_destinationCoordinates!.longitude}',
            );
          } else {
            AppLogger.log('No results found for destination address');
          }
        }
      } catch (e) {
        AppLogger.log('Error geocoding addresses: $e');
      }

      _updateMapWithRoute();
      _panelController.animatePanelToPosition(
        0.0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _showBookingDetails();
    }
  }

  void _updateMapWithRoute() async {
    _pickupCoordinates ??= _currentLocation;
    _destinationCoordinates ??= LatLng(
      _currentLocation.latitude + 0.01,
      _currentLocation.longitude + 0.01,
    );

    AppLogger.log('Getting real route path...');

    List<LatLng> routePoints = [];

    try {
      PolylinePoints polylinePoints = PolylinePoints();
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: UrlConstants.googleMapsApiKey,
        request: PolylineRequest(
          origin: PointLatLng(
            _pickupCoordinates!.latitude,
            _pickupCoordinates!.longitude,
          ),
          destination: PointLatLng(
            _destinationCoordinates!.latitude,
            _destinationCoordinates!.longitude,
          ),
          mode: TravelMode.driving,
          optimizeWaypoints: true,
        ),
      );

      if (result.points.isNotEmpty) {
        for (var point in result.points) {
          routePoints.add(LatLng(point.latitude, point.longitude));
        }
        AppLogger.log(
          'Got ${routePoints.length} route points from Directions API',
        );
      } else {
        AppLogger.log(
          'Directions API returned empty points. Error: ${result.errorMessage}',
        );
        routePoints = generateCurvedPath(
          _pickupCoordinates!,
          _destinationCoordinates!,
        );
        AppLogger.log(
          'Using curved path fallback with ${routePoints.length} points',
        );
      }
    } catch (e) {
      AppLogger.log('Error fetching route from Directions API: $e');
      routePoints = generateCurvedPath(
        _pickupCoordinates!,
        _destinationCoordinates!,
      );
      AppLogger.log(
        'Using curved path fallback with ${routePoints.length} points',
      );
    }

    AppLogger.log('Final route has ${routePoints.length} points');

    final pickupIcon = await _createBitmapDescriptorFromWidget(
      PickupMarkerWidget(
        driverArrivalTime: _driverArrivalTime,
        hasNearbyDriver: _hasNearbyDriver,
        isDriverAssigned: _isDriverAssigned,
        pickupAddress: null,
        fromText: fromController.text,
        currentLocationAddress: _currentLocationAddress,
      ),
      size: Size(247.w, 50.h),
    );

    final dropoffIcon = await _createBitmapDescriptorFromWidget(
      DropoffMarkerWidget(destAddress: null, toText: toController.text),
      size: Size(242.w, 48.h),
    );

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

    if (stopController.text.isNotEmpty) {
      final stopIcon = await _createBitmapDescriptorFromWidget(
        StopMarkerWidget(stopAddress: stopController.text),
        size: Size(200.w, 40.h),
      );

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
      barrierColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: 700.h,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 69.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 20.h),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.5.r),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select your vehicle',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
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
              Divider(thickness: 1, color: Colors.grey.shade300),
              SizedBox(height: 20.h),
              ..._buildVehicleOptions(setModalState),
              Spacer(),
              GestureDetector(
                onTap: selectedVehicle != null
                    ? () {
                        context.pop();
                        _showBookingDetails();
                      }
                    : null,
                child: Container(
                  width: double.infinity,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: selectedVehicle != null
                        ? Color(ConstColors.mainColor)
                        : Color(ConstColors.fieldColor),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
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
              SizedBox(height: 10.h),
            ],
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
          title = 'Regular';
          break;
        case 'fancy':
          title = 'Fancy';
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
            width: double.infinity,
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
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                      SizedBox(height: 5.h),
                      Text(
                        '${_currentEstimate!.durationMin.round()} min | 4 passengers',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Inter',
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_currentEstimate!.currency}${totalFare.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
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
    _isBookingRide = false;

    try {
      await _estimateRide();
    } catch (e) {
      AppLogger.log('Failed to get estimate: $e');
      return;
    }

    if (_currentEstimate == null) return;

    if (selectedVehicle == null) {
      setState(() {
        selectedVehicle = 0;
      });
    }

    final selectedOption = selectedVehicle != null
        ? ['Regular', 'Fancy', 'VIP'][selectedVehicle!]
        : ['Bicycle', 'Vehicle', 'Motor bike'][selectedDelivery!];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.2),
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setBookingState) => Container(
          height: 351.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              SizedBox(height: 11.57.h),
              Center(
                child: Container(
                  width: 69.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: Color(0xFFD1D1D6),
                    borderRadius: BorderRadius.circular(2.5.r),
                  ),
                ),
              ),
              SizedBox(height: 18.h),
              GestureDetector(
                onTap: () => _showAddNoteSheet(
                  onNoteChanged: () {
                    setBookingState(() {});
                  },
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.message, size: 28.sp, color: Colors.black),
                          SizedBox(height: 8.h),
                          Text(
                            'Add note',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      if (noteController.text.isNotEmpty)
                        Positioned(
                          top: -4.h,
                          right: -4.w,
                          child: Container(
                            width: 24.w,
                            height: 24.h,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16.sp,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 15.h),
              Divider(thickness: 1, height: 1, color: Color(0xFFE5E5EA)),
              SizedBox(height: 16.h),
              GestureDetector(
                onTap: () {
                  context.pop();
                  _showVehicleSelection();
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: [
                      Image.asset(
                        selectedVehicle != null
                            ? ConstImages.car
                            : ConstImages.bike,
                        width: 60.w,
                        height: 29.h,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedOption,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '4 passengers',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF8E8E93),
                              ),
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
                                : '#45,000',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            _currentEstimate != null
                                ? '${_currentEstimate!.durationMin.round()} min'
                                : 'Fixed',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 12.w),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 18.sp,
                        color: Color(0xFF8E8E93),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Divider(thickness: 1, height: 1, color: Color(0xFFE5E5EA)),
              SizedBox(height: 16.h),
              GestureDetector(
                onTap: () => _showPaymentMethods(
                  onPaymentChanged: () {
                    setBookingState(() {});
                  },
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: [
                      Container(
                        width: 80.w,
                        height: 38.h,
                        child: Image.asset(
                          width: 80.w,
                          height: 38.h,
                          _getPaymentMethodIcon(selectedPaymentMethod),
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          selectedPaymentMethod,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 18.sp,
                        color: Color(0xFF8E8E93),
                      ),
                    ],
                  ),
                ),
              ),
              Spacer(),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 30.h),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          context.pop();
                          _showPrebookSheet();
                        },
                        child: Container(
                          height: 47.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: Color(0xFFD1D1D6),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Center(
                            child: Text(
                              'Later',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: GestureDetector(
                        onTap: !_isBookingRide
                            ? () async {
                                _panelController.animatePanelToPosition(
                                  0.0,
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                                if (selectedPaymentMethod == 'Pay with card') {
                                  setBookingState(() {
                                    _isBookingRide = true;
                                  });

                                  try {
                                    AppLogger.log(
                                      'BOOK NOW - CARD PAYMENT: Starting ride request...',
                                    );
                                    AppLogger.log(
                                      'Selected Payment Method: $selectedPaymentMethod',
                                    );
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
                                        'Ride request successful for card payment',
                                      );
                                      AppLogger.log(
                                        'Ride ID: ${_currentRideResponse!.id}',
                                      );
                                      AppLogger.log(
                                        'Ride Price: ${_currentRideResponse!.price}',
                                      );
                                      final paymentData = await _paymentService
                                          .initializePayment(
                                            rideId: _currentRideResponse!.id,
                                            amount: _currentRideResponse!.price,
                                          );
                                      if (paymentData['authorization_url'] !=
                                          null) {
                                        AppLogger.log(
                                          'Opening payment webview',
                                          tag: 'BOOK_NOW',
                                        );
                                        final result = await context.pushNamed(
                                          AppRoutes.paymentWebView.name,
                                          extra: {
                                            'authorizationUrl':
                                                paymentData['authorization_url'],
                                            'reference':
                                                paymentData['reference'],
                                            'onPaymentSuccess': () {},
                                          },
                                        );
                                        if (result == true) {
                                          if (mounted) {
                                            fromController.clear();
                                            toController.clear();
                                            setState(() {
                                              _showDestinationField = false;
                                            });
                                            Navigator.pop(context);
                                            if (isScheduledRide) {
                                              final pickupAddress =
                                                  fromController.text.isNotEmpty
                                                  ? fromController.text
                                                  : _currentLocationAddress;
                                              final destAddress =
                                                  toController.text.isNotEmpty
                                                  ? toController.text
                                                  : 'Destination';
                                              _showTripScheduledSheet(
                                                pickupAddress: pickupAddress,
                                                destAddress: destAddress,
                                              );
                                              setState(() {
                                                isScheduledRide = false;
                                              });
                                            } else {
                                              _panelController
                                                  .animatePanelToPosition(
                                                    0.0,
                                                    duration: Duration(
                                                      milliseconds: 300,
                                                    ),
                                                    curve: Curves.easeInOut,
                                                  );
                                              _showBookSuccessfulSheet();
                                            }
                                          }
                                        } else {}
                                      }
                                    }
                                  } catch (e) {
                                    AppLogger.error(
                                      'Card payment failed',
                                      error: e,
                                      tag: 'BOOK_NOW',
                                    );
                                    if (mounted) {
                                      final errorMessage = e.toString();
                                      if (errorMessage.contains(
                                            'active ride',
                                          ) ||
                                          errorMessage.contains(
                                            'complete it before',
                                          )) {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15.r),
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
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                                      context.pop(),
                                                  child: Text(
                                                    'OK',
                                                    style: TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontSize: 16.sp,
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                        CustomFlushbar.showError(
                                          context: context,
                                          message: '${e.toString()}',
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
                                  setBookingState(() {
                                    _isBookingRide = true;
                                  });
                                  try {
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
                                    if (_currentRideResponse != null &&
                                        mounted) {
                                      AppLogger.log(
                                        'Ride ID: ${_currentRideResponse!.id}',
                                      );
                                      AppLogger.log(
                                        'Ride Price: ${_currentRideResponse!.price}',
                                      );
                                      if (selectedPaymentMethod ==
                                          'Pay with wallet') {
                                        setState(() {
                                          selectedPaymentMethod = 'wallet';
                                        });

                                        final scheduledDateTime =
                                            isScheduledRide
                                            ? DateTime(
                                                selectedDate.year,
                                                selectedDate.month,
                                                selectedDate.day,
                                                selectedTime.hour,
                                                selectedTime.minute,
                                              )
                                            : null;

                                        _currentRideResponse =
                                            await _requestRide(
                                              isScheduled: isScheduledRide,
                                              scheduledDateTime:
                                                  scheduledDateTime,
                                            );

                                        if (mounted) {
                                          fromController.clear();
                                          toController.clear();
                                          setState(() {
                                            _showDestinationField = false;
                                          });
                                          context.pop();
                                          if (isScheduledRide) {
                                            final pickupAddress =
                                                _currentRideResponse!
                                                    .pickupAddress;
                                            final destAddress =
                                                _currentRideResponse!
                                                    .destAddress;
                                            _showTripScheduledSheet(
                                              pickupAddress: pickupAddress,
                                              destAddress: destAddress,
                                            );
                                            setState(() {
                                              isScheduledRide = false;
                                            });
                                          } else {
                                            _panelController
                                                .animatePanelToPosition(
                                                  0.0,
                                                  duration: Duration(
                                                    milliseconds: 300,
                                                  ),
                                                  curve: Curves.easeInOut,
                                                );
                                            _showBookSuccessfulSheet();
                                          }
                                        }
                                      } else {
                                        if (mounted) {
                                          fromController.clear();
                                          toController.clear();
                                          setState(() {
                                            _showDestinationField = false;
                                          });
                                          context.pop();

                                          if (isScheduledRide) {
                                            final pickupAddress =
                                                _currentRideResponse!
                                                    .pickupAddress;
                                            final destAddress =
                                                _currentRideResponse!
                                                    .destAddress;
                                            _showTripScheduledSheet(
                                              pickupAddress: pickupAddress,
                                              destAddress: destAddress,
                                            );
                                            setState(() {
                                              isScheduledRide = false;
                                            });
                                          } else {
                                            _panelController
                                                .animatePanelToPosition(
                                                  0.0,
                                                  duration: Duration(
                                                    milliseconds: 300,
                                                  ),
                                                  curve: Curves.easeInOut,
                                                );
                                            _showBookSuccessfulSheet();
                                          }
                                        }
                                      }
                                    }
                                  } catch (e) {
                                    AppLogger.error(
                                      'OTHER PAYMENT - Ride request failed',
                                      error: e,
                                      tag: 'BOOK_NOW',
                                    );
                                    if (mounted) {
                                      setBookingState(() {
                                        _isBookingRide = false;
                                      });
                                      final errorMessage = e.toString();
                                      if (errorMessage.toLowerCase().contains(
                                            'insufficient',
                                          ) ||
                                          errorMessage.toLowerCase().contains(
                                            'balance',
                                          )) {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext dialogContext) {
                                            return Dialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16.r),
                                              ),
                                              child: Container(
                                                padding: EdgeInsets.all(24.w),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        16.r,
                                                      ),
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Image.asset(
                                                      "assets/images/error.png",
                                                      height: 80.h,
                                                      width: 80.w,
                                                      fit: BoxFit.contain,
                                                    ),
                                                    SizedBox(height: 10.h),
                                                    Text(
                                                      'Insufficient Balance',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        fontFamily: 'Inter',
                                                        fontSize: 18.sp,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    SizedBox(height: 8.h),
                                                    Text(
                                                      "Your wallet balance isn't enough to request this ride. Please add funds to continue",
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        fontFamily: 'Inter',
                                                        fontSize: 14.sp,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    SizedBox(height: 24.h),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: GestureDetector(
                                                            onTap: () {
                                                              Navigator.pop(
                                                                dialogContext,
                                                              );
                                                              _showPaymentMethods(
                                                                onPaymentChanged:
                                                                    () {
                                                                      setBookingState(
                                                                        () {},
                                                                      );
                                                                    },
                                                              );
                                                            },
                                                            child: Container(
                                                              height: 48.h,
                                                              decoration:
                                                                  BoxDecoration(
                                                                    color: Color(
                                                                      0xffB1B1B1,
                                                                    ),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          8.r,
                                                                        ),
                                                                  ),
                                                              child: Center(
                                                                child: Text(
                                                                  'Other Payment',
                                                                  style: TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        14.sp,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(width: 12.w),
                                                        Expanded(
                                                          child: GestureDetector(
                                                            onTap: () {
                                                              Navigator.pop(
                                                                dialogContext,
                                                              );
                                                              _navigateToWallet();
                                                            },
                                                            child: Container(
                                                              height: 48.h,
                                                              decoration: BoxDecoration(
                                                                color: Color(
                                                                  ConstColors
                                                                      .mainColor,
                                                                ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      8.r,
                                                                    ),
                                                              ),
                                                              child: Center(
                                                                child: Text(
                                                                  'Top Up Wallet',
                                                                  style: TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        14.sp,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
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
                                            );
                                          },
                                        );
                                      } else if (errorMessage.contains(
                                            'active ride',
                                          ) ||
                                          errorMessage.contains(
                                            'complete it before',
                                          )) {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15.r),
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
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                        CustomFlushbar.showError(
                                          context: context,
                                          message: e.toString(),
                                        );
                                      }
                                    }
                                  }
                                }
                              }
                            : null,
                        child: Container(
                          height: 47.h,
                          decoration: BoxDecoration(
                            color: _isBookingRide
                                ? Color(ConstColors.mainColor).withOpacity(0.7)
                                : Color(ConstColors.mainColor),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Center(
                            child: _isBookingRide
                                ? SizedBox(
                                    width: 24.w,
                                    height: 24.h,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : isScheduledRide
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Confirm Booking',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        '${selectedDate.day} ${_getMonth(selectedDate.month)} ${selectedTime.format(context)}',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    'Book now',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
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

  void _showPaymentMethods({VoidCallback? onPaymentChanged}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF2C9BE0),
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              context.pushNamed(AppRoutes.promoCode.name);
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFF2C9BE0),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Apply 20% off promo code>>',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            child: DecoratedBox(
              decoration: BoxDecoration(color: Colors.white),
              child: Padding(
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
                    _buildPaymentOption(
                      'Pay with wallet',
                      onPaymentChanged: onPaymentChanged,
                    ),
                    Divider(thickness: 1, color: Colors.grey.shade300),
                    _buildPaymentOption(
                      'Pay with card',
                      onPaymentChanged: onPaymentChanged,
                    ),
                    Divider(thickness: 1, color: Colors.grey.shade300),
                    _buildPaymentOption(
                      'Pay in car',
                      onPaymentChanged: onPaymentChanged,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'Pay with wallet':
        return 'assets/images/wallet_icon.png';
      case 'Pay with card':
        return 'assets/images/card_icon.png';
      case 'pay4me':
        return 'assets/images/pay4me_icon.png';
      case 'Pay in car':
        return 'assets/images/payincar_icon.png';
      default:
        return 'assets/images/wallet_icon.png';
    }
  }

  Widget _buildPaymentOption(String method, {VoidCallback? onPaymentChanged}) {
    final isSelected = selectedPaymentMethod == method;
    return GestureDetector(
      onTap: () {
        AppLogger.log(
          'Payment method selected: $method',
          tag: 'PAYMENT_METHOD',
        );
        AppLogger.log('Previous payment method: $selectedPaymentMethod');
        setState(() {
          selectedPaymentMethod = method;
        });
        AppLogger.log('New payment method set: $selectedPaymentMethod');

        if (onPaymentChanged != null) {
          onPaymentChanged();
        }
        Navigator.pop(context);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 15.h),
        child: Row(
          children: [
            Image.asset(
              _getPaymentMethodIcon(method),
              width: 55.w,
              height: 30.h,
              fit: BoxFit.cover,
            ),
            SizedBox(width: 15.w),
            Expanded(
              child: Text(method, style: TextStyle(fontSize: 16.sp)),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Colors.green, size: 20.sp),
          ],
        ),
      ),
    );
  }

  void _showAddNoteSheet({VoidCallback? onNoteChanged}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.2),
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
                GestureDetector(
                  onTap: noteController.text.isNotEmpty
                      ? () {
                          if (onNoteChanged != null) {
                            onNoteChanged();
                          }
                          context.pop();
                        }
                      : null,
                  child: Container(
                    width: 353.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: noteController.text.isNotEmpty
                          ? Color(ConstColors.mainColor)
                          : Color(ConstColors.fieldColor),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
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
      barrierColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setPrebookState) => Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 69.w,
                  height: 5.h,
                  margin: EdgeInsets.only(bottom: 20.h),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.5.r),
                  ),
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
              Text(
                'Select time and date',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10.h),
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
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                    color: Colors.black,
                  ),
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: Color(ConstColors.mainColor),
                            onPrimary: Colors.white,
                            onSurface: Colors.black,
                            surface: Colors.white,
                          ),
                          dialogBackgroundColor: Colors.white,
                        ),
                        child: child!,
                      );
                    },
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
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                    color: Colors.black,
                  ),
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: Color(ConstColors.mainColor),
                            onPrimary: Colors.white,
                            onSurface: Colors.black,
                            surface: Colors.white,
                          ),
                          dialogBackgroundColor: Colors.white,
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null && picked != selectedTime) {
                    setPrebookState(() {
                      selectedTime = picked;
                    });
                  }
                },
              ),
              SizedBox(height: 20.h),
              GestureDetector(
                onTap: () {
                  setPrebookState(() {
                    selectedDate = DateTime.now().add(Duration(days: 1));
                    selectedTime = TimeOfDay.now();
                  });
                },
                child: Container(
                  width: double.infinity,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Color(ConstColors.greyColor)),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Center(
                    child: Text(
                      'Reset to now',
                      style: TextStyle(
                        color: Color(ConstColors.blackColor),
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              GestureDetector(
                onTap: () {
                  setState(() {
                    isScheduledRide = true;
                  });
                  Navigator.pop(context);
                  _showBookingDetails();
                },
                child: Container(
                  width: double.infinity,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: Color(ConstColors.mainColor),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
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
              SizedBox(height: 10.h),
            ],
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

  Future<void> _openGoogleMaps() async {
    try {
      if (_activeRide == null) {
        CustomFlushbar.showError(context: context, message: 'No active ride');
        return;
      }

      String? destinationAddress;
      final rideStatus = _activeRide!['Status'] ?? 'accepted';

      if (rideStatus == 'started') {
        destinationAddress = _activeRide!['DestAddress'];
      } else {
        destinationAddress = _activeRide!['PickupAddress'];
      }

      if (destinationAddress == null || destinationAddress.isEmpty) {
        CustomFlushbar.showError(
          context: context,
          message: 'Location address not available',
        );
        return;
      }

      final encodedAddress = Uri.encodeComponent(destinationAddress);
      final url =
          'https://www.google.com/maps/search/?api=1&query=$encodedAddress';

      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        CustomFlushbar.showError(
          context: context,
          message: 'Could not open Google Maps',
        );
      }
    } catch (e) {
      AppLogger.log('Error opening Google Maps: $e');
      CustomFlushbar.showError(
        context: context,
        message: 'Failed to open Google Maps',
      );
    }
  }

  void _showDriverAcceptedSheet() {
    if (_isActiveRideSheetVisible) return;
    _isActiveRideSheetVisible = true;

    final bool hasArrived =
        _activeRide?['Status']?.toString().toLowerCase() == 'arrived';
    final bool hasStarted =
        _activeRide?['Status']?.toString().toLowerCase() == 'started';
    log("this is the arrived bool $hasArrived");
    log("this is the started bool $hasStarted");
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.2),
      isDismissible: true,
      enableDrag: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasStarted)
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: _openGoogleMaps,
                child: Container(
                  margin: EdgeInsets.only(bottom: 10.h, right: 5.w),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.navigation, color: Colors.black, size: 20.sp),
                      SizedBox(width: 8.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Navigation',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 12.sp,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            'Open in map',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                              fontSize: 10.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.black,
                        size: 12.sp,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Column(
            children: [
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20.r),
                  ),
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
                    Row(
                      children: [
                        if (!hasStarted && !hasArrived) ...[
                          SizedBox(
                            width: 60.w,
                            height: 60.h,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 60.w,
                                  height: 60.h,
                                  decoration: BoxDecoration(
                                    color: Color(ConstColors.mainColor),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _driverArrivalTime,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'min',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.all(8),
                                  width: 60.w,
                                  height: 60.h,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                    backgroundColor: Colors.transparent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 15.w),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                  if (hasArrived || hasStarted)
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
                              SizedBox(height: 16.h),
                              Divider(
                                thickness: 1,
                                color: Colors.grey.shade300,
                              ),
                              SizedBox(height: 20.h),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        if (_assignedDriver != null) ...[
                          Container(
                            margin: !hasStarted && !hasArrived
                                ? EdgeInsets.only(left: 69.5.w)
                                : EdgeInsets.only(left: 1.w),
                            child: DriverDetailRow(
                              label: 'Driver name: ',
                              value: _assignedDriver!.name,
                            ),
                          ),
                          SizedBox(height: 20.h),
                          if (!hasStarted) ...[
                            Container(
                              margin: !hasStarted && !hasArrived
                                  ? EdgeInsets.only(left: 69.5.w)
                                  : EdgeInsets.only(left: 1.w),
                              child: Row(
                                children: [
                                  Text(
                                    'Driver rating: ',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w500,
                                      height: 1.0,
                                      letterSpacing: -0.32,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 16.sp,
                                        color: Colors.amber,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        _assignedDriver!.rating.toStringAsFixed(
                                          1,
                                        ),
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
                            SizedBox(height: 20.h),
                          ],
                          Container(
                            margin: !hasStarted && !hasArrived
                                ? EdgeInsets.only(left: 69.5.w)
                                : EdgeInsets.only(left: 1.w),
                            child: DriverDetailRow(
                              label: 'Plate number: ',
                              value: _assignedDriver!.plateNumber,
                            ),
                          ),
                          SizedBox(height: 20.h),
                          if (!hasStarted) ...[
                            Container(
                              margin: !hasStarted && !hasArrived
                                  ? EdgeInsets.only(left: 69.5.w)
                                  : EdgeInsets.only(left: 1.w),
                              child: DriverDetailRow(
                                label: 'Car: ',
                                value: _assignedDriver!.vehicleModel,
                              ),
                            ),
                            SizedBox(height: 20.h),
                          ],
                          Container(
                            margin: !hasStarted && !hasArrived
                                ? EdgeInsets.only(left: 69.5.w)
                                : EdgeInsets.only(left: 1.w),
                            alignment: Alignment.center,
                            child: DriverDetailRow(
                              label: 'Trip ID: ',
                              value: _activeRide?['ID']?.toString() ?? 'N/A',
                            ),
                          ),
                          SizedBox(height: 20.h),
                          Container(
                            margin: !hasStarted && !hasArrived
                                ? EdgeInsets.only(left: 69.5.w)
                                : EdgeInsets.only(left: 1.w),
                            alignment: Alignment.center,
                            child: DriverDetailRow(
                              label: 'Price: #',
                              value: CurrencyFormatter.format(
                                _activeRide?['Price']?.toString() ?? "",
                              ),
                            ),
                          ),
                          SizedBox(height: 20.h),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                          if (_activeRide != null) {
                                            try {
                                              showDialog(
                                                context: context,
                                                barrierDismissible: false,
                                                builder: (context) => Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              );

                                              final position =
                                                  await Geolocator.getCurrentPosition(
                                                    desiredAccuracy:
                                                        LocationAccuracy.high,
                                                  );

                                              String locationAddress =
                                                  'Unknown location';
                                              try {
                                                final placemarks =
                                                    await placemarkFromCoordinates(
                                                      position.latitude,
                                                      position.longitude,
                                                    );
                                                if (placemarks.isNotEmpty) {
                                                  final placemark =
                                                      placemarks.first;
                                                  locationAddress =
                                                      '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}';
                                                }
                                              } catch (e) {
                                                AppLogger.log(
                                                  'Failed to get address: $e',
                                                  tag: 'SOS',
                                                );
                                              }

                                              final location =
                                                  'POINT(${position.longitude} ${position.latitude})';

                                              final rideId =
                                                  _activeRide?['ID'] is int
                                                  ? _activeRide!['ID']
                                                  : int.parse(
                                                      _activeRide?['ID']
                                                              ?.toString() ??
                                                          '0',
                                                    );

                                              final result = await _rideService
                                                  .sendSOS(
                                                    location: location,
                                                    locationAddress:
                                                        locationAddress,
                                                    rideId: rideId,
                                                  );

                                              Navigator.pop(context);

                                              if (result['success'] == true) {
                                                CustomFlushbar.showSuccess(
                                                  context: context,
                                                  message:
                                                      'SOS alert sent successfully!',
                                                );
                                              } else {
                                                CustomFlushbar.showError(
                                                  context: context,
                                                  message:
                                                      'Failed to send SOS: ${result['message']}',
                                                );
                                              }
                                            } catch (e) {
                                              Navigator.pop(context);
                                              CustomFlushbar.showError(
                                                context: context,
                                                message:
                                                    'Error sending SOS: $e',
                                              );
                                              AppLogger.error(
                                                'SOS Error',
                                                error: e,
                                                tag: 'SOS',
                                              );
                                            }
                                          }
                                        } else if (hasArrived) {
                                          context.pushNamed(
                                            'call',
                                            extra: {
                                              'driverName':
                                                  _assignedDriver!.name,
                                              'rideId':
                                                  _activeRide?['ID'] is int
                                                  ? _activeRide!['ID']
                                                  : int.parse(
                                                      _activeRide?['ID']
                                                              ?.toString() ??
                                                          '0',
                                                    ),
                                            },
                                          );
                                        } else {
                                          if (_assignedDriver != null &&
                                              _activeRide != null) {
                                            Navigator.pop(context);
                                            _showTripCanceledSheet();
                                          }
                                        }
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          hasStarted
                                              ? Image.asset(
                                                  "assets/images/soss.png",
                                                  height: 28.h,
                                                  width: 28.w,
                                                  fit: BoxFit.contain,
                                                )
                                              : Icon(
                                                  hasArrived
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
                                                  : hasArrived
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
                                          try {
                                            final position =
                                                await Geolocator.getCurrentPosition(
                                                  desiredAccuracy:
                                                      LocationAccuracy.high,
                                                );
                                            final lat = position.latitude;
                                            final lng = position.longitude;
                                            final mapsUrl =
                                                'https://www.google.com/maps?q=$lat,$lng';
                                            String locationInfo =
                                                'My current location';
                                            try {
                                              final placemarks =
                                                  await placemarkFromCoordinates(
                                                    lat,
                                                    lng,
                                                  );
                                              if (placemarks.isNotEmpty) {
                                                final placemark =
                                                    placemarks.first;
                                                locationInfo =
                                                    '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}';
                                              }
                                            } catch (e) {
                                              AppLogger.log(
                                                'Failed to get address: $e',
                                                tag: 'SHARE',
                                              );
                                            }
                                            await Share.share(
                                              "I'm currently here:\n$locationInfo\n\nView on map: $mapsUrl",
                                              subject: 'My Location',
                                            );
                                          } catch (e) {
                                            AppLogger.error(
                                              'Share location error',
                                              error: e,
                                              tag: 'SHARE',
                                            );
                                            CustomFlushbar.showError(
                                              context: context,
                                              message:
                                                  'Failed to share location: $e',
                                            );
                                          }
                                        } else {
                                          if (_assignedDriver != null) {
                                            context.pushNamed(
                                              AppRoutes.chat.name,
                                              extra: {
                                                'rideId':
                                                    _activeRide?['ID'] is int
                                                    ? _activeRide!['ID']
                                                    : int.parse(
                                                        _activeRide?['ID']
                                                                ?.toString() ??
                                                            '0',
                                                      ),
                                                'driverId':
                                                    _assignedDriver?.id ?? '0',
                                                'driverName':
                                                    _assignedDriver?.name ??
                                                    'Driver',
                                                'driverImage': _assignedDriver
                                                    ?.profilePicture,
                                                'driverPhone': _assignedDriver
                                                    ?.phoneNumber,
                                              },
                                            );
                                          }
                                        }
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            hasStarted
                                                ? Icons.share
                                                : Icons.chat,
                                            size: 16.sp,
                                            color: Colors.black,
                                          ),
                                          SizedBox(width: 8.w),
                                          Text(
                                            hasStarted
                                                ? 'Share'
                                                : 'Chat Driver',
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
            ],
          ),
        ],
      ),
    ).whenComplete(() {
      _isActiveRideSheetVisible = false;
      _hasUserDismissedSheet = true;
    });
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
                'Please note that charges may apply if you cancel the ride now.',
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
                  CustomFlushbar.showError(
                    context: context,
                    message: 'Please provide a reason for cancellation',
                  );
                  return;
                }
                context.pop();
                showDialog(
                  context: this.context,
                  barrierDismissible: false,
                  builder: (context) => Center(
                    child: CircularProgressIndicator(
                      color: Color(ConstColors.mainColor),
                    ),
                  ),
                );
                try {
                  final rideId = _activeRide?['ID'] is int
                      ? _activeRide!['ID']
                      : int.parse(_activeRide?['ID']?.toString() ?? '0');

                  final result = await _rideService.cancelRide(
                    rideId: rideId,
                    reason: reason,
                  );
                  if (mounted &&
                      Navigator.of(
                        this.context,
                        rootNavigator: true,
                      ).canPop()) {
                    Navigator.of(this.context, rootNavigator: true).pop();
                  }
                  if (result['success'] == true) {
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
                      _stopDriverLocationTracking();
                      CustomFlushbar.showSuccess(
                        context: this.context,
                        message: 'Ride cancelled successfully',
                      );
                    }
                  } else {
                    if (mounted) {
                      CustomFlushbar.showError(
                        context: this.context,
                        message:
                            result['message']["error"] ??
                            'Failed to cancel ride',
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.of(this.context, rootNavigator: true).pop();
                  }
                  AppLogger.error('Cancel ride error', error: e, tag: 'CANCEL');
                  if (mounted) {
                    CustomFlushbar.showError(
                      context: this.context,
                      message: 'Error cancelling ride: $e',
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

  void _showDriverAvailabilitySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (context) {
        return Container(
          margin: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 24.h),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.all(Radius.circular(24.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "There are no available drivers at the moment please try again",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 16.h),
              Image.asset("assets/images/faill.png", width: 92.w, height: 92.h),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final parentContext = context;
                        Navigator.pop(parentContext);
                        final rideId =
                            _currentRideResponse?.id ??
                            (_activeRide?['ID'] is int
                                ? _activeRide!['ID']
                                : int.parse(
                                    _activeRide?['ID']?.toString() ?? '0',
                                  ));

                        showDialog(
                          context: this.context,
                          barrierDismissible: false,
                          builder: (dialogContext) => Center(
                            child: CircularProgressIndicator(
                              color: Color(ConstColors.mainColor),
                            ),
                          ),
                        );

                        try {
                          final result = await _rideService.cancelRide(
                            rideId: rideId,
                            reason: 'No drivers available',
                          );
                          if (mounted) {
                            Navigator.of(this.context).pop();
                          }
                          if (result['success'] == true) {
                            if (mounted) {
                              setState(() {
                                _activeRide = null;
                                _isDriverAssigned = false;
                                _isRideAccepted = false;
                                _isInCar = false;
                                _assignedDriver = null;
                                _currentRideResponse = null;
                                _mapMarkers = {};
                                _mapPolylines = {};
                              });
                              _stopDriverLocationTracking();
                              CustomFlushbar.showSuccess(
                                context: this.context,
                                message: 'Ride cancelled successfully',
                              );
                            }
                          } else {
                            if (mounted) {
                              CustomFlushbar.showError(
                                context: this.context,
                                message:
                                    result['message'] ??
                                    'Failed to cancel ride',
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            Navigator.of(this.context).pop();
                          }
                          AppLogger.error(
                            'Cancel ride error',
                            error: e,
                            tag: 'DRIVER_AVAILABILITY',
                          );

                          if (mounted) {
                            CustomFlushbar.showError(
                              context: this.context,
                              message: 'Error cancelling ride: $e',
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xffB1B1B1),
                          borderRadius: BorderRadius.all(Radius.circular(8.r)),
                        ),
                        child: Center(
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 13.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        CustomFlushbar.showInfo(
                          context: context,
                          message: 'Still searching for available drivers...',
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: Color(ConstColors.mainColor),
                          borderRadius: BorderRadius.all(Radius.circular(8.r)),
                        ),
                        child: Center(
                          child: Text(
                            "Keep Waiting",
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
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
        );
      },
    );
  }

  void _showBookSuccessfulSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        height: 219.h,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              textAlign: TextAlign.left,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                height: 1.0,
                letterSpacing: -0.32,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 10.h),
            Divider(thickness: 1, color: Colors.grey.shade300),
            SizedBox(height: 10.h),
            SizedBox(
              width: 353.w,
              height: 10.h,
              child: LinearProgressIndicator(
                borderRadius: BorderRadius.circular(10.r),
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(ConstColors.mainColor),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            GestureDetector(
              onTap: () {
                _panelController.animatePanelToPosition(
                  0.0,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                Navigator.pop(context);
                _showTripDetailsSheet();
              },
              child: Container(
                width: 353.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: Color(ConstColors.mainColor),
                  borderRadius: BorderRadius.circular(8.r),
                ),
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
            ? ['Regular', 'Fancy', 'VIP'][selectedVehicle!]
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.2),
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 600.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          children: [
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_currentRideResponse?.id ?? '10923444'}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, size: 24.sp, color: Colors.black),
                  ),
                ],
              ),
            ),
            SizedBox(height: 13.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Divider(thickness: 1, height: 1, color: Color(0xFFE5E5EA)),
            ),
            SizedBox(height: 15.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8.w,
                        height: 8.h,
                        decoration: BoxDecoration(
                          color: Color(0xFF34C759),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Pick up',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    pickupAddr,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(height: 15.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Divider(thickness: 1, height: 1, color: Color(0xFFE5E5EA)),
            ),
            SizedBox(height: 15.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8.w,
                        height: 8.h,
                        decoration: BoxDecoration(
                          color: Color(0xFFFF3B30),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Destination',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    destAddr,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(height: 15.h),
            Divider(thickness: 1, height: 1, color: Color(0xFFE5E5EA)),
            SizedBox(height: 15.h),
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      currentDate,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 15.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Divider(thickness: 1, height: 1, color: Color(0xFFE5E5EA)),
            ),
            SizedBox(height: 15.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment method',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          paymentMethod,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1.w,
                    height: 44.h,
                    color: Color(0xFFE5E5EA),
                    margin: EdgeInsets.symmetric(horizontal: 16.w),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vehicle',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          selectedOption,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 15.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Divider(thickness: 1, height: 1, color: Color(0xFFE5E5EA)),
            ),
            SizedBox(height: 15.h),
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '#${_currentRideResponse?.price.toStringAsFixed(0) ?? '45,000'}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30.h),
            Container(
              height: 60.h,
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _panelController.animatePanelToPosition(
                          0.0,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.refresh_outlined,
                            size: 20.sp,
                            color: Colors.black,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Book Again',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(width: 1.w, height: 30.h, color: Color(0xFFE5E5EA)),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _showTripCanceledSheet();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cancel, size: 20.sp, color: Colors.red),
                          SizedBox(width: 8.w),
                          Text(
                            'Cancel Ride',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w400,
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
    );
  }

  void _showTripScheduledSheet({String? pickupAddress, String? destAddress}) {
    final selectedOption = selectedVehicle != null
        ? ['Regular', 'Fancy', 'VIP'][selectedVehicle!]
        : ['Bicycle', 'Vehicle', 'Motor bike'][selectedDelivery!];

    final scheduledDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    final formattedDate =
        '${_getMonth(scheduledDateTime.month)} ${scheduledDateTime.day}, ${scheduledDateTime.year} at ${selectedTime.format(context)}';

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
        height: 580.h,
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
              margin: EdgeInsets.only(bottom: 15.h),
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
            SizedBox(height: 15.h),
            Divider(thickness: 1, color: Colors.grey.shade300),
            SizedBox(height: 15.h),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Divider(thickness: 1, color: Colors.grey.shade300),
                  SizedBox(height: 12.h),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 15.h),
            Divider(thickness: 1, color: Colors.grey.shade300),
            SizedBox(height: 15.h),
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
            SizedBox(height: 15.h),
            Divider(thickness: 1, color: Colors.grey.shade300),
            SizedBox(height: 15.h),
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
            SizedBox(height: 15.h),
            Divider(thickness: 1, color: Colors.grey.shade300),
            SizedBox(height: 15.h),
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
            Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _panelController.animatePanelToPosition(
                  0.0,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                _showEditPrebookingSheet();
              },
              child: Container(
                width: 353.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: Color(ConstColors.mainColor),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Center(
                  child: Text(
                    'Edit prebooking',
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

  void _showEditPrebookingSheet() {
    if (fromController.text.isEmpty || toController.text.isEmpty) {
      String? pickupAddr;
      String? destAddr;
      String? pickupLoc;
      String? destLoc;

      if (_currentRideResponse != null) {
        pickupAddr = _currentRideResponse!.pickupAddress;
        destAddr = _currentRideResponse!.destAddress;
      }

      if (_activeRide != null) {
        pickupAddr ??= _activeRide!['PickupAddress'];
        destAddr ??= _activeRide!['DestAddress'];
        pickupLoc = _activeRide!['PickupLocation'];
        destLoc = _activeRide!['DestLocation'];
      }

      if (fromController.text.isEmpty && pickupAddr != null) {
        fromController.text = pickupAddr;
      }
      if (toController.text.isEmpty && destAddr != null) {
        toController.text = destAddr;
      }

      if (_pickupCoordinates == null && pickupLoc != null) {
        try {
          final content = pickupLoc
              .replaceAll('POINT(', '')
              .replaceAll(')', '')
              .trim();
          final parts = content.split(RegExp(r'\s+'));
          if (parts.length >= 2) {
            _pickupCoordinates = LatLng(
              double.parse(parts[1]),
              double.parse(parts[0]),
            );
          }
        } catch (_) {}
      }

      if (_destinationCoordinates == null && destLoc != null) {
        try {
          final content = destLoc
              .replaceAll('POINT(', '')
              .replaceAll(')', '')
              .trim();
          final parts = content.split(RegExp(r'\s+'));
          if (parts.length >= 2) {
            _destinationCoordinates = LatLng(
              double.parse(parts[1]),
              double.parse(parts[0]),
            );
          }
        } catch (_) {}
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final scheduledDateTime = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedTime.hour,
            selectedTime.minute,
          );
          final formattedDate =
              '${_getMonth(scheduledDateTime.month)} ${scheduledDateTime.day}, '
              '${scheduledDateTime.year} at ${selectedTime.format(context)}';
          return Container(
            height: 852.h,
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
                        'Edit PreBooking',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.close,
                          size: 24.sp,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30.h),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PICK UP',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        height: 50.h,
                        decoration: BoxDecoration(
                          color: Color(
                            ConstColors.fieldColor,
                          ).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: TextField(
                          controller: fromController,
                          onChanged: (value) {
                            setSheetState(() {
                              _isFromFieldFocused = true;
                            });
                            _searchLocations(value);
                          },
                          decoration: InputDecoration(
                            hintText: 'Enter pickup location',
                            hintStyle: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[400],
                            ),
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(left: 16.w, right: 12.w),
                              child: SvgPicture.asset(
                                ConstImages.search,
                                width: 20.w,
                                height: 20.h,
                                color: Colors.grey,
                                fit: BoxFit.scaleDown,
                              ),
                            ),
                            prefixIconConstraints: BoxConstraints(
                              minWidth: 48.w,
                              minHeight: 20.h,
                            ),
                            suffixIcon: GestureDetector(
                              onTap: () async {
                                Navigator.pop(context);
                                final result = await context.pushNamed(
                                  AppRoutes.mapSelection.name,
                                  extra: {
                                    'isFromField': true,
                                    'initialLocation':
                                        _pickupCoordinates ?? _currentLocation,
                                  },
                                );
                                if (result != null &&
                                    result is Map<String, dynamic>) {
                                  setSheetState(() {
                                    _pickupCoordinates =
                                        result['location'] as LatLng;
                                    fromController.text =
                                        result['address'] as String;
                                  });
                                  _panelController.animatePanelToPosition(
                                    0.0,
                                    duration: Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                  _showEditPrebookingSheet();
                                }
                              },
                              child: Container(
                                width: 24.w,
                                height: 24.h,
                                margin: EdgeInsets.only(right: 16.w),
                                child: Icon(
                                  Icons.map,
                                  size: 20.sp,
                                  color: Color(ConstColors.mainColor),
                                ),
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: 15.h,
                            ),
                          ),
                        ),
                      ),
                      if (_showSuggestions &&
                          _locationSuggestions.isNotEmpty &&
                          _isFromFieldFocused)
                        LocationSuggestionsList(
                          suggestions: _locationSuggestions,
                          onSelect: (prediction) async {
                            final placeDetails = await _placesService
                                .getPlaceDetails(
                                  prediction.placeId,
                                  sessionToken: _sessionToken,
                                );
                            if (placeDetails != null) {
                              setSheetState(() {
                                _pickupCoordinates = LatLng(
                                  placeDetails.latitude,
                                  placeDetails.longitude,
                                );
                                fromController.text = prediction.description;
                                _showSuggestions = false;
                                _locationSuggestions = [];
                                _sessionToken = null;
                              });
                            }
                          },
                        ),
                    ],
                  ),
                  SizedBox(height: 15.h),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DESTINATION',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        height: 50.h,
                        decoration: BoxDecoration(
                          color: Color(
                            ConstColors.fieldColor,
                          ).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: TextField(
                          controller: toController,
                          onChanged: (value) {
                            setSheetState(() {
                              _isFromFieldFocused = false;
                            });
                            _searchLocations(value);
                          },
                          decoration: InputDecoration(
                            hintText: 'Enter destination',
                            hintStyle: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[400],
                            ),
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(left: 16.w, right: 12.w),
                              child: SvgPicture.asset(
                                ConstImages.search,
                                width: 20.w,
                                height: 20.h,
                                color: Colors.grey,
                                fit: BoxFit.scaleDown,
                              ),
                            ),
                            prefixIconConstraints: BoxConstraints(
                              minWidth: 48.w,
                              minHeight: 20.h,
                            ),
                            suffixIcon: GestureDetector(
                              onTap: () async {
                                Navigator.pop(context);
                                final result = await context.pushNamed(
                                  AppRoutes.mapSelection.name,
                                  extra: {
                                    'isFromField': false,
                                    'initialLocation':
                                        _destinationCoordinates ??
                                        _currentLocation,
                                  },
                                );
                                if (result != null &&
                                    result is Map<String, dynamic>) {
                                  setSheetState(() {
                                    _destinationCoordinates =
                                        result['location'] as LatLng;
                                    toController.text =
                                        result['address'] as String;
                                  });
                                  _panelController.animatePanelToPosition(
                                    0.0,
                                    duration: Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                  _showEditPrebookingSheet();
                                }
                              },
                              child: Container(
                                width: 24.w,
                                height: 24.h,
                                margin: EdgeInsets.only(right: 16.w),
                                child: Icon(
                                  Icons.map,
                                  size: 20.sp,
                                  color: Color(ConstColors.mainColor),
                                ),
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: 15.h,
                            ),
                          ),
                        ),
                      ),
                      if (_showSuggestions &&
                          _locationSuggestions.isNotEmpty &&
                          !_isFromFieldFocused)
                        LocationSuggestionsList(
                          suggestions: _locationSuggestions,
                          onSelect: (prediction) async {
                            final placeDetails = await _placesService
                                .getPlaceDetails(
                                  prediction.placeId,
                                  sessionToken: _sessionToken,
                                );
                            if (placeDetails != null) {
                              setSheetState(() {
                                _destinationCoordinates = LatLng(
                                  placeDetails.latitude,
                                  placeDetails.longitude,
                                );
                                toController.text = prediction.description;
                                _showSuggestions = false;
                                _locationSuggestions = [];
                                _sessionToken = null;
                              });
                            }
                          },
                        ),
                    ],
                  ),
                  SizedBox(height: 15.h),
                  GestureDetector(
                    onTap: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                      );
                      if (pickedDate != null) {
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (pickedTime != null) {
                          setSheetState(() {
                            selectedDate = pickedDate;
                            selectedTime = pickedTime;
                          });
                        }
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WHEN',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          width: 353.w,
                          padding: EdgeInsets.symmetric(
                            horizontal: 15.w,
                            vertical: 15.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 15.h),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PAYMENT METHOD',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Color(0xFF2C9BE0),
                            barrierColor: Colors.black.withOpacity(0.2),
                            builder: (context) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    context.pushNamed(AppRoutes.promoCode.name);
                                  },
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Color(0xFF2C9BE0),
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20.r),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 20.w,
                                        vertical: 10.h,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Apply 20% off promo code>>',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16.r),
                                  ),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(20.w),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 69.w,
                                            height: 5.h,
                                            margin: EdgeInsets.only(
                                              bottom: 20.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade300,
                                              borderRadius:
                                                  BorderRadius.circular(2.5.r),
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
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
                                                onTap: () =>
                                                    Navigator.pop(context),
                                                child: Icon(
                                                  Icons.close,
                                                  size: 24.sp,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 20.h),
                                          _buildPaymentOption(
                                            'Pay with wallet',
                                          ),
                                          Divider(
                                            thickness: 1,
                                            color: Colors.grey.shade300,
                                          ),
                                          _buildPaymentOption('Pay with card'),
                                          Divider(
                                            thickness: 1,
                                            color: Colors.grey.shade300,
                                          ),
                                          _buildPaymentOption('Pay in car'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: 15.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            color: Color(
                              ConstColors.fieldColor,
                            ).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                _getPaymentMethodIcon(selectedPaymentMethod),
                                width: 60.w,
                                height: 28.h,
                                fit: BoxFit.contain,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  selectedPaymentMethod,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16.sp,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15.h),
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        barrierColor: Colors.black.withOpacity(0.2),
                        context: context,
                        builder: (context) => Container(
                          padding: EdgeInsets.all(20.w),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (selectedVehicle != null) ...[
                                ListTile(
                                  title: Text('Regular'),
                                  onTap: () {
                                    setSheetState(() {
                                      selectedVehicle = 0;
                                    });
                                    context.pop();
                                  },
                                ),
                                ListTile(
                                  title: Text('Fancy'),
                                  onTap: () {
                                    setSheetState(() {
                                      selectedVehicle = 1;
                                    });
                                    context.pop();
                                  },
                                ),
                                ListTile(
                                  title: Text('VIP'),
                                  onTap: () {
                                    setSheetState(() {
                                      selectedVehicle = 2;
                                    });
                                    context.pop();
                                  },
                                ),
                              ] else ...[
                                ListTile(
                                  title: Text('Bicycle'),
                                  onTap: () {
                                    setSheetState(() {
                                      selectedDelivery = 0;
                                    });
                                    context.pop();
                                  },
                                ),
                                ListTile(
                                  title: Text('Vehicle'),
                                  onTap: () {
                                    setSheetState(() {
                                      selectedDelivery = 1;
                                    });
                                    context.pop();
                                  },
                                ),
                                ListTile(
                                  title: Text('Motor bike'),
                                  onTap: () {
                                    setSheetState(() {
                                      selectedDelivery = 2;
                                    });
                                    context.pop();
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VEHICLE',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          width: 353.w,
                          padding: EdgeInsets.symmetric(
                            horizontal: 15.w,
                            vertical: 15.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                "assets/images/car.png",
                                width: 60.w,
                                height: 28.h,
                                fit: BoxFit.contain,
                              ),
                              SizedBox(width: 5.w),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedVehicle != null
                                        ? [
                                            'Regular',
                                            'Fancy',
                                            'VIP',
                                          ][selectedVehicle!]
                                        : [
                                            'Bicycle',
                                            'Vehicle',
                                            'Motor bike',
                                          ][selectedDelivery!],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                  Text(
                                    "4 Passengers",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xffB1B1B1),
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
                  SizedBox(height: 115.h),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _showTripCanceledSheet();
                        },
                        child: Container(
                          width: 353.w,
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.red),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
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
                      GestureDetector(
                        onTap: () async {
                          final rideId =
                              _currentRideResponse?.id ??
                              (_activeRide?['ID'] is int
                                  ? _activeRide!['ID']
                                  : int.parse(
                                      _activeRide?['ID']?.toString() ?? '0',
                                    ));

                          final pickupCoords =
                              _pickupCoordinates ?? _currentLocation;
                          final pickup =
                              'POINT(${pickupCoords.longitude} ${pickupCoords.latitude})';

                          final destCoords = _destinationCoordinates;
                          if (destCoords == null) {
                            CustomFlushbar.showError(
                              context: context,
                              message: 'Please select a destination',
                            );
                            return;
                          }
                          final dest =
                              'POINT(${destCoords.longitude} ${destCoords.latitude})';

                          final pickupAddress = fromController.text.isNotEmpty
                              ? fromController.text
                              : 'Current location';
                          final destAddress = toController.text;
                          if (destAddress.isEmpty) {
                            CustomFlushbar.showError(
                              context: context,
                              message: 'Please enter a destination',
                            );
                            return;
                          }

                          final scheduledDateTime = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );
                          final scheduledAt = scheduledDateTime
                              .toUtc()
                              .toIso8601String();
                          final stopAddress = stopController.text.isNotEmpty
                              ? stopController.text
                              : null;
                          final vehicleType = selectedVehicle != null
                              ? ['Regular', 'Fancy', 'VIP'][selectedVehicle!]
                              : [
                                  'Bicycle',
                                  'Vehicle',
                                  'Motor bike',
                                ][selectedDelivery!];

                          Navigator.pop(context);

                          showDialog(
                            context: this.context,
                            barrierDismissible: false,
                            builder: (context) => Center(
                              child: CircularProgressIndicator(
                                color: Color(ConstColors.mainColor),
                              ),
                            ),
                          );

                          try {
                            final result = await _rideService
                                .updatePrebookedRide(
                                  rideId: rideId,
                                  dest: dest,
                                  destAddress: destAddress,
                                  pickup: pickup,
                                  pickupAddress: pickupAddress,
                                  scheduledAt: scheduledAt,
                                  stopAddress: stopAddress,
                                  vehicleType: vehicleType,
                                );
                            if (result['success'] != true) {
                              if (mounted &&
                                  Navigator.of(
                                    this.context,
                                    rootNavigator: true,
                                  ).canPop()) {
                                Navigator.of(
                                  this.context,
                                  rootNavigator: true,
                                ).pop();
                              }
                              if (mounted) {
                                CustomFlushbar.showError(
                                  context: this.context,
                                  message:
                                      result['message'] ??
                                      'Failed to update ride',
                                );
                              }
                              return;
                            }
                            AppLogger.log(
                              'Prebooked ride updated: ${result['data']}',
                              tag: 'UPDATE_PREBOOKED',
                            );
                            if (selectedPaymentMethod == 'Pay with card') {
                              final price =
                                  _currentRideResponse?.price ??
                                  (_activeRide?['Price'] is double
                                      ? _activeRide!['Price']
                                      : double.tryParse(
                                              _activeRide?['Price']
                                                      ?.toString() ??
                                                  '0',
                                            ) ??
                                            0.0);

                              final paymentData = await _paymentService
                                  .initializePayment(
                                    rideId: rideId,
                                    amount: price,
                                  );
                              AppLogger.log(
                                'Payment data: $paymentData',
                                tag: 'UPDATE_PREBOOKED',
                              );
                              if (selectedPaymentMethod == 'Pay with card' &&
                                  paymentData['authorization_url'] != null) {
                                if (mounted &&
                                    Navigator.of(
                                      this.context,
                                      rootNavigator: true,
                                    ).canPop()) {
                                  Navigator.of(
                                    this.context,
                                    rootNavigator: true,
                                  ).pop();
                                }
                                final paymentResult = await context.pushNamed(
                                  AppRoutes.paymentWebView.name,
                                  extra: {
                                    'authorizationUrl':
                                        paymentData['authorization_url'],
                                    'reference': paymentData['reference'],
                                    'onPaymentSuccess': () {},
                                  },
                                );
                                if (paymentResult == true) {
                                  try {
                                    final verifyResult = await _paymentService
                                        .verifyPayment(
                                          paymentData['reference'],
                                        );
                                    if (!mounted) return;
                                    if (verifyResult['success'] == true ||
                                        verifyResult['status'] == 'success') {
                                      fromController.clear();
                                      toController.clear();
                                      setState(() {
                                        _showDestinationField = false;
                                      });
                                      Navigator.pop(context);
                                      if (isScheduledRide) {
                                        final pickupAddress =
                                            _currentRideResponse!.pickupAddress;
                                        final destAddress =
                                            _currentRideResponse!.destAddress;
                                        _showTripScheduledSheet(
                                          pickupAddress: pickupAddress,
                                          destAddress: destAddress,
                                        );
                                        setState(() {
                                          isScheduledRide = false;
                                        });
                                      } else {
                                        _panelController.animatePanelToPosition(
                                          0.0,
                                          duration: Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                        _showBookSuccessfulSheet();
                                      }
                                    } else {
                                      if (mounted) {
                                        setState(() {
                                          _isBookingRide = false;
                                        });
                                        CustomFlushbar.showError(
                                          context: context,
                                          message:
                                              verifyResult['message'] ??
                                              'Payment verification failed. Please try again.',
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      setState(() {
                                        _isBookingRide = false;
                                      });
                                      CustomFlushbar.showError(
                                        context: context,
                                        message: 'Error verifying payment: $e',
                                      );
                                    }
                                  }
                                } else {
                                  if (mounted) {
                                    setState(() {
                                      _isBookingRide = false;
                                    });
                                    CustomFlushbar.showError(
                                      context: context,
                                      message: 'Payment was not completed.',
                                    );
                                  }
                                }
                                return;
                              }
                            }
                            if (mounted &&
                                Navigator.of(
                                  this.context,
                                  rootNavigator: true,
                                ).canPop()) {
                              Navigator.of(
                                this.context,
                                rootNavigator: true,
                              ).pop();
                            }
                            if (mounted) {
                              CustomFlushbar.showSuccess(
                                context: this.context,
                                message: 'Prebooking saved successfully!',
                              );
                            }
                          } catch (e) {
                            if (mounted &&
                                Navigator.of(
                                  this.context,
                                  rootNavigator: true,
                                ).canPop()) {
                              Navigator.of(
                                this.context,
                                rootNavigator: true,
                              ).pop();
                            }
                            AppLogger.error(
                              'Save prebooked ride error',
                              error: e,
                              tag: 'UPDATE_PREBOOKED',
                            );
                            if (mounted) {
                              CustomFlushbar.showError(
                                context: this.context,
                                message: 'Error saving prebooking: $e',
                              );
                            }
                          }
                        },
                        child: Container(
                          width: 353.w,
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: Color(ConstColors.mainColor),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
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
          );
        },
      ),
    );
  }

  void _showTripCanceledSheet() {
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2),
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
              CancelReasonOption(
                index: 0,
                reason: 'I am taking alternative transport',
                isSelected: selectedCancelReason == 0,
                onTap: (index) {
                  setCancelState(() {
                    selectedCancelReason = index;
                  });
                },
              ),
              SizedBox(height: 10.h),
              CancelReasonOption(
                index: 1,
                reason: 'It is taking too long to get a driver',
                isSelected: selectedCancelReason == 1,
                onTap: (index) {
                  setCancelState(() {
                    selectedCancelReason = index;
                  });
                },
              ),
              SizedBox(height: 10.h),
              CancelReasonOption(
                index: 2,
                reason: 'I have to attend to something',
                isSelected: selectedCancelReason == 2,
                onTap: (index) {
                  setCancelState(() {
                    selectedCancelReason = index;
                  });
                },
              ),
              SizedBox(height: 10.h),
              CancelReasonOption(
                index: 3,
                reason: 'Others',
                isSelected: selectedCancelReason == 3,
                onTap: (index) {
                  setCancelState(() {
                    selectedCancelReason = index;
                  });
                },
              ),
              Spacer(),
              GestureDetector(
                onTap: selectedCancelReason != null
                    ? () {
                        if (selectedCancelReason == 3) {
                          Navigator.pop(context);
                          _showCancelRideDialog();
                        } else {
                          Navigator.pop(context);
                          _showFeedbackSuccessSheet();
                        }
                      }
                    : null,
                child: Container(
                  width: 353.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: selectedCancelReason != null
                        ? Color(ConstColors.mainColor)
                        : Color(ConstColors.fieldColor),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
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

  void _showFeedbackSuccessSheet() {
    final reasons = [
      'I am taking alternative transport',
      'It is taking too long to get a driver',
      'I have to attend to something',
      'Others',
    ];
    final reason = selectedCancelReason != null
        ? reasons[selectedCancelReason!]
        : 'Cancelled by passenger';

    () async {
      try {
        final rideId =
            _currentRideResponse?.id ??
            (_activeRide?['ID'] is int
                ? _activeRide!['ID']
                : int.parse(_activeRide?['ID']?.toString() ?? '0'));

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: CircularProgressIndicator(
              color: Color(ConstColors.mainColor),
            ),
          ),
        );

        final result = await _rideService.cancelRide(
          rideId: rideId,
          reason: reason,
        );
        log("this is the ride response $result");
        log("this is the ride id$rideId");
        if (mounted &&
            Navigator.of(this.context, rootNavigator: true).canPop()) {
          Navigator.of(this.context, rootNavigator: true).pop();
        }

        if (result['success'] == true) {
          if (mounted) {
            setState(() {
              _activeRide = null;
              _isDriverAssigned = false;
              _isRideAccepted = false;
              _isInCar = false;
              _assignedDriver = null;
              _currentRideResponse = null;
              _mapMarkers = {};
              _mapPolylines = {};
              _lastKnownRideStatus = null;
            });
            _stopDriverLocationTracking();
          }
        } else {
          if (mounted) {
            CustomFlushbar.showError(
              context: this.context,
              message: result['message'] ?? 'Failed to cancel ride',
            );
          }
          return;
        }
      } catch (e) {
        if (mounted &&
            Navigator.of(this.context, rootNavigator: true).canPop()) {
          Navigator.of(this.context, rootNavigator: true).pop();
        }
        if (mounted) {
          CustomFlushbar.showError(context: this.context, message: 'Error: $e');
        }
        return;
      }

      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        barrierColor: Colors.black.withOpacity(0.2),
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
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100.sp,
                height: 100.sp,
                decoration: BoxDecoration(
                  color: Color(0xff34B869),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: Colors.white, size: 40.sp),
              ),
              SizedBox(height: 10.h),
              Text(
                "Feedback Sent",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                "We've received your answer\nand we hope we see you next\ntime.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 30.h),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 353.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: Color(ConstColors.mainColor),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
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
    }();
  }

  void _showTripCompleteSheet(int rideId, String price) {
    AppLogger.log(
      'Opening Trip Complete sheet for ride ID: $rideId',
      tag: 'RIDE',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      barrierColor: Colors.black.withOpacity(0.2),
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
                      onPressed: () async {
                        final sheetContext = context;

                        final result = await context.pushNamed(
                          'tip',
                          extra: {'rideId': rideId},
                        );

                        if (result == true && sheetContext.mounted) {
                          CustomFlushbar.showSuccess(
                            context: sheetContext,
                            message: 'Tip sent successfully!',
                          );
                        }
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
                          Navigator.pop(context);
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
      'Opening rating sheet for ride ID: $currentRideId',
      tag: 'RATING',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      barrierColor: Colors.black.withOpacity(0.2),
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
                  GestureDetector(
                    onTap: selectedRating > 0 && !isSubmitting
                        ? () async {
                            AppLogger.log(
                              'Submit button pressed',
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
                                'No ride ID available!',
                                tag: 'RATING',
                              );
                              if (mounted) {
                                CustomFlushbar.showError(
                                  context: context,
                                  message: 'Error: No ride ID found',
                                );
                              }
                              return;
                            }
                            setRatingState(() {
                              isSubmitting = true;
                            });

                            try {
                              AppLogger.log(
                                'Calling rateRide API with ID: $currentRideId',
                                tag: 'RATING',
                              );

                              final result = await _rideService.rateRide(
                                rideId: currentRideId,
                                score: selectedRating,
                                comment: reviewController.text,
                              );

                              AppLogger.log(
                                'API Response: $result',
                                tag: 'RATING',
                              );

                              if (result['success'] == true) {
                                _dismissedRatingRides.add(currentRideId);
                                if (mounted) {
                                  Navigator.pop(context);
                                }
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
                                    CustomFlushbar.showSuccess(
                                      context: context,
                                      message: "Thank you for your rating!",
                                    );
                                  }
                                });
                              } else {
                                if (mounted) {
                                  setRatingState(() {
                                    isSubmitting = false;
                                  });
                                  CustomFlushbar.showError(
                                    context: context,
                                    message: 'Failed to submit rating',
                                  );
                                }
                              }
                            } catch (e) {
                              AppLogger.log(
                                'Error submitting rating: $e',
                                tag: 'RATING',
                              );
                              if (mounted) {
                                setRatingState(() {
                                  isSubmitting = false;
                                });
                                CustomFlushbar.showError(
                                  context: context,
                                  message: 'Error: $e',
                                );
                              }
                            }
                          }
                        : null,
                    child: Container(
                      width: 353.w,
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: selectedRating > 0
                            ? Color(ConstColors.mainColor)
                            : Color(ConstColors.fieldColor),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        reviewController.dispose();
      });

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

  void _showDeleteLocationDialog(String locationType, int locationId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DeleteLocationDialog(
          locationType: locationType,
          locationId: locationId,
          onDelete: () async {
            try {
              await _favouriteService.deleteFavouriteLocation(locationId);
              await _loadFavouriteLocations();
              CustomFlushbar.showSuccess(
                context: context,
                message: '$locationType deleted successfully',
              );
            } catch (e) {
              CustomFlushbar.showError(
                context: context,
                message: 'Failed to delete location',
              );
            }
          },
        );
      },
    );
  }

  List<LatLng> _generateCurvedPath(LatLng start, LatLng end) {
    List<LatLng> points = [];

    double midLat = (start.latitude + end.latitude) / 2;
    double midLng = (start.longitude + end.longitude) / 2;

    double offsetLat = (end.longitude - start.longitude) * 0.002;
    double offsetLng = (start.latitude - end.latitude) * 0.002;

    LatLng curvePoint = LatLng(midLat + offsetLat, midLng + offsetLng);

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

  Future<RideResponse> _requestRide({
    bool isScheduled = false,
    DateTime? scheduledDateTime,
  }) async {
    AppLogger.log('=== STARTING RIDE REQUEST ===');

    if (_currentEstimate == null || selectedVehicle == null) {
      AppLogger.log('Missing estimate or vehicle selection');
      throw Exception('No estimate or vehicle selected');
    }
    final selectedPriceData = _currentEstimate!.priceList[selectedVehicle!];
    final vehicleType = selectedPriceData['vehicle_type'];
    AppLogger.log('Selected Vehicle Type: $vehicleType');
    AppLogger.log('Selected Price Data: $selectedPriceData');
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
      'Pickup Coordinates: $pickupCoords (${pickupLatLng.latitude}, ${pickupLatLng.longitude})',
    );
    AppLogger.log(
      'Destination Coordinates: $destCoords (${destLatLng.latitude}, ${destLatLng.longitude})',
    );
    AppLogger.log('Original Payment Method: "$selectedPaymentMethod"');
    String convertedPaymentMethod;
    if (selectedPaymentMethod == 'Pay in car') {
      convertedPaymentMethod = 'in_car';
    } else if (selectedPaymentMethod == 'Pay with wallet') {
      convertedPaymentMethod = 'wallet';
    } else {
      convertedPaymentMethod = 'gateway';
    }
    AppLogger.log('Converted Payment Method: "$convertedPaymentMethod"');
    AppLogger.log('isScheduled parameter: $isScheduled');
    AppLogger.log('scheduledDateTime parameter: $scheduledDateTime');
    String? formattedScheduledAt;
    if (isScheduled && scheduledDateTime != null) {
      formattedScheduledAt = scheduledDateTime.toUtc().toIso8601String();
      AppLogger.log('Scheduled Ride: true');
      AppLogger.log('Scheduled At (formatted): $formattedScheduledAt');
      AppLogger.log('Original DateTime: $scheduledDateTime');
    } else {
      AppLogger.log(
        'NOT a scheduled ride - isScheduled: $isScheduled, scheduledDateTime: $scheduledDateTime',
      );
    }
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
          AppLogger.log('Reverse geocoded destination: $destAddress');
        }
      } catch (e) {
        AppLogger.log('Failed to reverse geocode destination: $e');
        destAddress = "Destination";
      }
    }
    if (destAddress.isEmpty) {
      destAddress = "Destination";
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
      scheduledAt: formattedScheduledAt,
      stopAddress: stopController.text.isNotEmpty ? stopController.text : null,
      note: noteController.text.isNotEmpty ? noteController.text : null,
    );
    AppLogger.log('=== RIDE REQUEST OBJECT CREATED ===');
    AppLogger.log('request.scheduled: ${request.scheduled}');
    AppLogger.log('request.scheduledAt: ${request.scheduledAt}');
    AppLogger.log('Final Ride Request Object:');
    AppLogger.log('  - Pickup: ${request.pickup}');
    AppLogger.log('  - Destination: ${request.dest}');
    AppLogger.log('  - Pickup Address: ${request.pickupAddress}');
    AppLogger.log('  - Destination Address: ${request.destAddress}');
    AppLogger.log('  - Service Type: ${request.serviceType}');
    AppLogger.log('  - Vehicle Type: ${request.vehicleType}');
    AppLogger.log('  - Payment Method: ${request.paymentMethod}');
    if (request.scheduled == true) {
      AppLogger.log('  - Scheduled: ${request.scheduled}');
      AppLogger.log('  - Scheduled At======: ${request.scheduledAt}');
    }
    AppLogger.log('\n===================================================');
    AppLogger.log('FINAL DATA BEING SENT TO BACKEND');
    AppLogger.log('===================================================');
    AppLogger.log('Method: POST');
    AppLogger.log('URL: ${UrlConstants.baseUrl}${UrlConstants.rideRequest}');
    AppLogger.log(
      'Headers: {Content-Type: application/json, Authorization: Bearer <TOKEN>}',
    );
    AppLogger.log('Body (JSON):');
    try {
      AppLogger.log(jsonEncode(request.toJson()));
    } catch (e) {
      AppLogger.log('Error encoding JSON: $e');
      AppLogger.log('Raw Map: ${request.toJson()}');
    }
    AppLogger.log('===================================================\n');
    return await _rideService.requestRide(request);
  }

  @override
  void dispose() {
    _driverLocationTimer?.cancel();
    _etaUpdateTimer?.cancel();
    _activeRideCheckTimer?.cancel();
    _nearbyDriversTimer?.cancel();
    _webSocketService.disconnect();
    _callService.dispose();
    fromController.removeListener(_onTextFieldChanged);
    toController.removeListener(_onTextFieldChanged);
    stopController.removeListener(_onTextFieldChanged);
    fromController.dispose();
    toController.dispose();
    stopController.dispose();
    _nearbyDriverTrackingTimer?.cancel();
    noteController.dispose();
    super.dispose();
  }
}
