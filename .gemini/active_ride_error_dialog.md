# Active Ride Error Alert Dialog Implementation

## Summary
Added alert dialog to inform users when they try to book a new ride while having an active ride in progress, providing clear error message and guidance.

## Problem
When users tried to book a new ride while having an active ride, the backend returned an error:
```
"passenger has an active ride; complete it before requesting a new one"
```

However, the app only logged this error without informing the user, leading to confusion about why the booking failed.

## Solution
Implemented an alert dialog that:
1. Detects when the error is about an active ride
2. Shows a user-friendly dialog with clear message
3. Provides guidance on what to do next
4. Falls back to a generic error message for other errors

## Changes Made

### **Home Screen** (`lib/features/home/presentation/screens/home_screen.dart`)

#### Updated Error Handling in Two Places:

**1. Card Payment Error Handler** (Line ~3409)
**2. Other Payment Methods Error Handler** (Line ~3458)

#### Implementation:

```dart
} catch (e) {
  AppLogger.error('❌ Payment failed', error: e, tag: 'BOOK_NOW');
  
  if (mounted) {
    // Check if error is about active ride
    final errorMessage = e.toString();
    if (errorMessage.contains('active ride') || 
        errorMessage.contains('complete it before')) {
      // Show alert dialog for active ride error
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.r),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 28.sp,
                ),
                SizedBox(width: 10.w),
                Text(
                  'Active Ride',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: Text(
              'You already have an active ride. Please complete or cancel your current ride before requesting a new one.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14.sp,
                color: Colors.grey[700],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Color(ConstColors.mainColor),
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else {
      // Show generic error snackbar for other errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to book ride. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

## Dialog Design

### Visual Elements:

**Title:**
- ⚠️ Warning icon (orange)
- "Active Ride" text
- Clean, professional layout

**Content:**
- Clear explanation of the issue
- Guidance on what to do next
- Easy-to-read font and color

**Action:**
- Single "OK" button
- Branded color (main app color)
- Dismisses the dialog

### Dialog Preview:

```
┌─────────────────────────────────┐
│ ⚠️  Active Ride                 │
├─────────────────────────────────┤
│                                 │
│ You already have an active      │
│ ride. Please complete or cancel │
│ your current ride before        │
│ requesting a new one.           │
│                                 │
├─────────────────────────────────┤
│                            [OK] │
└─────────────────────────────────┘
```

## Error Detection Logic

### Active Ride Error Detected When:
```dart
errorMessage.contains('active ride') || 
errorMessage.contains('complete it before')
```

### Other Errors:
- Shows generic SnackBar
- Red background
- Message: "Failed to book ride. Please try again."

## User Flow

### Before (Problem):
```
User taps "Book Now" with active ride
         ↓
Backend returns error
         ↓
Error logged only ❌
         ↓
User confused why booking failed
```

### After (Fixed):
```
User taps "Book Now" with active ride
         ↓
Backend returns error
         ↓
Error logged ✅
         ↓
Alert dialog shown ✅
         ↓
User understands the issue
         ↓
User completes/cancels current ride
```

## Benefits

✅ **User-Friendly**: Clear, non-technical error message
✅ **Actionable**: Tells user exactly what to do
✅ **Professional**: Well-designed dialog with proper styling
✅ **Consistent**: Same error handling for all payment methods
✅ **Fallback**: Generic error for other issues

## Payment Methods Covered

1. ✅ **Pay with Card** - Shows alert dialog
2. ✅ **Pay in Car** - Shows alert dialog
3. ✅ **Pay with Wallet** - Shows alert dialog (if implemented)
4. ✅ **Other Methods** - Shows alert dialog

## Testing Checklist

- [ ] Try to book ride with active ride - verify alert shows
- [ ] Tap "OK" button - verify dialog dismisses
- [ ] Check alert shows for card payment
- [ ] Check alert shows for other payment methods
- [ ] Verify generic error shows for other errors
- [ ] Test dialog appearance and styling
- [ ] Verify text is readable and clear

## Error Messages

### Active Ride Error:
```
Title: "Active Ride"
Message: "You already have an active ride. Please complete or cancel your current ride before requesting a new one."
```

### Generic Error:
```
SnackBar: "Failed to book ride. Please try again."
```

## Related Files

- `lib/features/home/presentation/screens/home_screen.dart` - Error handling implementation

## Notes

- The dialog uses the app's main color for branding consistency
- The warning icon is orange to indicate caution (not critical error)
- The message is friendly and instructive, not technical
- The dialog is modal and requires user interaction to dismiss
- Error detection is case-sensitive and checks for specific keywords
