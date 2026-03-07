import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:muvam/core/config/repository/ui_service.dart';
import 'package:muvam/core/constants/app_spacings.dart';
import 'package:muvam/layouts/presentation/shared/app_scaffold.dart';
import 'package:muvam/layouts/presentation/shared/device_responsive_view.dart';
import 'package:provider/provider.dart';

class WebPage extends StatelessWidget {
  final Color? backgroundColor;
  final Widget Function(
    BuildContext context,
    BoxConstraints constraints,
    DeviceDetails deviceType,
  )
  builder;
  final ScrollController? scrollController;
  final ScrollPhysics? scrollPhysics;
  final bool showAppbar;
  final bool compactView;
  final List<Widget> actions;

  const WebPage({
    super.key,
    required this.builder,
    this.scrollController,
    this.showAppbar = true,
    this.scrollPhysics,
    this.backgroundColor,
    this.compactView = false,
    this.actions = const [],
  });

  void _parseBaseURL(BuildContext context) {
    final String? previewQueryParam = Uri.base.queryParameters['preview'];
    if (previewQueryParam != null) {
      final Codec<String, String> stringToBase64Url = utf8.fuse(base64Url);
      final String decodedJson = stringToBase64Url.decode(previewQueryParam);
      final Map<String, dynamic> jsonData = jsonDecode(decodedJson);
      debugPrint(jsonData.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final uiService = Provider.of<UIService>(context, listen: false);

    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, appConstraints) {
          final double maxClampedWidth = appConstraints.maxWidth.clamp(
            DeviceBreakpoints.computer,
            DeviceBreakpoints.maxSupported,
          );
          final BoxConstraints constraints = appConstraints.copyWith(
            maxWidth: maxClampedWidth * 0.8,
            minWidth: 0,
            maxHeight: appConstraints.maxHeight,
            minHeight: 0,
          );
          final DeviceDetails deviceDetails = DeviceDetails.fromConstraints(
            constraints,
            originalConstraints: appConstraints,
          );
          const String currentPath = '';
          if (currentPath == '/') {
            _parseBaseURL(context);
          }
          uiService.setDeviceType(context, deviceDetails);
          final Widget builderChild = builder(
            context,
            constraints,
            deviceDetails,
          );
          return AppScaffold(
            backgroundColor: backgroundColor,
            resizeToAvoidBottomInset: deviceDetails.isMobile,
            body: SizedBox(
              width: appConstraints.maxWidth,
              height: appConstraints.maxHeight,
              child: Center(
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: Builder(
                    builder: (context) {
                      if (compactView && !deviceDetails.isMobile) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (actions.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: AppSpacings.elementSpacing,
                                  right: constraints.maxWidth * 0.15,
                                  top: AppSpacings.k20,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: actions,
                                ),
                              ),
                            Expanded(
                              child: Center(
                                child: SizedBox(
                                  width: constraints.maxWidth * 0.5,
                                  height: constraints.maxHeight * 0.9,
                                  child: builderChild,
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return builderChild;
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
