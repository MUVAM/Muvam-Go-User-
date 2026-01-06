import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/services/places_service.dart';
import 'package:muvam/core/utils/app_logger.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/activities/data/models/ride_data.dart';
import 'package:muvam/features/activities/data/providers/rides_provider.dart';
import 'package:muvam/features/trips/presentation/widgets/display_field_widget.dart';
import 'package:muvam/features/trips/presentation/widgets/edit_field_widget.dart';
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
  late TextEditingController _whenController;

  final PlacesService _placesService = PlacesService();
  List<PlacePrediction> _predictions = [];
  bool _showPredictions = false;
  String? _sessionToken;
  LatLng? _selectedPickupLocation;
  LatLng? _selectedDestinationLocation;
  String _activeField = '';

  @override
  void initState() {
    super.initState();
    _pickupController = TextEditingController(text: widget.ride.pickupAddress);
    _destinationController = TextEditingController(
      text: widget.ride.destAddress,
    );
    _whenController = TextEditingController(
      text: _formatDateTime(widget.ride.scheduledAt ?? widget.ride.createdAt),
    );
    _sessionToken = DateTime.now().millisecondsSinceEpoch.toString();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _whenController.dispose();
    super.dispose();
  }

  String _formatDateTime(String dateTime) {
    try {
      final dt = DateTime.parse(dateTime);
      final months = [
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
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'pm' : 'am';
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $hour:$minute$period';
    } catch (e) {
      return dateTime;
    }
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

    setState(() {
      _activeField = fieldType;
    });

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
          if (_activeField == 'pickup') {
            _pickupController.text = prediction.description;
            _selectedPickupLocation = LatLng(
              placeDetails.latitude,
              placeDetails.longitude,
            );
          } else if (_activeField == 'destination') {
            _destinationController.text = prediction.description;
            _selectedDestinationLocation = LatLng(
              placeDetails.latitude,
              placeDetails.longitude,
            );
          }
          _showPredictions = false;
          _activeField = '';
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

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (pickedDate == null) return;

    if (!mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    final selectedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    final months = [
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
    final hour = pickedTime.hourOfPeriod == 0 ? 12 : pickedTime.hourOfPeriod;
    final minute = pickedTime.minute.toString().padLeft(2, '0');
    final period = pickedTime.period == DayPeriod.am ? 'am' : 'pm';

    _whenController.text =
        '${months[selectedDateTime.month - 1]} ${selectedDateTime.day}, ${selectedDateTime.year} at $hour:$minute$period';

    AppLogger.log('Date and time selected: ${_whenController.text}');
  }

  Future<void> _handleCancelPrebooking() async {
    Navigator.pop(context);
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
        message: 'Please select pickup location from suggestions',
      );
      return;
    }

    if (_selectedDestinationLocation == null) {
      CustomFlushbar.showError(
        context: context,
        message: 'Please select destination location from suggestions',
      );
      return;
    }

    final provider = context.read<RidesProvider>();

    final pickupCoordinate =
        'POINT(${_selectedPickupLocation!.longitude} ${_selectedPickupLocation!.latitude})';
    final destCoordinate =
        'POINT(${_selectedDestinationLocation!.longitude} ${_selectedDestinationLocation!.latitude})';

    final success = await provider.updateRide(
      rideId: widget.ride.id,
      pickup: pickupCoordinate,
      pickupAddress: _pickupController.text.trim(),
      dest: destCoordinate,
      destAddress: _destinationController.text.trim(),
      paymentMethod: widget.ride.paymentMethod,
      vehicleType: widget.ride.vehicleType,
      serviceType: widget.ride.serviceType,
    );

    if (!mounted) return;

    if (success) {
      CustomFlushbar.showSuccess(
        context: context,
        message: 'Prebooking updated successfully',
      );
      Navigator.pop(context, true);
    } else {
      CustomFlushbar.showError(
        context: context,
        message: provider.errorMessage ?? 'Failed to update prebooking',
      );
    }
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
                    child: _showPredictions && _predictions.isNotEmpty
                        ? ListView.separated(
                            padding: EdgeInsets.only(top: 10.h),
                            itemCount: _predictions.length,
                            separatorBuilder: (context, index) => Divider(
                              thickness: 1,
                              color: Colors.grey.shade300,
                            ),
                            itemBuilder: (context, index) {
                              final prediction = _predictions[index];
                              return ListTile(
                                leading: Icon(
                                  Icons.location_on,
                                  color: Color(ConstColors.mainColor),
                                ),
                                title: Text(
                                  prediction.mainText,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                subtitle: Text(
                                  prediction.secondaryText,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey,
                                  ),
                                ),
                                onTap: () => _selectPrediction(prediction),
                              );
                            },
                          )
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                EditFieldWidget(
                                  label: 'PICK UP',
                                  controller: _pickupController,
                                  onChanged: (value) =>
                                      _searchPlaces(value, 'pickup'),
                                ),
                                SizedBox(height: 15.h),
                                EditFieldWidget(
                                  label: 'DESTINATION',
                                  controller: _destinationController,
                                  onChanged: (value) =>
                                      _searchPlaces(value, 'destination'),
                                ),
                                SizedBox(height: 15.h),
                                GestureDetector(
                                  onTap: () => _selectDateTime(context),
                                  child: AbsorbPointer(
                                    child: EditFieldWidget(
                                      label: 'WHEN',
                                      controller: _whenController,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 15.h),
                                DisplayFieldWidget(
                                  label: 'PAYMENT METHOD',
                                  content: Row(
                                    children: [
                                      Container(
                                        width: 45.w,
                                        height: 35.h,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            4.r,
                                          ),
                                        ),
                                        child: SvgPicture.asset(
                                          'assets/svg/cash-iconic.svg',
                                          width: 24.w,
                                          height: 24.h,
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            provider.formatPrice(
                                              widget.ride.price,
                                            ),
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                          ),
                                          Text(
                                            widget.ride
                                                .getPaymentMethodDisplay(),
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w400,
                                              color: Color(0xFF666666),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 15.h),
                                DisplayFieldWidget(
                                  label: 'VEHICLE',
                                  content: Row(
                                    children: [
                                      Image.asset(
                                        'assets/images/car.png',
                                        width: 45.w,
                                        height: 35.h,
                                        fit: BoxFit.cover,
                                      ),
                                      SizedBox(width: 12.w),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Any Vehicle',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                          ),
                                          Text(
                                            widget.ride.getVehicleTypeDisplay(),
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w400,
                                              color: Color(0xFF666666),
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
                  ),
                  SizedBox(height: 20.h),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: provider.isUpdating
                            ? null
                            : _handleCancelPrebooking,
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
                        onTap: provider.isUpdating
                            ? null
                            : _handleSavePrebooking,
                        child: Container(
                          width: 353.w,
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
}
