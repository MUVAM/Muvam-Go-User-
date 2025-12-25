# Call Premature Ending Fix

## Problem
When initiating a call, the call status would immediately change to "Call ended" before the driver's phone even started ringing. This created a poor user experience where calls appeared to fail instantly.

## Root Cause
The issue was in the Agora `onUserOffline` event handler in `CallService`. The handler was triggering "Call ended" status whenever ANY user went offline, even during the initial ringing phase when no one had connected yet.

### Call Flow Issue:
```
1. User initiates call
2. User joins Agora channel immediately
3. Driver hasn't joined yet (still ringing)
4. Agora triggers onUserOffline (no other users in channel)
5. ❌ Status changes to "Call ended" prematurely
```

## Solution
Added a `_wasConnected` flag to track whether users were actually connected before triggering "Call ended" status.

### New Call Flow:
```
1. User initiates call
2. _wasConnected = false (reset)
3. User joins Agora channel
4. Status stays "Ringing..."
5. Driver joins channel
6. _wasConnected = true (users connected)
7. onUserJoined triggers "Connected" status
8. If driver leaves: onUserOffline checks _wasConnected
9. ✅ Only shows "Call ended" if _wasConnected == true
```

## Changes Made

### **CallService** (`lib/core/services/call_service.dart`)

#### 1. Added `_wasConnected` Flag
```dart
bool _wasConnected = false; // Track if call was ever connected
```

#### 2. Updated `onUserJoined` Handler
```dart
onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
  AppLogger.log("👤 Agora: User joined $remoteUid", tag: 'CALL');
  stopRingtone();
  _wasConnected = true; // Mark that we had a connection ✅
  onCallStateChanged?.call("Connected");
},
```

#### 3. Updated `onUserOffline` Handler
**Before:**
```dart
onUserOffline: (...) {
  AppLogger.log("👋 Agora: User offline $remoteUid", tag: 'CALL');
  onCallStateChanged?.call("Call ended"); // ❌ Always ended
},
```

**After:**
```dart
onUserOffline: (...) {
  AppLogger.log("👋 Agora: User offline $remoteUid (Reason: $reason)", tag: 'CALL');
  // Only trigger "Call ended" if we were actually connected
  if (_wasConnected) {
    AppLogger.log("📞 Call ending - user was connected before", tag: 'CALL');
    onCallStateChanged?.call("Call ended");
  } else {
    AppLogger.log("⏭️ Ignoring user offline - never connected", tag: 'CALL');
  }
},
```

#### 4. Reset Flag on New Calls

**In `initiateCall()`:**
```dart
Future<Map<String, dynamic>> initiateCall(int rideId) async {
  _rideId = rideId;
  _wasConnected = false; // Reset connection state for new call ✅
  // ... rest of code
}
```

**In `answerCall()`:**
```dart
Future<void> answerCall(int sessionId, int rideId) async {
  _currentSessionId = sessionId;
  _rideId = rideId;
  _wasConnected = false; // Reset connection state for new call ✅
  // ... rest of code
}
```

#### 5. Removed Premature State Change
**In `onJoinChannelSuccess`:**
```dart
onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
  AppLogger.log("✅ Agora: Joined channel ${connection.channelId}", tag: 'CALL');
  _isJoined = true;
  // Don't change state here - keep it as "Ringing..." until other user joins ✅
},
```

## State Flow Diagram

### Before Fix:
```
Initiate Call
     ↓
Join Channel
     ↓
onJoinChannelSuccess
     ↓
Status: "Connecting..."
     ↓
onUserOffline (no users yet)
     ↓
❌ Status: "Call ended"
(Driver never got a chance to answer!)
```

### After Fix:
```
Initiate Call
     ↓
_wasConnected = false
     ↓
Join Channel
     ↓
onJoinChannelSuccess
     ↓
Status: "Ringing..." (waiting)
     ↓
Driver Answers & Joins
     ↓
onUserJoined
     ↓
_wasConnected = true
     ↓
Status: "Connected"
     ↓
(Later) Driver Leaves
     ↓
onUserOffline
     ↓
Check: _wasConnected == true?
     ↓
✅ Status: "Call ended"
```

## Benefits

✅ **Proper Ringing State**: Call stays in "Ringing..." until driver answers
✅ **No False Endings**: "Call ended" only shows when actually appropriate
✅ **Better UX**: Users see accurate call status throughout
✅ **Robust Logic**: Handles edge cases like network issues during ringing

## Call States

| State | When It Appears | User Action |
|-------|----------------|-------------|
| **Ringing...** | After initiating call, before driver answers | Wait for driver |
| **Connected** | When driver joins the call | Talk to driver |
| **Call ended** | When driver hangs up (after being connected) | Call finished |

## Edge Cases Handled

1. **Driver Never Answers**: Call stays in "Ringing..." (can add timeout later)
2. **Network Issues During Ring**: No false "Call ended"
3. **Multiple Users**: Only tracks if ANY user connected
4. **Rapid Reconnects**: Flag resets for each new call

## Testing Checklist

- [ ] Initiate call - verify status shows "Ringing..."
- [ ] Wait for driver to answer - verify status changes to "Connected"
- [ ] Driver hangs up - verify status changes to "Call ended"
- [ ] Initiate call but driver doesn't answer - verify stays "Ringing..."
- [ ] Network drops during ringing - verify doesn't show "Call ended"
- [ ] Answer incoming call - verify proper state flow
- [ ] Multiple rapid calls - verify flag resets properly

## Logging

The fix includes detailed logging for debugging:

```dart
// When user joins:
"👤 Agora: User joined $remoteUid"

// When user goes offline:
"👋 Agora: User offline $remoteUid (Reason: $reason)"

// If ending call (was connected):
"📞 Call ending - user was connected before"

// If ignoring (never connected):
"⏭️ Ignoring user offline - never connected"
```

## Future Enhancements

Potential improvements:
- Add call timeout (e.g., 60 seconds of ringing)
- Add "No answer" state if driver doesn't pick up
- Track connection quality metrics
- Add reconnection logic for dropped calls
- Implement call waiting/hold features

## Notes

- The `_wasConnected` flag is reset at the start of each new call
- The flag is set to `true` only when `onUserJoined` is triggered
- This ensures "Call ended" only appears after an actual connection
- The fix maintains backward compatibility with existing call flows
