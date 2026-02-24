import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/services/payment_service.dart';
import 'package:muvam/core/services/places_service.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/activities/data/models/ride_data.dart';
import 'package:muvam/features/activities/data/providers/rides_provider.dart';
import 'package:muvam/features/home/presentation/screens/map_selection_screen.dart';
import 'package:muvam/shared/presentation/screens/payment_webview_screen.dart';
import 'package:muvam/features/promo/presentation/screens/promo_code_screen.dart';
import 'package:provider/provider.dart';

class EditPrebookingScreen extends StatefulWidget {
  final RideData ride;

  const EditPrebookingScreen({super.key, required this.ride});

  @override
  State<EditPrebookingScreen> createState() => _EditPrebookingScreenState();
}

class _EditPrebookingScreenState extends State<EditPrebookingScreen> {
  late TextEditingController _pickupController;
  late TextEditingController _destinationController;

  final PlacesService _placesService = PlacesService();
  final PaymentService _paymentService = PaymentService();
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
    // 'pay4me',
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

    // Parse scheduled date
    try {
      final dt = DateTime.parse(
        widget.ride.scheduledAt ?? widget.ride.createdAt,
      ).toLocal();
      _selectedDate = dt;
      _selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    } catch (e) {
      _selectedDate = DateTime.now().add(Duration(days: 1));
      _selectedTime = TimeOfDay.now();
    }

    // Map payment method from ride data
    final pm = widget.ride.paymentMethod.toLowerCase();
    if (pm.contains('wallet')) {
      _selectedPaymentMethod = 'Pay with wallet';
    } else if (pm.contains('card')) {
      _selectedPaymentMethod = 'Pay with card';
    } else if (pm.contains('pay4me')) {
      _selectedPaymentMethod = 'pay4me';
    } else {
      _selectedPaymentMethod = 'Pay in car';
    }

    // Map vehicle type
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
    } catch (e) {
      CustomFlushbar.showError(
        context: context,
        message: 'Could not get location details',
      );
    }
  }

  void _showPaymentMethodSheet() {
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PromoCodeScreen(),
                ),
              );
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
                    ..._paymentMethods
                        .map(
                          (method) => Column(
                            children: [
                              _buildPaymentOption(method),
                              Divider(
                                thickness: 1,
                                color: Colors.grey.shade300,
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String method) {
    final isSelected = _selectedPaymentMethod == method;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPaymentMethod = method);
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
              child: Text(
                method,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Colors.green, size: 20.sp),
          ],
        ),
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
            Text(
              'Select Vehicle',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 20.h),
            ..._vehicleTypes.asMap().entries.map((entry) {
              final index = entry.key;
              final type = entry.value;
              final isSelected = _selectedVehicleIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedVehicleIndex = index);
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  height: 60.h,
                  margin: EdgeInsets.only(bottom: 12.h),
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Color(ConstColors.mainColor)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? Color(ConstColors.mainColor)
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/car.png',
                        width: 55.w,
                        height: 26.h,
                      ),
                      SizedBox(width: 15.w),
                      Expanded(
                        child: Text(
                          type,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
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

    final pickupCoords = _selectedPickupLocation;
    final destCoords = _selectedDestinationLocation;

    if (pickupCoords == null) {
      CustomFlushbar.showError(
        context: context,
        message: 'Please select pickup from suggestions',
      );
      return;
    }
    if (destCoords == null) {
      CustomFlushbar.showError(
        context: context,
        message: 'Please select destination from suggestions',
      );
      return;
    }

    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

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
      // scheduledAt: scheduledDateTime.toUtc().toIso8601String(),
    );

    if (!mounted) return;

    if (!success) {
      CustomFlushbar.showError(
        context: context,
        message: provider.errorMessage ?? 'Failed to update prebooking',
      );
      return;
    }

    // Handle payment based on selected method
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
          final paymentResult = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentWebViewScreen(
                authorizationUrl: paymentData['authorization_url'],
                reference: paymentData['reference'],
                onPaymentSuccess: () {},
              ),
            ),
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

        // Wallet
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

    // Pay in car / pay4me
    CustomFlushbar.showSuccess(
      context: context,
      message: 'Prebooking saved successfully!',
    );
    Navigator.pop(context, true);
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        color: Colors.black,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildFieldContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                      Text(
                        'Edit Prebooking',
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
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // PICK UP
                          _buildLabel('PICK UP'),
                          SizedBox(height: 8.h),
                          Container(
                            height: 50.h,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
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
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            MapSelectionScreen(
                                              isFromField: true,
                                              initialLocation:
                                                  _selectedPickupLocation,
                                            ),
                                      ),
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
                                      color: Color(ConstColors.mainColor),
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
                            _buildPredictionsList(),
                          SizedBox(height: 15.h),

                          // DESTINATION
                          _buildLabel('DESTINATION'),
                          SizedBox(height: 8.h),
                          Container(
                            height: 50.h,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
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
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            MapSelectionScreen(
                                              isFromField: false,
                                              initialLocation:
                                                  _selectedDestinationLocation,
                                            ),
                                      ),
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
                                      color: Color(ConstColors.mainColor),
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
                            _buildPredictionsList(),
                          SizedBox(height: 15.h),

                          // WHEN
                          _buildLabel('WHEN'),
                          SizedBox(height: 8.h),
                          GestureDetector(
                            onTap: () async {
                              final DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  Duration(days: 365),
                                ),
                                builder: (context, child) => Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: Color(ConstColors.mainColor),
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
                                          colorScheme: ColorScheme.light(
                                            primary: Color(
                                              ConstColors.mainColor,
                                            ),
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
                            child: _buildFieldContainer(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_getMonth(_selectedDate.month)} ${_selectedDate.day}, ${_selectedDate.year} at ${_selectedTime.format(context)}',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
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

                          // PAYMENT METHOD
                          _buildLabel('PAYMENT METHOD'),
                          SizedBox(height: 8.h),
                          GestureDetector(
                            onTap: _showPaymentMethodSheet,
                            child: _buildFieldContainer(
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
                                    child: Text(
                                      _selectedPaymentMethod,
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
                                    size: 14.sp,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 15.h),

                          // VEHICLE
                          _buildLabel('VEHICLE'),
                          SizedBox(height: 8.h),
                          GestureDetector(
                            onTap: _showVehicleSheet,
                            child: _buildFieldContainer(
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
                                        Text(
                                          _vehicleTypes[_selectedVehicleIndex],
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Text(
                                          '4 Passengers',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.grey,
                                          ),
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
                            : () => Navigator.pop(context),
                        child: Container(
                          width: double.infinity,
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
                        onTap: provider.isUpdating
                            ? null
                            : _handleSavePrebooking,
                        child: Container(
                          width: double.infinity,
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: provider.isUpdating
                                ? Colors.grey
                                : Color(ConstColors.mainColor),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Center(
                            child: provider.isUpdating
                                ? SizedBox(
                                    width: 20.w,
                                    height: 20.h,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildPredictionsList() {
    return Container(
      constraints: BoxConstraints(maxHeight: 200.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _predictions.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey.shade200),
        itemBuilder: (context, index) {
          final prediction = _predictions[index];
          return ListTile(
            dense: true,
            leading: Icon(Icons.location_on, size: 20.sp, color: Colors.grey),
            title: Text(
              prediction.mainText,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
            subtitle: prediction.secondaryText.isNotEmpty
                ? Text(
                    prediction.secondaryText,
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                  )
                : null,
            onTap: () => _selectPrediction(prediction),
          );
        },
      ),
    );
  }
}
