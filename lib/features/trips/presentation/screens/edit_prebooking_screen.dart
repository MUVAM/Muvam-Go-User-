import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/app_routes.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/core/services/payment_service.dart';
import 'package:muvam/core/services/places_service.dart';
import 'package:muvam/core/services/ride_service.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/activities/data/models/ride_data.dart';
import 'package:muvam/features/activities/data/providers/rides_provider.dart';
import 'package:muvam/features/home/presentation/screens/map_selection_screen.dart';
import 'package:muvam/features/trips/presentation/widgets/cancel_reason_sheet.dart';
import 'package:muvam/features/trips/presentation/widgets/cancel_ride_dialog.dart';
import 'package:muvam/features/trips/presentation/widgets/payment_method_sheet.dart';
import 'package:muvam/features/trips/presentation/widgets/predictions_list.dart';
import 'package:muvam/features/trips/presentation/widgets/vehicle_sheet.dart';
import 'package:muvam/layouts/presentation/screens/payment_webview_screen.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';
import 'package:provider/provider.dart';

class EditPrebookingScreen extends StatefulWidget {
  final RideData ride;
  final String? initialScheduledAt;

  const EditPrebookingScreen({
    super.key,
    required this.ride,
    this.initialScheduledAt,
  });

  @override
  State<EditPrebookingScreen> createState() => _EditPrebookingScreenState();
}

class _EditPrebookingScreenState extends State<EditPrebookingScreen> {
  late TextEditingController _pickupController;
  late TextEditingController _destinationController;

  final PlacesService _placesService = PlacesService();
  final PaymentService _paymentService = PaymentService();
  final RideService _rideService = RideService();

  int? _selectedCancelReason;
  List<PlacePrediction> _predictions = [];
  bool _showPredictions = false;
  String? _sessionToken;
  LatLng? _selectedPickupLocation;
  LatLng? _selectedDestinationLocation;
  String _activeField = '';
  bool _isFromFieldFocused = false;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _selectedPaymentMethod;
  late int _selectedVehicleIndex;

  final List<String> _vehicleTypes = ['Regular', 'Fancy', 'VIP'];
  final List<String> _paymentMethods = [
    'Pay with wallet',
    'Pay with card',
    'Pay in car',
  ];

  @override
  void initState() {
    super.initState();
    _pickupController = TextEditingController(text: widget.ride.pickupAddress);
    _destinationController = TextEditingController(
      text: widget.ride.destAddress,
    );
    _sessionToken = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      final dt = DateTime.parse(
        widget.initialScheduledAt ??
            widget.ride.scheduledAt ??
            widget.ride.createdAt,
      ).toLocal();
      _selectedDate = dt;
      _selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    } catch (_) {
      _selectedDate = DateTime.now().add(const Duration(days: 1));
      _selectedTime = TimeOfDay.now();
    }

    final pm = widget.ride.paymentMethod.toLowerCase();
    if (pm.contains('wallet')) {
      _selectedPaymentMethod = 'Pay with wallet';
    } else if (pm.contains('card')) {
      _selectedPaymentMethod = 'Pay with card';
    } else {
      _selectedPaymentMethod = 'Pay in car';
    }

    final vt = widget.ride.vehicleType.toLowerCase();
    if (vt.contains('fancy')) {
      _selectedVehicleIndex = 1;
    } else if (vt.contains('vip')) {
      _selectedVehicleIndex = 2;
    } else {
      _selectedVehicleIndex = 0;
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    super.dispose();
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
        return 'assets/images/payincar_icon.png';
    }
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

  Future<void> _searchPlaces(String query, String fieldType) async {
    if (query.isEmpty) {
      setState(() {
        _predictions = [];
        _showPredictions = false;
        _activeField = '';
      });
      return;
    }
    setState(() => _activeField = fieldType);
    try {
      final predictions = await _placesService.getPlacePredictions(
        query,
        sessionToken: _sessionToken,
      );
      setState(() {
        _predictions = predictions;
        _showPredictions = predictions.isNotEmpty;
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
          if (_activeField == 'pickup') {
            _pickupController.text = prediction.description;
            _selectedPickupLocation = LatLng(
              placeDetails.latitude,
              placeDetails.longitude,
            );
          } else {
            _destinationController.text = prediction.description;
            _selectedDestinationLocation = LatLng(
              placeDetails.latitude,
              placeDetails.longitude,
            );
          }
          _showPredictions = false;
          _activeField = '';
          _sessionToken = DateTime.now().millisecondsSinceEpoch.toString();
        });
      }
    } catch (_) {
      CustomFlushbar.showError(
        context: context,
        message: 'Could not get location details',
      );
    }
  }

  void _showPaymentMethodSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.kMainColor,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (context) => PaymentMethodSheet(
        paymentMethods: _paymentMethods,
        selectedPaymentMethod: _selectedPaymentMethod,
        onMethodSelected: (method) {
          setState(() => _selectedPaymentMethod = method);
        },
        getPaymentMethodIcon: _getPaymentMethodIcon,
      ),
    );
  }

  void _showVehicleSheet() {
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => VehicleSheet(
        vehicleTypes: _vehicleTypes,
        selectedVehicleIndex: _selectedVehicleIndex,
        onVehicleSelected: (index) {
          setState(() => _selectedVehicleIndex = index);
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
      builder: (context) => CancelReasonSheet(
        selectedCancelReason: _selectedCancelReason,
        onReasonSelected: (index) {
          setState(() => _selectedCancelReason = index);
        },
        onSubmit: () {
          if (_selectedCancelReason == 3) {
            context.pop();
            _showCancelRideDialog();
          } else {
            context.pop();
            _showFeedbackSuccessSheet();
          }
        },
      ),
    );
  }

  void _showCancelRideDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => CancelRideDialog(
        onConfirm: (reason) async {
          await _executeCancelRide(reason);
        },
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
    final reason = _selectedCancelReason != null
        ? reasons[_selectedCancelReason!]
        : 'Cancelled by passenger';
    () async {
      await _executeCancelRide(reason);
    }();
  }

  Future<void> _executeCancelRide(String reason) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          Center(child: CircularProgressIndicator(color: AppColors.kMainColor)),
    );

    try {
      final result = await _rideService.cancelRide(
        rideId: widget.ride.id,
        reason: reason,
      );

      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (result['success'] == true) {
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
              color: AppColors.kWhiteColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100.sp,
                  height: 100.sp,
                  decoration: const BoxDecoration(
                    color: Color(0xff34B869),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: AppColors.kWhiteColor,
                    size: 40.sp,
                  ),
                ),
                SizedBox(height: 10.h),
                MuvamTexts.headlineMedium28(
                  context,
                  text: 'Feedback Sent',
                  isTextWidget: true,
                  fontWeight: FontWeight.bold,
                ),
                MuvamTexts.titleMedium18(
                  context,
                  text:
                      "We've received your answer\nand we hope we see you next\ntime.",
                  isTextWidget: true,
                  center: true,
                ),
                SizedBox(height: 30.h),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: double.infinity,
                    height: 47.h,
                    decoration: BoxDecoration(
                      color: AppColors.kMainColor,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: MuvamTexts.button16(
                        context,
                        text: 'GO HOME',
                        isTextWidget: true,
                        color: AppColors.kWhiteColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        if (mounted) {
          CustomFlushbar.showError(
            context: context,
            message: result['message'] ?? 'Failed to cancel ride',
          );
        }
      }
    } catch (e) {
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (mounted) {
        CustomFlushbar.showError(context: context, message: 'Error: $e');
      }
    }
  }

  Future<void> _handleSavePrebooking() async {
    if (_pickupController.text.trim().isEmpty) {
      CustomFlushbar.showError(
        context: context,
        message: 'Please enter pickup address',
      );
      return;
    }
    if (_destinationController.text.trim().isEmpty) {
      CustomFlushbar.showError(
        context: context,
        message: 'Please enter destination address',
      );
      return;
    }
    if (_selectedPickupLocation == null) {
      CustomFlushbar.showError(
        context: context,
        message: 'Please select pickup from suggestions',
      );
      return;
    }
    if (_selectedDestinationLocation == null) {
      CustomFlushbar.showError(
        context: context,
        message: 'Please select destination from suggestions',
      );
      return;
    }

    final pickupCoords = _selectedPickupLocation!;
    final destCoords = _selectedDestinationLocation!;

    final provider = context.read<RidesProvider>();

    final success = await provider.updateRide(
      rideId: widget.ride.id,
      pickup: 'POINT(${pickupCoords.longitude} ${pickupCoords.latitude})',
      pickupAddress: _pickupController.text.trim(),
      dest: 'POINT(${destCoords.longitude} ${destCoords.latitude})',
      destAddress: _destinationController.text.trim(),
      paymentMethod: _selectedPaymentMethod,
      vehicleType: _vehicleTypes[_selectedVehicleIndex],
      serviceType: widget.ride.serviceType,
    );

    if (!mounted) return;

    if (!success) {
      CustomFlushbar.showError(
        context: context,
        message: provider.errorMessage ?? 'Failed to update prebooking',
      );
      return;
    }

    if (_selectedPaymentMethod == 'Pay with card' ||
        _selectedPaymentMethod == 'Pay with wallet') {
      try {
        final paymentData = await _paymentService.initializePayment(
          rideId: widget.ride.id,
          amount: widget.ride.price,
        );

        if (!mounted) return;

        if (_selectedPaymentMethod == 'Pay with card' &&
            paymentData['authorization_url'] != null) {
          final paymentResult = await context.push(
            AppRoutes.paymentWebView.urlPath,
            extra: {
              'authorizationUrl': paymentData['authorization_url'],
              'reference': paymentData['reference'],
              'onPaymentSuccess': () {},
            },
          );
          if (!mounted) return;
          if (paymentResult == true) {
            CustomFlushbar.showSuccess(
              context: context,
              message: 'Prebooking saved and payment successful!',
            );
            Navigator.pop(context, true);
          } else {
            CustomFlushbar.showError(
              context: context,
              message: 'Payment was not completed.',
            );
          }
          return;
        }

        if (paymentData['success'] == true || paymentData['status'] == true) {
          CustomFlushbar.showSuccess(
            context: context,
            message: 'Prebooking saved and wallet charged successfully!',
          );
          Navigator.pop(context, true);
        } else {
          CustomFlushbar.showError(
            context: context,
            message: paymentData['message'] ?? 'Wallet payment failed.',
          );
        }
      } catch (e) {
        CustomFlushbar.showError(
          context: context,
          message: 'Payment error: $e',
        );
      }
      return;
    }

    CustomFlushbar.showSuccess(
      context: context,
      message: 'Prebooking saved successfully!',
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: SafeArea(
        child: Consumer<RidesProvider>(
          builder: (context, provider, child) {
            return Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MuvamTexts.headlineSmall24(
                        context,
                        text: 'Edit Prebooking',
                        isTextWidget: true,
                        fontWeight: FontWeight.w600,
                      ),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Icon(
                          Icons.close,
                          size: 24.sp,
                          color: AppColors.kBlackColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30.h),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MuvamTexts.bodySmall12(
                            context,
                            text: 'PICK UP',
                            isTextWidget: true,
                            fontWeight: FontWeight.w500,
                            color: AppColors.kBlackColor,
                          ),
                          SizedBox(height: 8.h),
                          Container(
                            height: 50.h,
                            decoration: BoxDecoration(
                              color: AppColors.kFormFieldColor,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: TextField(
                              controller: _pickupController,
                              onChanged: (value) {
                                setState(() => _isFromFieldFocused = true);
                                _searchPlaces(value, 'pickup');
                              },
                              decoration: InputDecoration(
                                hintText: 'Enter pickup location',
                                hintStyle: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey[400],
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.grey,
                                  size: 20.sp,
                                ),
                                suffixIcon: GestureDetector(
                                  onTap: () async {
                                    final result = await context.push(
                                      AppRoutes.mapSelection.urlPath,
                                      extra: {
                                        'isFromField': true,
                                        'initialLocation':
                                            _selectedPickupLocation,
                                      },
                                    );
                                    if (result != null &&
                                        result is Map<String, dynamic>) {
                                      setState(() {
                                        _selectedPickupLocation =
                                            result['location'] as LatLng;
                                        _pickupController.text =
                                            result['address'] as String;
                                      });
                                    }
                                  },
                                  child: Container(
                                    margin: EdgeInsets.only(right: 16.w),
                                    child: Icon(
                                      Icons.map,
                                      size: 20.sp,
                                      color: AppColors.kMainColor,
                                    ),
                                  ),
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 15.h,
                                ),
                              ),
                            ),
                          ),
                          if (_showPredictions &&
                              _predictions.isNotEmpty &&
                              _activeField == 'pickup')
                            PredictionsList(
                              predictions: _predictions,
                              onPredictionSelected: _selectPrediction,
                            ),
                          SizedBox(height: 15.h),
                          MuvamTexts.bodySmall12(
                            context,
                            text: 'DESTINATION',
                            isTextWidget: true,
                            fontWeight: FontWeight.w500,
                            color: AppColors.kBlackColor,
                          ),
                          SizedBox(height: 8.h),
                          Container(
                            height: 50.h,
                            decoration: BoxDecoration(
                              color: AppColors.kFormFieldColor,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: TextField(
                              controller: _destinationController,
                              onChanged: (value) {
                                setState(() => _isFromFieldFocused = false);
                                _searchPlaces(value, 'destination');
                              },
                              decoration: InputDecoration(
                                hintText: 'Enter destination',
                                hintStyle: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey[400],
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.grey,
                                  size: 20.sp,
                                ),
                                suffixIcon: GestureDetector(
                                  onTap: () async {
                                    final result = await context.push(
                                      AppRoutes.mapSelection.urlPath,
                                      extra: {
                                        'isFromField': false,
                                        'initialLocation':
                                            _selectedDestinationLocation,
                                      },
                                    );
                                    if (result != null &&
                                        result is Map<String, dynamic>) {
                                      setState(() {
                                        _selectedDestinationLocation =
                                            result['location'] as LatLng;
                                        _destinationController.text =
                                            result['address'] as String;
                                      });
                                    }
                                  },
                                  child: Container(
                                    margin: EdgeInsets.only(right: 16.w),
                                    child: Icon(
                                      Icons.map,
                                      size: 20.sp,
                                      color: AppColors.kMainColor,
                                    ),
                                  ),
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 15.h,
                                ),
                              ),
                            ),
                          ),
                          if (_showPredictions &&
                              _predictions.isNotEmpty &&
                              _activeField == 'destination')
                            PredictionsList(
                              predictions: _predictions,
                              onPredictionSelected: _selectPrediction,
                            ),
                          SizedBox(height: 15.h),

                          MuvamTexts.bodySmall12(
                            context,
                            text: 'WHEN',
                            isTextWidget: true,
                            fontWeight: FontWeight.w500,
                            color: AppColors.kBlackColor,
                          ),
                          SizedBox(height: 8.h),
                          GestureDetector(
                            onTap: () async {
                              final DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                                builder: (context, child) => Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: AppColors.kMainColor,
                                    ),
                                  ),
                                  child: child!,
                                ),
                              );
                              if (pickedDate != null) {
                                final TimeOfDay? pickedTime =
                                    await showTimePicker(
                                      context: context,
                                      initialTime: _selectedTime,
                                      builder: (context, child) => Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: const ColorScheme.light(
                                            primary: AppColors.kMainColor,
                                          ),
                                        ),
                                        child: child!,
                                      ),
                                    );
                                if (pickedTime != null) {
                                  setState(() {
                                    _selectedDate = pickedDate;
                                    _selectedTime = pickedTime;
                                  });
                                }
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: 15.w,
                                vertical: 12.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.kFormFieldColor,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  MuvamTexts.bodyMedium14(
                                    context,
                                    text:
                                        '${_getMonth(_selectedDate.month)} ${_selectedDate.day}, ${_selectedDate.year} at ${_selectedTime.format(context)}',
                                    isTextWidget: true,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14.sp,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 15.h),

                          MuvamTexts.bodySmall12(
                            context,
                            text: 'PAYMENT METHOD',
                            isTextWidget: true,
                            fontWeight: FontWeight.w500,
                            color: AppColors.kBlackColor,
                          ),
                          SizedBox(height: 8.h),
                          GestureDetector(
                            onTap: _showPaymentMethodSheet,
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: 15.w,
                                vertical: 12.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.kFormFieldColor,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    _getPaymentMethodIcon(
                                      _selectedPaymentMethod,
                                    ),
                                    width: 60.w,
                                    height: 28.h,
                                    fit: BoxFit.contain,
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: MuvamTexts.bodyMedium14(
                                      context,
                                      text: _selectedPaymentMethod,
                                      isTextWidget: true,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14.sp,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 15.h),

                          MuvamTexts.bodySmall12(
                            context,
                            text: 'VEHICLE',
                            isTextWidget: true,
                            fontWeight: FontWeight.w500,
                            color: AppColors.kBlackColor,
                          ),
                          SizedBox(height: 8.h),
                          GestureDetector(
                            onTap: _showVehicleSheet,
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: 15.w,
                                vertical: 12.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.kFormFieldColor,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    'assets/images/car.png',
                                    width: 60.w,
                                    height: 28.h,
                                    fit: BoxFit.contain,
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        MuvamTexts.bodyMedium14(
                                          context,
                                          text:
                                              _vehicleTypes[_selectedVehicleIndex],
                                          isTextWidget: true,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        MuvamTexts.bodySmall12(
                                          context,
                                          text: '4 Passengers',
                                          isTextWidget: true,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14.sp,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ),

                  Column(
                    children: [
                      GestureDetector(
                        onTap: provider.isUpdating
                            ? null
                            : _showTripCanceledSheet,
                        child: Container(
                          width: double.infinity,
                          height: 47.h,
                          decoration: BoxDecoration(
                            color: AppColors.kWhiteColor,
                            border: Border.all(color: AppColors.kError),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Center(
                            child: MuvamTexts.button16(
                              context,
                              text: 'Cancel prebooking',
                              isTextWidget: true,
                              color: AppColors.kError,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 15.h),
                      GestureDetector(
                        onTap: provider.isUpdating
                            ? null
                            : _handleSavePrebooking,
                        child: Container(
                          width: double.infinity,
                          height: 47.h,
                          decoration: BoxDecoration(
                            color: provider.isUpdating
                                ? Colors.grey
                                : AppColors.kMainColor,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Center(
                            child: provider.isUpdating
                                ? SizedBox(
                                    width: 20.w,
                                    height: 20.h,
                                    child: const CircularProgressIndicator(
                                      color: AppColors.kWhiteColor,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : MuvamTexts.button16(
                                    context,
                                    text: 'Save prebooking',
                                    isTextWidget: true,
                                    color: AppColors.kWhiteColor,
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
        ),
      ),
    );
  }
}
