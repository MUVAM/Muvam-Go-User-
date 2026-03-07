import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';

class StateSelectionScreen extends StatefulWidget {
  const StateSelectionScreen({super.key});

  @override
  State<StateSelectionScreen> createState() => _StateSelectionScreenState();
}

class _StateSelectionScreenState extends State<StateSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredStates = [];
  Map<String, List<String>> _groupedStates = {};
  List<String> _groupHeaders = [];

  final List<String> _nigerianStates = [
    'Abia',
    'Adamawa',
    'Akwa Ibom',
    'Anambra',
    'Bauchi',
    'Bayelsa',
    'Benue',
    'Borno',
    'Cross River',
    'Delta',
    'Ebonyi',
    'Edo',
    'Ekiti',
    'Enugu',
    'Gombe',
    'Imo',
    'Jigawa',
    'Kaduna',
    'Kano',
    'Katsina',
    'Kebbi',
    'Kogi',
    'Kwara',
    'Lagos',
    'Nasarawa',
    'Niger',
    'Ogun',
    'Ondo',
    'Osun',
    'Oyo',
    'Plateau',
    'Rivers',
    'Sokoto',
    'Taraba',
    'Yobe',
    'Zamfara',
    'FCT',
  ];

  @override
  void initState() {
    super.initState();
    _filteredStates = List.from(_nigerianStates);
    _groupStates(_filteredStates);
  }

  void _groupStates(List<String> states) {
    _groupedStates.clear();
    _groupHeaders.clear();
    for (final state in states) {
      final firstChar = state.isEmpty ? '#' : state[0].toUpperCase();
      final header = RegExp(r'[A-Z]').hasMatch(firstChar) ? firstChar : '#';
      _groupedStates.putIfAbsent(header, () {
        _groupHeaders.add(header);
        return [];
      });
      _groupedStates[header]!.add(state);
    }
    _groupHeaders.sort((a, b) {
      if (a == '#') return -1;
      if (b == '#') return 1;
      return a.compareTo(b);
    });
    setState(() {});
  }

  void _filterStates(String query) {
    _filteredStates = query.isEmpty
        ? List.from(_nigerianStates)
        : _nigerianStates
              .where((s) => s.toLowerCase().contains(query.toLowerCase()))
              .toList();
    _groupStates(_filteredStates);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.kWhiteColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Image.asset(
                      ConstImages.back,
                      width: 33.w,
                      height: 33.h,
                    ),
                  ),
                  const Spacer(),
                  MuvamTexts.headlineSmall24(
                    context,
                    text: 'Select State',
                    isTextWidget: true,
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                height: 47.h,
                decoration: BoxDecoration(
                  color: AppColors.kFieldColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterStates,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.sp,
                    color: AppColors.kBlackColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search state',
                    hintStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.sp,
                      color: Colors.grey,
                    ),
                    prefixIcon: SvgPicture.asset(
                      ConstImages.search,
                      width: 20.w,
                      height: 20.h,
                      fit: BoxFit.scaleDown,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: _filteredStates.isEmpty
                  ? Center(
                      child: MuvamTexts.bodyMedium14(
                        context,
                        text: 'No states found',
                        isTextWidget: true,
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      itemCount: _groupHeaders.length,
                      itemBuilder: (context, index) {
                        final header = _groupHeaders[index];
                        final statesInGroup = _groupedStates[header] ?? [];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                top: index == 0 ? 0 : 24.h,
                                bottom: 8.h,
                              ),
                              child: MuvamTexts.titleSmall14(
                                context,
                                text: header,
                                isTextWidget: true,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            ...statesInGroup.map(
                              (state) => GestureDetector(
                                onTap: () => context.pop(state),
                                child: Container(
                                  margin: EdgeInsets.only(bottom: 8.h),
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.withOpacity(0.1),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: MuvamTexts.bodyLarge16(
                                    context,
                                    text: state,
                                    isTextWidget: true,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
