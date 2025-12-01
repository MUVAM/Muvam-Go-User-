import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../constants/images.dart';
import '../constants/text_styles.dart';
import '../providers/location_provider.dart';
import '../models/location_models.dart';

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
                _buildTextField('Location Name', nameController),
                SizedBox(height: 20.h),
                _buildTextField('Address', addressController),
                SizedBox(height: 20.h),
                _buildTextField('Location Coordinates', locationController),
                SizedBox(height: 40.h),
                Consumer<LocationProvider>(
                  builder: (context, locationProvider, child) {
                    return GestureDetector(
                      onTap: _isFormValid() && !locationProvider.isLoading ? () async {
                        final request = AddFavouriteRequest(
                          name: nameController.text,
                          destAddress: addressController.text,
                          destLocation: locationController.text,
                        );
                        
                        final success = await locationProvider.addFavouriteLocation(request);
                        
                        if (success) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Favourite location added successfully')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(locationProvider.errorMessage ?? 'Failed to add favourite location'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } : null,
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

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ConstTextStyles.fieldLabel,
        ),
        SizedBox(height: 8.h),
        Container(
          width: 353.w,
          height: 50.h,
          decoration: BoxDecoration(
            color: Color(ConstColors.formFieldColor),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: TextField(
            controller: controller,
            style: ConstTextStyles.inputText,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),
      ],
    );
  }
}