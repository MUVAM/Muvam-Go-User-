# Prebook Ride Fixes

## Summary
Fixed two critical issues preventing scheduled rides from working:
1. **DateTime format error** - Backend rejected datetime without timezone
2. **Widget deactivation error** - Showing new sheet with deactivated context

## Problems

### Problem 1: DateTime Format Error (400 Bad Request)

**Error from Backend:**
```
{
  "errorz": "parsing time \"2025-12-30T22:23:00.000\" as \"2006-01-02T15:04:05Z07:00\": cannot parse \"\" as \"Z07:00\""
}
```

**Root Cause:**
The app was sending datetime in ISO8601 format without timezone:
```
2025-12-30T22:23:00.000
```

But the backend (Go server) expects RFC3339 format with timezone:
```
2025-12-30T22:23:00.000Z
```

### Problem 2: Widget Deactivation Error

**Error:**
```
Looking up a deactivated widget's ancestor is unsafe.
At this point the state of the widget's element tree is no longer stable.
```

**Root Cause:**
After closing the prebook sheet with `Navigator.pop(context)`, the code immediately tried to show the trip scheduled sheet using the same context. The context was deactivated, causing the error.

```dart
Navigator.pop(context); // ← Context deactivated
_showTripScheduledSheet(); // ❌ Uses deactivated context
```

## Solutions

### Solution 1: Add UTC Timezone to DateTime

Convert the datetime to UTC before formatting:

**Before (Broken):**
```dart
scheduledAt: isScheduled && scheduledDateTime != null
    ? scheduledDateTime.toIso8601String() // ❌ No timezone
    : null,
```

Output: `2025-12-30T22:23:00.000`

**After (Fixed):**
```dart
scheduledAt: isScheduled && scheduledDateTime != null
    ? scheduledDateTime.toUtc().toIso8601String() // ✅ With timezone
    : null,
```

Output: `2025-12-30T22:23:00.000Z`

### Solution 2: Use addPostFrameCallback

Wait for the widget tree to stabilize before showing the new sheet:

**Before (Broken):**
```dart
Navigator.pop(context); // Close prebook sheet
_showTripScheduledSheet(); // ❌ Immediate call with dead context
```

**After (Fixed):**
```dart
Navigator.pop(context); // Close prebook sheet
// Wait for frame to complete
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (mounted) {
    _showTripScheduledSheet(); // ✅ Safe call after tree stabilizes
  }
});
```

## Changes Made

### **File:** `lib/features/home/presentation/screens/home_screen.dart`

#### 1. **Fixed DateTime Format** (Line 7226)

**Before:**
```dart
scheduledAt: isScheduled && scheduledDateTime != null
    ? scheduledDateTime.toIso8601String()
    : null,
```

**After:**
```dart
scheduledAt: isScheduled && scheduledDateTime != null
    ? scheduledDateTime.toUtc().toIso8601String()
    : null,
```

**What Changed:**
- Added `.toUtc()` before `.toIso8601String()`
- This converts local time to UTC and adds the `Z` suffix

#### 2. **Fixed Widget Deactivation** (Lines 4169-4177)

**Before:**
```dart
Navigator.pop(context);
// Then show trip scheduled sheet
_showTripScheduledSheet();
```

**After:**
```dart
Navigator.pop(context);
// Then show trip scheduled sheet after frame completes
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (mounted) {
    _showTripScheduledSheet();
  }
});
```

**What Changed:**
- Wrapped `_showTripScheduledSheet()` in `addPostFrameCallback`
- Added `mounted` check for safety
- Ensures widget tree is stable before showing new sheet

## How It Works Now

### DateTime Conversion Flow

```
User selects: Dec 30, 2025 at 10:23 PM (Local time)
      ↓
DateTime(2025, 12, 30, 22, 23)
      ↓
.toUtc() → Converts to UTC
      ↓
.toIso8601String() → Formats with Z suffix
      ↓
"2025-12-30T22:23:00.000Z"
      ↓
Backend accepts ✅
```

### Widget Lifecycle Flow

```
User clicks "Set pickup date and time"
      ↓
API call succeeds
      ↓
Navigator.pop(context) - Close prebook sheet
      ↓
addPostFrameCallback scheduled
      ↓
Frame completes, widget tree stable
      ↓
Callback executes
      ↓
Check if mounted
      ↓
Show trip scheduled sheet ✅
```

## Understanding the Fixes

### Why toUtc()?

**ISO8601 Format:**
- `2025-12-30T22:23:00.000` - No timezone (ambiguous)
- `2025-12-30T22:23:00.000Z` - UTC timezone (unambiguous)

The `Z` suffix means "Zulu time" (UTC). The backend requires this to know the exact moment in time, regardless of the user's timezone.

**Example:**
```dart
// User in Nigeria (UTC+1) selects 10:23 PM
DateTime local = DateTime(2025, 12, 30, 22, 23);

// Without toUtc()
local.toIso8601String()
// Output: "2025-12-30T22:23:00.000" (ambiguous - what timezone?)

// With toUtc()
local.toUtc().toIso8601String()
// Output: "2025-12-30T21:23:00.000Z" (clear - 9:23 PM UTC)
```

### Why addPostFrameCallback?

**Widget Lifecycle:**
1. `Navigator.pop(context)` marks the sheet for removal
2. Flutter schedules the removal for the next frame
3. The context becomes "deactivated" immediately
4. Trying to use it before the frame completes causes errors

**addPostFrameCallback ensures:**
- The previous sheet is fully removed
- The widget tree is stable
- The context is valid
- No race conditions

## Benefits

### Fix 1: DateTime with Timezone
✅ **Backend accepts request** - Proper RFC3339 format
✅ **No ambiguity** - Clear UTC time
✅ **Timezone handling** - Automatic conversion
✅ **International support** - Works across timezones

### Fix 2: Safe Widget Transitions
✅ **No crashes** - Widget tree is stable
✅ **Clean transitions** - Smooth sheet changes
✅ **Safe execution** - Mounted check prevents errors
✅ **Proper lifecycle** - Respects Flutter's build phases

## Testing Checklist

### DateTime Format Testing:
- [ ] Schedule ride for future date/time
- [ ] Verify request succeeds (no 400 error)
- [ ] Check backend receives correct UTC time
- [ ] Test with different timezones
- [ ] Verify scheduled time is correct

### Widget Transition Testing:
- [ ] Click "Set pickup date and time"
- [ ] Verify prebook sheet closes
- [ ] Verify trip scheduled sheet appears
- [ ] No error in console
- [ ] Test rapid clicking
- [ ] Test with slow network

## Common DateTime Formats

| Format | Example | Use Case |
|--------|---------|----------|
| **ISO8601 (no TZ)** | `2025-12-30T22:23:00.000` | ❌ Ambiguous |
| **ISO8601 (UTC)** | `2025-12-30T22:23:00.000Z` | ✅ Backend requires this |
| **RFC3339** | `2025-12-30T22:23:00.000+01:00` | ✅ With offset |
| **Unix Timestamp** | `1735596180` | Alternative format |

## Notes

- **toUtc()** converts local time to UTC (changes the time value)
- **toIso8601String()** formats the datetime as a string
- **Z suffix** indicates UTC timezone (zero offset)
- **addPostFrameCallback** runs after the current frame completes
- **mounted check** prevents errors if widget is disposed

## Related Files

- `lib/features/home/presentation/screens/home_screen.dart` - UI and scheduling logic
- `lib/features/home/data/models/ride_models.dart` - RideRequest model
- `lib/core/services/ride_service.dart` - API communication

## Backend Requirements

The Go backend expects:
```go
type ScheduledAt time.Time

// Parse format: "2006-01-02T15:04:05Z07:00"
// Example: "2025-12-30T22:23:00.000Z"
```

The `Z07:00` part requires either:
- `Z` for UTC
- `+HH:MM` for timezone offset
- `-HH:MM` for negative offset

Our fix uses `Z` (UTC) which is the simplest and most universal.
