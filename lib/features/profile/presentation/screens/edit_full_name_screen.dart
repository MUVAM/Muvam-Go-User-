import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';
import '../../../auth/presentation/widgets/editable_name_field.dart';

class EditFullNameScreen extends StatefulWidget {
  const EditFullNameScreen({super.key});

  @override
  _EditFullNameScreenState createState() => _EditFullNameScreenState();
}

class _EditFullNameScreenState extends State<EditFullNameScreen> {
  final TextEditingController firstNameController = TextEditingController(
    text: 'John',
  );
  final TextEditingController lastNameController = TextEditingController(
    text: 'Doe',
  );
  final TextEditingController emailController = TextEditingController(text: '');
  bool isFirstNameEditable = false;
  bool isLastNameEditable = false;
  bool isEmailEditable = false;

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => GoRouter.of(context).pop(),
                    child: Image.asset(
                      ConstImages.back,
                      width: 33.w,
                      height: 33.h,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 60.w,
                      height: 30.h,
                      decoration: BoxDecoration(
                        color: AppColors.kMainColor,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Center(
                        child: MuvamTexts.bodySmall12(
                          context,
                          text: 'Save',
                          isTextWidget: true,
                          color: AppColors.kWhiteColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              MuvamTexts.titleMedium18(
                context,
                text: 'Full name',
                isTextWidget: true,
                fontWeight: FontWeight.w600,
              ),
              SizedBox(height: 30.h),
              EditableNameField(
                label: 'First name',
                controller: firstNameController,
                isEditable: isFirstNameEditable,
                onEditTap: () =>
                    setState(() => isFirstNameEditable = !isFirstNameEditable),
              ),
              SizedBox(height: 20.h),
              EditableNameField(
                label: 'Last name',
                controller: lastNameController,
                isEditable: isLastNameEditable,
                onEditTap: () =>
                    setState(() => isLastNameEditable = !isLastNameEditable),
              ),
              SizedBox(height: 20.h),
              EditableNameField(
                label: 'Email address',
                controller: emailController,
                isEditable: isEmailEditable,
                onEditTap: () =>
                    setState(() => isEmailEditable = !isEmailEditable),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
