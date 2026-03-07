import 'package:flutter/material.dart';
import 'package:muvam/core/config/repository/ui_service.dart';
import 'package:muvam/layouts/presentation/shared/device_responsive_view.dart';
import 'package:provider/provider.dart';

class AppScaffold extends StatelessWidget {
  final Widget floatingActionButton;
  final Widget body;
  final bool compactView;
  final Widget bottom;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final PreferredSizeWidget? appBar;

  const AppScaffold({
    super.key,
    this.floatingActionButton = const SizedBox(),
    required this.body,
    this.bottom = const SizedBox.shrink(),
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.compactView = false,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    final uiService = Provider.of<UIService>(context, listen: false);

    return LayoutBuilder(
      builder: (context, constraint) {
        final DeviceDetails details =
            uiService.deviceTypeNotifier.value ??
            DeviceDetails.fromConstraints(
              constraint,
              originalConstraints: constraint,
            );

        return Scaffold(
          appBar: appBar,
          extendBodyBehindAppBar: false,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          backgroundColor:
              backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
          floatingActionButton: floatingActionButton,
          body: SafeArea(
            child: Builder(
              builder: (context) {
                if (compactView && !details.isMobile) {
                  return GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: Center(
                      child: SizedBox(
                        width: constraint.maxWidth * 0.60,
                        height: constraint.maxHeight * 0.85,
                        child: body,
                      ),
                    ),
                  );
                }
                return GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: body,
                );
              },
            ),
          ),
          bottomNavigationBar: bottom,
        );
      },
    );
  }
}
