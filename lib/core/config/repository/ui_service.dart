import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:muvam/layouts/presentation/shared/device_responsive_view.dart';

enum ResultState { idle, loading }

@immutable
class Result<T> {
  final T data;
  final Map<String, dynamic> meta;
  final ResultState state;

  bool get isLoading => state == ResultState.loading;

  const Result({required this.data, this.meta = const {}, required this.state});

  factory Result.initial({
    required T data,
    Map<String, dynamic> meta = const {},
  }) {
    return Result(data: data, state: ResultState.idle, meta: meta);
  }

  Result<T> copyWith({
    T? data,
    Map<String, dynamic>? meta,
    ResultState? state,
  }) {
    return Result<T>(
      data: data ?? this.data,
      meta: meta ?? this.meta,
      state: state ?? this.state,
    );
  }

  @override
  bool operator ==(covariant Result<T> other) {
    if (identical(this, other)) return true;

    return other.data == data &&
        mapEquals(other.meta, meta) &&
        other.state == state;
  }

  @override
  int get hashCode => data.hashCode ^ meta.hashCode ^ state.hashCode;
}

class UIService extends ChangeNotifier {
  BuildContext? _mainContext;

  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<bool> customDrawerNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<OverlayEntry?> _currentOverlay =
      ValueNotifier<OverlayEntry?>(null);
  final ValueNotifier<DeviceDetails?> _deviceDetails =
      ValueNotifier<DeviceDetails?>(null);

  bool get hasOverlay => _currentOverlay.value != null;
  ValueNotifier<OverlayEntry?> get currentOverlay => _currentOverlay;

  DeviceDetails? get deviceType => _deviceDetails.value;
  ValueNotifier<DeviceDetails?> get deviceTypeNotifier => _deviceDetails;

  bool get isMobileDevice => _deviceDetails.value?.isMobile ?? true;
  bool get isTabletDevice => _deviceDetails.value?.isTablet ?? false;
  bool get isComputerDevice => _deviceDetails.value?.isComputer ?? false;

  BuildContext? get mainContext => _mainContext;

  void setDeviceType(BuildContext context, DeviceDetails details) {
    _mainContext = context;
    _deviceDetails.value = details;
    unsetOverlay();
  }

  void openDrawer({bool value = true, Function()? onDone}) {
    customDrawerNotifier.value = value;
    if (onDone != null) {
      Future.delayed(const Duration(milliseconds: 400), onDone);
    }
  }

  bool get isLoading => _isLoading.value;
  ValueNotifier<bool> get uiLoading => _isLoading;

  void _startLoading([bool value = true]) => _isLoading.value = value;
  void _stopLoading() => _isLoading.value = false;

  Future<T?> runFuture<T>(
    Future Function() future, {
    Function(dynamic)? onError,
  }) async {
    if (isLoading == false) {
      try {
        _startLoading();
        T response = await future();
        _stopLoading();
        return response;
      } catch (error) {
        _stopLoading();
        if (onError != null) {
          onError(error);
        }
      }
    }
    return null;
  }

  OverlayEntry createOverlay(OverlayEntry entry) {
    _currentOverlay.value = entry;
    return entry;
  }

  void unsetOverlay() {
    _currentOverlay.value?.remove();
    _currentOverlay.value = null;
  }
}
