# Driver Arrival Timer Visibility Fix

## Summary
Made the driver arrival time circle (timer) only visible when the driver is on the way, hiding it when the driver has arrived or the trip has started.

## Problem
The circular timer showing the driver's arrival time was always visible in the "Driver Accepted" sheet, regardless of the ride status. This didn't make sense when:
- The driver had already arrived (timer no longer relevant)
- The trip had started (timer no longer relevant)

## Solution
Added conditional rendering to only show the timer container when the driver is on the way.

## Changes Made

### **HomeScreen** (`lib/features/home/presentation/screens/home_screen.dart`)

**Before:**
```dart
Row(
  children: [
    Container(
      width: 60.w,
      height: 60.h,
      decoration: BoxDecoration(
        color: Color(ConstColors.mainColor),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(_driverArrivalTime, ...),
      ),
    ),
    SizedBox(width: 15.w),
    Expanded(...),
  ],
)
```

**After:**
```dart
Row(
  children: [
    // Only show timer when driver is on the way
    if (!hasStarted && !hasArrived) ...[
      Container(
        width: 60.w,
        height: 60.h,
        decoration: BoxDecoration(
          color: Color(ConstColors.mainColor),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(_driverArrivalTime, ...),
        ),
      ),
      SizedBox(width: 15.w),
    ],
    Expanded(...),
  ],
)
```

## Visibility Logic

| Ride Status | `hasStarted` | `hasArrived` | Timer Visible? |
|-------------|--------------|--------------|----------------|
| **Driver on the way** | `false` | `false` | ✅ **YES** |
| **Driver arrived** | `false` | `true` | ❌ NO |
| **Trip started** | `true` | `false` | ❌ NO |

## User Experience

### Before:
- Timer always shown, even when not relevant
- Confusing when driver already arrived
- Wasted screen space

### After:
- Timer only shown when driver is on the way ✅
- Clean interface when driver arrives
- More space for other content

## Implementation Details

Used Dart's collection spread operator (`...`) with conditional rendering:
```dart
if (!hasStarted && !hasArrived) ...[
  // Widgets to show
],
```

This is equivalent to:
```dart
if (!hasStarted && !hasArrived) 
  Container(...),
  SizedBox(...),
```

But more readable and maintainable.

## Benefits

✅ **Cleaner UI** - Timer only shown when relevant
✅ **Better UX** - Less visual clutter
✅ **Logical** - Timer disappears when no longer needed
✅ **Responsive** - Automatically adjusts based on ride status

## Notes

- The timer still updates in the background (if implemented)
- The condition checks both `hasStarted` and `hasArrived` flags
- The `SizedBox` spacing is also conditionally rendered to maintain proper layout
