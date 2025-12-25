# Call Driver Button Implementation

## Summary
Changed the "Modify Trip" button in the "Driver is on the way" sheet to "Call Driver" and implemented functionality to navigate to the call screen when tapped.

## Changes Made

### 1. **Import Added** (`lib/features/home/presentation/screens/home_screen.dart`)
- Added import for `CallScreen`:
  ```dart
  import 'package:muvam/features/chat/presentation/screens/call_screen.dart';
  ```

### 2. **Button Updated in Driver Accepted Sheet**

#### Before:
- **Icon:** `Icons.edit`
- **Text:** "Modify Trip"
- **Action:** Empty `onTap: () {}`

#### After:
- **Icon:** `Icons.call`
- **Text:** "Call Driver"
- **Action:** Navigates to `CallScreen` with driver information

### 3. **Implementation Details**

The button now has three states based on ride status:

1. **Driver is on the way** (default state):
   - Shows: "Call Driver" with phone icon
   - Action: Opens CallScreen to initiate a call to the driver
   
2. **Driver has arrived** (`hasArrived` = true):
   - Shows: "Cancel" with cancel icon
   - Action: Cancel functionality (placeholder)
   
3. **Trip has started** (`hasStarted` = true):
   - Shows: "SOS" with SOS icon
   - Action: SOS functionality (placeholder)

### 4. **Call Screen Navigation**

When the user taps "Call Driver", the app:
1. Checks if driver and ride information is available
2. Navigates to `CallScreen` with:
   - `driverName`: The assigned driver's name
   - `rideId`: The current active ride ID
   - `sessionId`: Not provided (null) - this initiates a new outgoing call

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => CallScreen(
      driverName: _assignedDriver!.name,
      rideId: _activeRide?['ID'] is int
          ? _activeRide!['ID']
          : int.parse(_activeRide?['ID']?.toString() ?? '0'),
    ),
  ),
);
```

## User Flow

1. **User books a ride** → Ride request sent
2. **Driver accepts** → "Driver is on the way" sheet appears
3. **User sees "Call Driver" button** with phone icon
4. **User taps "Call Driver"**
5. **App navigates to CallScreen** → Initiates voice call to driver
6. **User can talk to driver** using the call interface

## Benefits

- ✅ **Direct Communication**: Users can easily call their driver during the ride
- ✅ **Better UX**: More intuitive than "Modify Trip" for the waiting state
- ✅ **Clear Icon**: Phone icon makes the action obvious
- ✅ **Consistent**: Uses the existing CallScreen infrastructure

## Testing Checklist

- [ ] Test "Call Driver" button appears when driver is on the way
- [ ] Test button navigates to CallScreen with correct driver info
- [ ] Test call initiates successfully
- [ ] Test button changes to "Cancel" when driver arrives
- [ ] Test button changes to "SOS" when trip starts
- [ ] Verify driver name displays correctly in call screen
- [ ] Verify ride ID is passed correctly

## Notes

- The button dynamically changes based on ride status (on the way → arrived → started)
- Only the "on the way" state triggers the call functionality
- The implementation reuses the existing `CallScreen` component
- No `sessionId` is passed, which means this initiates a new outgoing call (not answering an incoming call)
