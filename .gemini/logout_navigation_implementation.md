# Logout Navigation Implementation

## Summary
Implemented complete logout functionality that navigates users back to the phone number (onboarding) screen after clearing all state variables and authentication data.

## Changes Made

### **File:** `lib/features/profile/presentation/screens/profile_screen.dart`

#### 1. **Added Import for OnboardingScreen** (Line 10)

```dart
import 'package:muvam/features/auth/presentation/screens/onboarding_screen.dart';
```

This import allows us to navigate to the onboarding screen after logout.

#### 2. **Updated Logout Logic** (Lines 295-310)

**Before:**
```dart
await profileProvider.clearProfile();
await authProvider.logout();

Navigator.pop(context);
// Navigate to login screen
```

**After:**
```dart
await profileProvider.clearProfile();
await authProvider.logout();

// Close the logout sheet
Navigator.pop(context);

// Navigate to onboarding screen and clear all previous routes
Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(
    builder: (context) => const OnboardingScreen(),
  ),
  (route) => false,
);
```

## How It Works

### Logout Flow

```
User taps "Logout" button
      ↓
Show logout confirmation sheet
      ↓
User confirms logout
      ↓
Clear profile data (profileProvider.clearProfile())
      ↓
Clear auth data (authProvider.logout())
      ↓
Close logout sheet (Navigator.pop)
      ↓
Navigate to OnboardingScreen
Clear entire navigation stack
      ↓
User sees phone number entry screen ✅
```

### State Cleanup

#### 1. **Profile Provider Cleanup**

```dart
await profileProvider.clearProfile();
```

This clears:
- User profile data
- Profile photo
- User name, email, phone
- All cached profile information

#### 2. **Auth Provider Cleanup**

```dart
await authProvider.logout();
```

This clears (from `auth_provider.dart`):
- Authentication token (via `_authService.clearToken()`)
- `_verifyOtpResponse = null`
- `_registerUserResponse = null`
- `_userData = {}`
- Notifies all listeners

### Navigation Strategy

**Using `pushAndRemoveUntil`:**

```dart
Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(
    builder: (context) => const OnboardingScreen(),
  ),
  (route) => false,  // Remove ALL previous routes
);
```

**Why `pushAndRemoveUntil`?**

✅ **Clears navigation stack** - Removes all previous screens
✅ **Prevents back navigation** - User can't go back to authenticated screens
✅ **Fresh start** - App state is completely reset
✅ **Memory efficient** - Disposes all previous screens

**Alternative approaches (NOT used):**
- ❌ `Navigator.push()` - Would keep previous screens in stack
- ❌ `Navigator.pushReplacement()` - Only replaces current screen
- ❌ `Navigator.pushNamed()` - Requires named routes (not configured)

## What Gets Cleared

### Authentication State
- ✅ Auth token removed from SharedPreferences
- ✅ OTP verification response cleared
- ✅ User registration response cleared
- ✅ User data map emptied

### Profile State
- ✅ User profile object cleared
- ✅ Profile photo URL removed
- ✅ User name cleared
- ✅ Email cleared
- ✅ Phone number cleared
- ✅ All cached profile data removed

### Navigation State
- ✅ All previous screens removed from stack
- ✅ Home screen disposed
- ✅ Profile screen disposed
- ✅ Any other screens in stack disposed

## User Experience

### Before Logout
```
Navigation Stack:
├─ OnboardingScreen (initial)
├─ OtpScreen
├─ CreateAccountScreen
├─ HomeScreen
└─ ProfileScreen (current)
```

### After Logout
```
Navigation Stack:
└─ OnboardingScreen (only screen)
```

**User sees:**
1. Logout confirmation sheet
2. Brief loading (while clearing data)
3. Smooth transition to onboarding screen
4. Phone number entry screen
5. No way to navigate back to authenticated screens

## Security Benefits

✅ **Complete session termination** - All auth data removed
✅ **No residual data** - Profile and user data cleared
✅ **Secure navigation** - Can't go back to authenticated screens
✅ **Fresh authentication** - Must re-enter phone and verify OTP
✅ **Memory cleanup** - All previous screens disposed

## Testing Checklist

### Logout Flow
- [ ] Tap logout button
- [ ] Confirm logout in sheet
- [ ] Verify navigation to onboarding screen
- [ ] Verify phone number field is empty
- [ ] Try pressing back button (should exit app, not go to home)

### State Cleanup
- [ ] After logout, check SharedPreferences (token should be gone)
- [ ] Verify profile data is cleared
- [ ] Verify auth data is cleared
- [ ] Try accessing protected screens (should redirect to login)

### Navigation
- [ ] Verify can't navigate back to home screen
- [ ] Verify can't navigate back to profile screen
- [ ] Verify navigation stack is cleared
- [ ] Test with Android back button
- [ ] Test with iOS swipe back gesture

## Related Files

- **`lib/features/profile/presentation/screens/profile_screen.dart`** - Logout button and logic
- **`lib/features/auth/presentation/screens/onboarding_screen.dart`** - Phone number entry screen
- **`lib/features/auth/data/providers/auth_provider.dart`** - Auth state management
- **`lib/features/profile/data/providers/user_profile_provider.dart`** - Profile state management
- **`lib/features/profile/presentation/widgets/logout_sheet.dart`** - Logout confirmation UI

## Code Examples

### Complete Logout Implementation

```dart
void _showLogoutSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (context) => LogoutSheet(
      onLogout: () async {
        // Get providers
        final profileProvider = Provider.of<UserProfileProvider>(
          context,
          listen: false,
        );
        final authProvider = Provider.of<AuthProvider>(
          context,
          listen: false,
        );

        // Clear all data
        await profileProvider.clearProfile();
        await authProvider.logout();

        // Close the logout sheet
        Navigator.pop(context);
        
        // Navigate to onboarding screen and clear all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const OnboardingScreen(),
          ),
          (route) => false,
        );
      },
      onGoBack: () => Navigator.pop(context),
    ),
  );
}
```

### Auth Provider Logout Method

```dart
Future<void> logout() async {
  await _authService.clearToken();
  _verifyOtpResponse = null;
  _registerUserResponse = null;
  _userData = {};
  notifyListeners();
}
```

### Profile Provider Clear Method

```dart
Future<void> clearProfile() async {
  _userProfile = null;
  _isLoading = false;
  _errorMessage = null;
  notifyListeners();
  
  // Clear from SharedPreferences if stored
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('user_profile');
}
```

## Benefits

✅ **Complete logout** - All user data and state cleared
✅ **Secure** - No residual authentication data
✅ **Clean navigation** - Fresh start on onboarding screen
✅ **User-friendly** - Clear, predictable behavior
✅ **Memory efficient** - All previous screens disposed
✅ **Prevents bugs** - No stale data or navigation issues

## Future Enhancements

### Potential Improvements:
1. **Add logout analytics** - Track logout events
2. **Show logout success message** - Brief confirmation toast
3. **Add "Stay logged in" option** - Remember me functionality
4. **Implement session timeout** - Auto-logout after inactivity
5. **Add logout from all devices** - Server-side token invalidation

### Optional Features:
- **Logout confirmation with reason** - Ask why user is logging out
- **Quick re-login** - Remember phone number (not password)
- **Logout animation** - Smooth transition effect
- **Clear cache on logout** - Remove all cached data

## Notes

- The logout is **asynchronous** to ensure all data is properly cleared
- The navigation uses **`pushAndRemoveUntil`** to prevent back navigation
- The **`(route) => false`** predicate removes ALL previous routes
- The **`const OnboardingScreen()`** creates a fresh instance
- All **providers are notified** of the state changes

## Troubleshooting

### Issue: Back button still shows previous screens
**Solution:** Verify `(route) => false` is used, not `(route) => true`

### Issue: Data persists after logout
**Solution:** Check that both `clearProfile()` and `logout()` are called

### Issue: Navigation doesn't work
**Solution:** Ensure OnboardingScreen import is correct

### Issue: App crashes on logout
**Solution:** Check that `mounted` is verified before navigation

## Summary

The logout functionality now:
1. ✅ Clears all user profile data
2. ✅ Clears all authentication data
3. ✅ Removes auth token from storage
4. ✅ Navigates to onboarding screen
5. ✅ Clears entire navigation stack
6. ✅ Prevents back navigation to authenticated screens
7. ✅ Provides clean, secure logout experience

Users can now safely log out and will be returned to the phone number entry screen with all state properly reset!
