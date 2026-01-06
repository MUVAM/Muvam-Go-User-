import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/images.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  int? _expandedIndex;

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I request a ride?',
      'answer':
          'Simply open the app, enter your destination, and tap "Request Ride". A nearby driver will be matched with you automatically.',
    },
    {
      'question': 'How is the fare calculated?',
      'answer':
          'Fares are calculated based on distance, time, and current demand. You\'ll see the estimated fare before confirming your ride.',
    },
    {
      'question': 'Can I schedule a ride in advance?',
      'answer':
          'Yes! When requesting a ride, tap the clock icon to schedule a pickup time up to 7 days in advance.',
    },
    {
      'question': 'What payment methods are accepted?',
      'answer':
          'We accept cash, credit/debit cards, and mobile wallet payments. You can manage your payment methods in the Wallet section.',
    },
    {
      'question': 'How do I cancel a ride?',
      'answer':
          'You can cancel a ride from the active ride screen. Note that cancellation fees may apply if the driver is already on the way.',
    },
    {
      'question': 'What if I left something in the vehicle?',
      'answer':
          'Go to your ride history, select the trip, and use the "Contact Driver" option to reach out about lost items.',
    },
    {
      'question': 'How do I rate my driver?',
      'answer':
          'After each ride, you\'ll be prompted to rate your driver on a scale of 1-5 stars and provide optional feedback.',
    },
    {
      'question': 'Is my ride insured?',
      'answer':
          'Yes, all rides are covered by our comprehensive insurance policy for your safety and peace of mind.',
    },
    {
      'question': 'How do I add a stop during my ride?',
      'answer':
          'You can add stops when requesting a ride by tapping "Add Stop" before confirming. Additional charges may apply.',
    },
    {
      'question': 'What should I do in case of an emergency?',
      'answer':
          'Use the emergency button in the app to contact local authorities and share your ride details with emergency contacts.',
    },
  ];

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
                        'FAQ',
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
            SizedBox(height: 20.h),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                itemCount: _faqs.length,
                separatorBuilder: (context, index) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final faq = _faqs[index];
                  final isExpanded = _expandedIndex == index;
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isExpanded
                            ? Color(ConstColors.mainColor)
                            : Colors.grey.shade200,
                        width: isExpanded ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _expandedIndex = isExpanded ? null : index;
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        faq['question']!,
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: Color(ConstColors.mainColor),
                                      size: 24.sp,
                                    ),
                                  ],
                                ),
                                if (isExpanded) ...[
                                  SizedBox(height: 12.h),
                                  Text(
                                    faq['answer']!,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.grey[700],
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
