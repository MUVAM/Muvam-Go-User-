import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:muvam/core/constants/app_colors.dart';
import 'package:muvam/core/constants/app_spacings.dart';
import 'package:muvam/core/constants/images.dart';
import 'package:muvam/core/constants/muvam_text.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';
import 'package:nigerian_states_and_lga/nigerian_states_and_lga.dart';

class LgaSelectionScreen extends StatefulWidget {
  final String selectedState;
  const LgaSelectionScreen({super.key, required this.selectedState});

  @override
  State<LgaSelectionScreen> createState() => _LgaSelectionScreenState();
}

class _LgaSelectionScreenState extends State<LgaSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredLgas = [];
  Map<String, List<String>> _groupedLgas = {};
  List<String> _groupHeaders = [];
  List<String> _allLgas = [];

  @override
  void initState() {
    super.initState();
    _allLgas = NigerianStatesAndLGA.getStateLGAs(widget.selectedState);
    _filteredLgas = List.from(_allLgas);
    _groupLgas(_filteredLgas);
  }

  void _groupLgas(List<String> lgas) {
    _groupedLgas.clear();
    _groupHeaders.clear();
    for (final lga in lgas) {
      final firstChar = lga.isEmpty ? '#' : lga[0].toUpperCase();
      final header = RegExp(r'[A-Z]').hasMatch(firstChar) ? firstChar : '#';
      _groupedLgas.putIfAbsent(header, () {
        _groupHeaders.add(header);
        return [];
      });
      _groupedLgas[header]!.add(lga);
    }
    _groupHeaders.sort((a, b) {
      if (a == '#') return -1;
      if (b == '#') return 1;
      return a.compareTo(b);
    });
    setState(() {});
  }

  void _filterLgas(String query) {
    _filteredLgas = query.isEmpty
        ? List.from(_allLgas)
        : _allLgas
              .where((l) => l.toLowerCase().contains(query.toLowerCase()))
              .toList();
    _groupLgas(_filteredLgas);
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
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacings.k20,
                vertical: AppSpacings.k20,
              ),
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
                    text: 'Select LGA',
                    isTextWidget: true,
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MuvamTexts.bodySmall12(
                    context,
                    text: 'State: ${widget.selectedState}',
                    isTextWidget: true,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    height: 47.h,
                    decoration: BoxDecoration(
                      color: AppColors.kFieldColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterLgas,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.sp,
                        color: AppColors.kBlackColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search LGA',
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
                ],
              ),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: _filteredLgas.isEmpty
                  ? Center(
                      child: MuvamTexts.bodyMedium14(
                        context,
                        text: 'No LGAs found',
                        isTextWidget: true,
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      itemCount: _groupHeaders.length,
                      itemBuilder: (context, index) {
                        final header = _groupHeaders[index];
                        final lgasInGroup = _groupedLgas[header] ?? [];
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
                            ...lgasInGroup.map(
                              (lga) => GestureDetector(
                                onTap: () => context.pop(lga),
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
                                    text: lga,
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
