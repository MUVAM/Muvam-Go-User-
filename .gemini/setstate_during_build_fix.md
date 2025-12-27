# setState During Build Phase Fix

## Summary
Fixed the "setState() or markNeedsBuild() called during build" error by moving the `_loadProfile()` call from direct execution in `initState()` to `addPostFrameCallback`, ensuring it runs after the widget tree is built.

## Problem
When the app started, the following error appeared:

```
setState() or markNeedsBuild() called during build.
This _InheritedProviderScope<UserProfileProvider?> widget cannot be marked as needing to build 
because the framework is already in the process of building widgets.
```

### Error Stack Trace
```
#4  UserProfileProvider.fetchUserProfile (user_profile_provider.dart:39:5)
#5  _HomeScreenState._loadProfile (home_screen.dart:1829:27)
#6  _HomeScreenState.initState (home_screen.dart:154:5)
```

### Root Cause
The `_loadProfile()` method was called directly in `initState()`, which triggered `fetchUserProfile()` in the `UserProfileProvider`. This method calls `notifyListeners()`, which attempts to call `setState()` while the widget tree is still being built.

**Flutter Rule Violated:**
You cannot call `setState()` or `notifyListeners()` during the build phase. These must be called after the initial build is complete.

## Solution
Moved `_loadProfile()` into the `addPostFrameCallback` callback, which ensures it runs **after** the first frame is rendered and the widget tree is fully built.

## Changes Made

### **Home Screen** (`lib/features/home/presentation/screens/home_screen.dart`)

**Before:**
```dart
@override
void initState() {
  super.initState();
  
  _getCurrentLocation();
  _forceUpdateLocation();
  _createDriverIcon();
  _createCurrentLocationIcon();
  _createPickupIcon();
  _createDestinationIcon();
  _loadProfile(); // ❌ Called during build phase
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Provider.of<LocationProvider>(context, listen: false).loadFavouriteLocations();
    _loadFavouriteLocations();
    _listenToWebSocketMessages();
    _setupOtherWebSocketListeners();
    _initializeCallService();
    _startActiveRideChecking();
  });
}
```

**After:**
```dart
@override
void initState() {
  super.initState();
  
  _getCurrentLocation();
  _forceUpdateLocation();
  _createDriverIcon();
  _createCurrentLocationIcon();
  _createPickupIcon();
  _createDestinationIcon();
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Load profile after build is complete ✅
    _loadProfile();
    
    Provider.of<LocationProvider>(context, listen: false).loadFavouriteLocations();
    _loadFavouriteLocations();
    _listenToWebSocketMessages();
    _setupOtherWebSocketListeners();
    _initializeCallService();
    _startActiveRideChecking();
  });
}
```

## How It Works

### Build Phase Timeline

**Before (Broken):**
```
initState() called
    ↓
_loadProfile() called immediately
    ↓
fetchUserProfile() called
    ↓
notifyListeners() called
    ↓
setState() attempted during build ❌
    ↓
ERROR: setState during build
```

**After (Fixed):**
```
initState() called
    ↓
Icon creation methods called (safe)
    ↓
addPostFrameCallback registered
    ↓
Build completes
    ↓
First frame rendered
    ↓
PostFrameCallback executes
    ↓
_loadProfile() called ✅
    ↓
fetchUserProfile() called
    ↓
notifyListeners() called
    ↓
setState() works correctly ✅
```

## What is addPostFrameCallback?

`WidgetsBinding.instance.addPostFrameCallback` is a Flutter method that schedules a callback to run **after** the current frame is rendered. This ensures:

1. ✅ Widget tree is fully built
2. ✅ All widgets are mounted
3. ✅ Safe to call setState()
4. ✅ Safe to trigger provider notifications

## Methods That Are Safe in initState()

### ✅ Safe (Synchronous, No setState):
- `_getCurrentLocation()` - Just gets location
- `_createDriverIcon()` - Creates bitmap icons
- `_createCurrentLocationIcon()` - Creates bitmap icons
- `_createPickupIcon()` - Creates bitmap icons
- `_createDestinationIcon()` - Creates bitmap icons

### ❌ Unsafe (Triggers setState/notifyListeners):
- `_loadProfile()` - Calls provider that notifies listeners
- `_loadFavouriteLocations()` - May trigger state changes
- `_listenToWebSocketMessages()` - Sets up listeners
- `_setupOtherWebSocketListeners()` - Sets up listeners
- `_initializeCallService()` - Initializes services
- `_startActiveRideChecking()` - Starts timers

## Benefits

✅ **No More Errors** - setState during build error eliminated
✅ **Proper Lifecycle** - Respects Flutter's build lifecycle
✅ **Clean Code** - Follows Flutter best practices
✅ **Future-Proof** - Won't cause issues in production
✅ **Stable App** - No unexpected crashes or warnings

## Flutter Best Practices

### When to Use addPostFrameCallback:

1. **Loading data from providers** that call `notifyListeners()`
2. **Showing dialogs** or snackbars on screen load
3. **Navigating** to another screen immediately
4. **Accessing BuildContext** for inherited widgets
5. **Any operation** that triggers `setState()`

### Example Pattern:
```dart
@override
void initState() {
  super.initState();
  
  // ✅ Synchronous initialization (no setState)
  _initializeVariables();
  _createIcons();
  
  // ✅ Async operations that trigger setState
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadData();
    _setupListeners();
    _checkInitialState();
  });
}
```

## Testing Checklist

- [ ] Restart app - verify no "setState during build" error
- [ ] Check user profile loads correctly
- [ ] Verify favourite locations load
- [ ] Test WebSocket connection establishes
- [ ] Verify call service initializes
- [ ] Check active ride checking starts
- [ ] Confirm no console errors on app start
- [ ] Test hot reload works properly

## Related Files

- `lib/features/home/presentation/screens/home_screen.dart` - initState fix
- `lib/features/profile/data/providers/user_profile_provider.dart` - Provider that was causing issue

## Notes

- This is a common Flutter error when working with providers
- Always defer provider calls that trigger `notifyListeners()` to after build
- `addPostFrameCallback` is the standard solution for this pattern
- The error was non-fatal but could cause issues in production
- This fix ensures proper Flutter lifecycle management
