import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DeviceBreakpoints {
  static const double maxSupported = 1920;
  static const double tablet = 768;
  static const double computer = 800;
  static const double largeScreen = 1400;
  static const double wideScreen = 1920;
}

class DeviceDetails {
  final BoxConstraints constraints;
  final BoxConstraints originalConstraints;

  bool isMobile = false;
  bool isTablet = false;
  bool isComputer = false;
  bool isLargeScreen = false;
  bool isWidescreen = false;

  DeviceDetails(this.constraints, this.originalConstraints);

  factory DeviceDetails.fromConstraints(
    BoxConstraints constraints, {
    BoxConstraints? originalConstraints,
  }) {
    final DeviceDetails details = DeviceDetails(
      constraints,
      originalConstraints ?? constraints,
    );
    if (kIsWeb) {
      if (constraints.maxWidth >= DeviceBreakpoints.wideScreen) {
        details.isWidescreen = true;
        details.isLargeScreen = true;
        details.isComputer = true;
      } else if (constraints.maxWidth >= DeviceBreakpoints.largeScreen) {
        details.isLargeScreen = true;
        details.isComputer = true;
      } else if (constraints.maxWidth >= DeviceBreakpoints.computer) {
        details.isComputer = true;
      } else if (constraints.maxWidth >= DeviceBreakpoints.tablet) {
        details.isTablet = true;
        details.isMobile = true;
      } else {
        details.isMobile = true;
      }
    } else {
      details.isMobile = true;
    }
    return details;
  }

  factory DeviceDetails.fromSize(Size constraints) {
    final BoxConstraints boxConstraints = BoxConstraints(
      maxWidth: constraints.width,
      maxHeight: constraints.height,
    );
    final DeviceDetails details = DeviceDetails(boxConstraints, boxConstraints);
    if (kIsWeb) {
      if (constraints.width >= DeviceBreakpoints.wideScreen) {
        details.isWidescreen = true;
        details.isLargeScreen = true;
        details.isComputer = true;
      } else if (constraints.width >= DeviceBreakpoints.largeScreen) {
        details.isLargeScreen = true;
        details.isComputer = true;
      } else if (constraints.width >= DeviceBreakpoints.computer) {
        details.isComputer = true;
      } else if (constraints.width >= DeviceBreakpoints.tablet) {
        details.isTablet = true;
        details.isMobile = true;
      } else {
        details.isMobile = true;
      }
    } else {
      details.isMobile = true;
    }
    return details;
  }
}
