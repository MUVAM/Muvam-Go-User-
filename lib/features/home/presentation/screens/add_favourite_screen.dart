import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/utils/custom_flushbar.dart';
import 'package:muvam/features/trips/data/models/location_models.dart';
import 'package:muvam/shared/providers/location_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/favourite_text_field.dart';

class AddFavouriteScreen extends StatefulWidget {
  const AddFavouriteScreen({super.key});

  @override
  State<AddFavouriteScreen> createState() => _AddFavouriteScreenState();
}

class _AddFavouriteScreenState extends State<AddFavouriteScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  bool _isFormValid() {
    return nameController.text.isNotEmpty &&
        addressController.text.isNotEmpty &&
        locationController.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Image.asset(
                        ConstImages.back,
                        width: 24.w,
                        height: 24.h,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Add Favourite Location',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 24.w),
                  ],
                ),
                SizedBox(height: 40.h),
                FavouriteTextField(
                  label: 'Location Name',
                  controller: nameController,
                  onChanged: (value) => setState(() {}),
                ),
                SizedBox(height: 20.h),
                FavouriteTextField(
                  label: 'Address',
                  controller: addressController,
                  onChanged: (value) => setState(() {}),
                ),
                SizedBox(height: 20.h),
                FavouriteTextField(
                  label: 'Location Coordinates',
                  controller: locationController,
                  onChanged: (value) => setState(() {}),
                ),
                SizedBox(height: 40.h),
                Consumer<LocationProvider>(
                  builder: (context, locationProvider, child) {
                    return GestureDetector(
                      onTap: _isFormValid() && !locationProvider.isLoading
                          ? () async {
                              final request = AddFavouriteRequest(
                                name: nameController.text,
                                destAddress: addressController.text,
                                destLocation: locationController.text,
                              );

                              final success = await locationProvider
                                  .addFavouriteLocation(request);

                              if (success) {
                                Navigator.pop(context);
                                CustomFlushbar.showSuccess(
                                  context: context,
                                  message:
                                      'Favourite location added successfully',
                                );
                              } else {
                                CustomFlushbar.showError(
                                  context: context,
                                  message: 'Failed to add favourite location',
                                );
                              }
                            }
                          : null,
                      child: Container(
                        width: 353.w,
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: _isFormValid() && !locationProvider.isLoading
                              ? Color(ConstColors.mainColor)
                              : Color(ConstColors.fieldColor),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: locationProvider.isLoading
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.h,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Add Favourite',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
