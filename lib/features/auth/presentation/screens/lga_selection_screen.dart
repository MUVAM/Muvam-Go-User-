import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:muvam/core/constants/colors.dart';
import 'package:muvam/core/constants/images.dart';
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
    _initializeLgas();
  }

  void _initializeLgas() {
    _allLgas = NigerianStatesAndLGA.getStateLGAs(widget.selectedState);
    _filteredLgas = List.from(_allLgas);
    _groupLgas(_filteredLgas);
  }

  void _groupLgas(List<String> lgas) {
    _groupedLgas.clear();
    _groupHeaders.clear();

    for (var lga in lgas) {
      String header;
      if (lga.isEmpty) {
        header = '#';
      } else {
        final firstChar = lga[0].toUpperCase();
        if (RegExp(r'[0-9]').hasMatch(firstChar)) {
          header = '#';
        } else if (RegExp(r'[A-Z]').hasMatch(firstChar)) {
          header = firstChar;
        } else {
          header = '#';
        }
      }

      if (!_groupedLgas.containsKey(header)) {
        _groupedLgas[header] = [];
        _groupHeaders.add(header);
      }
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
    if (query.isEmpty) {
      _filteredLgas = List.from(_allLgas);
    } else {
      _filteredLgas = _allLgas
          .where((lga) => lga.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }

    _groupLgas(_filteredLgas);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset(
                      ConstImages.back,
                      width: 30.w,
                      height: 30.h,
                    ),
                  ),
                  Spacer(),
                  Text(
                    'Select LGA',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 20.sp,
                      color: Colors.black,
                    ),
                  ),
                  Spacer(),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'State: ${widget.selectedState}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14.sp,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: Color(ConstColors.fieldColor).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterLgas,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14.sp,
                        color: Colors.black,
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
                      child: Text(
                        'No LGAs found',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14.sp,
                          color: Colors.black,
                        ),
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
                              child: Text(
                                header,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14.sp,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            ...lgasInGroup.map((lga) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.pop(context, lga);
                                },
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
                                  child: Text(
                                    lga,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w400,
                                      fontSize: 16.sp,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
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
