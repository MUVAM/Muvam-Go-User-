import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/features/support/widgets/contact_item_widget.dart';
import 'package:muvam/features/support/widgets/feature_item_widget.dart';
import 'package:muvam/features/support/widgets/social_button_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset(
                      ConstImages.back,
                      width: 30.w,
                      height: 30.h,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'About Us',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 30.w),
                ],
              ),
            ),
            SizedBox(height: 30.h),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 120.w,
                        height: 120.h,
                        decoration: BoxDecoration(
                          color: Color(ConstColors.mainColor).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.local_taxi,
                            size: 60.sp,
                            color: Color(ConstColors.mainColor),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Center(
                      child: Text(
                        'Muvam',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w700,
                          color: Color(ConstColors.mainColor),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Center(
                      child: Text(
                        'Your Ride, Your Way',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    SizedBox(height: 30.h),
                    _buildSectionTitle('Our Story'),
                    SizedBox(height: 12.h),
                    _buildParagraph(
                      'Muvam is a leading ride-hailing service committed to providing safe, reliable, and affordable transportation solutions. Founded with a vision to revolutionize urban mobility, we connect riders with professional drivers at the tap of a button.',
                    ),
                    SizedBox(height: 20.h),
                    _buildSectionTitle('Our Mission'),
                    SizedBox(height: 12.h),
                    _buildParagraph(
                      'To make transportation accessible, convenient, and sustainable for everyone. We strive to create a seamless experience that empowers both riders and drivers while contributing to smarter, cleaner cities.',
                    ),
                    SizedBox(height: 20.h),
                    _buildSectionTitle('Why Choose Muvam?'),
                    SizedBox(height: 12.h),
                    FeatureItemWidget(
                      icon: Icons.verified_user,
                      title: 'Safety First',
                      description:
                          'All drivers are thoroughly vetted and rides are insured',
                    ),
                    SizedBox(height: 12.h),
                    FeatureItemWidget(
                      icon: Icons.attach_money,
                      title: 'Transparent Pricing',
                      description:
                          'No hidden fees, see your fare before you ride',
                    ),
                    SizedBox(height: 12.h),
                    FeatureItemWidget(
                      icon: Icons.support_agent,
                      title: '24/7 Support',
                      description: 'Our team is always here to help you',
                    ),
                    SizedBox(height: 12.h),
                    FeatureItemWidget(
                      icon: Icons.eco,
                      title: 'Eco-Friendly',
                      description: 'Committed to reducing carbon emissions',
                    ),
                    SizedBox(height: 30.h),
                    _buildSectionTitle('Get in Touch'),
                    SizedBox(height: 12.h),
                    ContactItemWidget(
                      icon: Icons.email,
                      label: 'Email',
                      value: 'support@muvam.com',
                      onTap: () => _launchEmail('support@muvam.com'),
                    ),
                    SizedBox(height: 12.h),
                    ContactItemWidget(
                      icon: Icons.phone,
                      label: 'Phone',
                      value: '+1 (555) 123-4567',
                      onTap: () => _launchPhone('+15551234567'),
                    ),
                    SizedBox(height: 12.h),
                    ContactItemWidget(
                      icon: Icons.language,
                      label: 'Website',
                      value: 'www.muvam.com',
                      onTap: () => _launchWebsite('https://www.muvam.com'),
                    ),
                    SizedBox(height: 30.h),
                    _buildSectionTitle('Follow Us'),
                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SocialButtonWidget(icon: Icons.facebook, onTap: () {}),
                        SizedBox(width: 16.w),
                        SocialButtonWidget(
                          icon: Icons.camera_alt,
                          onTap: () {},
                        ),
                        SizedBox(width: 16.w),
                        SocialButtonWidget(
                          icon: Icons.alternate_email,
                          onTap: () {},
                        ),
                      ],
                    ),
                    SizedBox(height: 30.h),
                    Center(
                      child: Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Center(
                      child: Text(
                        '© 2025 Muvam. All rights reserved.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                    SizedBox(height: 30.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 20.sp,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        color: Colors.grey[700],
        height: 1.6,
      ),
      textAlign: TextAlign.justify,
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _launchWebsite(String url) async {
    final Uri webUri = Uri.parse(url);
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }
}
