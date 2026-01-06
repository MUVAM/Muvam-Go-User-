# Scheduled Ride Implementation

## Summary
Implemented scheduled ride booking functionality that allows users to pre-book rides with a specific date and time. The system now sends `scheduled` (bool) and `scheduled_at` (DateTime) parameters with the ride request, and displays the user's actual selections in the Trip Scheduled confirmation sheet.

## Changes Made

### 1. **RideRequest Model** (`lib/features/home/data/models/ride_models.dart`)
- ✅ Already had `scheduled` and `scheduledAt` fields defined
- ✅ Already included in `toJson()` method with conditional inclusion

### 2. **RideService** (`lib/core/services/ride_service.dart`)
- ✅ No changes needed - already handles the scheduled parameters in the request

### 3. **HomeScreen** (`lib/features/home/presentation/screens/home_screen.dart`)

#### Modified `_requestRide()` Method
- **Added Parameters:**
  - `isScheduled` (bool, default: false)
  - `scheduledDateTime` (DateTime?, optional)
  
- **Updated Logic:**
  - Logs scheduled ride information when `isScheduled` is true
  - Passes `scheduled` and `scheduledAt` to `RideRequest` constructor
  - Converts `scheduledDateTime` to ISO 8601 string format for API

#### Updated Prebook Sheet (`_showPrebookSheet()`)
- **Modified "Set pick date and time" Button:**
  - Combines `selectedDate` and `selectedTime` into a single `DateTime` object
  - Calls `_requestRide()` with:
    - `isScheduled: true`
    - `scheduledDateTime: <combined DateTime>`

#### Updated Trip Scheduled Sheet (`_showTripScheduledSheet()`)
- **Now Displays Actual User Data:**
  - **Pickup Address:** Uses `fromController.text` (or "Current location" as fallback)
  - **Destination Address:** Uses `toController.text` (or "Destination" as fallback)
  - **Scheduled Date/Time:** Formats the selected date and time (e.g., "December 25, 2025 at 08:45 PM")
  - **Payment Method:** Shows the actual selected payment method
  - **Vehicle Type:** Shows the selected vehicle option
  - **Price:** Displays the actual estimated price from `_currentEstimate`

## Data Flow

1. **User selects ride details:**
   - Pickup location
   - Destination location
   - Vehicle type
   - Payment method

2. **User clicks "Book Later":**
   - Opens prebook sheet
   - User selects date and time

3. **User clicks "Set pick date and time":**
   - Combines date and time into `DateTime` object
   - Calls `_requestRide(isScheduled: true, scheduledDateTime: <DateTime>)`

4. **RideRequest is created with:**
   ```dart
   RideRequest(
     // ... other fields
     scheduled: true,
     scheduledAt: "2025-12-25T20:45:00.000Z", // ISO 8601 format
   )
   ```

5. **API Request sent to backend:**
   ```json
   {
     "pickup": "POINT(...)",
     "dest": "POINT(...)",
     "pickup_address": "User's pickup location",
     "dest_address": "User's destination",
     "service_type": "ride",
     "vehicle_type": "regular",
     "payment_method": "in_car",
     "scheduled": true,
     "scheduled_at": "2025-12-25T20:45:00.000Z"
   }
   ```

6. **Trip Scheduled Sheet displays:**
   - All the user's actual selections
   - Formatted scheduled date and time
   - Actual price estimate

## Testing Checklist

- [ ] Test booking a scheduled ride with different dates
- [ ] Test booking a scheduled ride with different times
- [ ] Verify the scheduled parameters are sent to the backend
- [ ] Verify the Trip Scheduled sheet shows correct user data
- [ ] Test with different vehicle types
- [ ] Test with different payment methods
- [ ] Verify the date/time formatting is correct
- [ ] Test edge cases (same day booking, far future dates, etc.)

## Notes

- The `scheduled` field is only included in the API request when `isScheduled` is true
- The `scheduledAt` field uses ISO 8601 format for consistency with backend expectations
- All user-selected data is now dynamically displayed instead of hardcoded values
- The implementation maintains backward compatibility with immediate ride bookings
