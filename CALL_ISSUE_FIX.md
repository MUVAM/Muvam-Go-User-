# Call Issue Fix Documentation

## Problem
Incoming calls were not visible to both driver and passenger because:

1. **Duplicate Call Handlers**: Multiple call handlers were being set up in different places, causing conflicts
2. **Handler Overwriting**: The WebSocket service's `onIncomingCall` handler was being overwritten
3. **Initialization Order**: WebSocket was connecting before call handlers were properly set up

## Solution Applied

### 1. Fixed Main App Setup (`main.dart`)
- Enhanced global call handler with proper logging
- Ensured call service initialization before answering/rejecting calls
- Added comprehensive logging for debugging

### 2. Removed Duplicate Handlers (`home_screen.dart`)
- Removed duplicate call handler setup in `_initializeCallService()`
- The global handler in `main.dart` now handles all incoming calls
- Fixed initialization order: call service → WebSocket connection → message listeners

### 3. Improved WebSocket Message Handling (`websocket_service.dart`)
- Enhanced logging for call-related messages
- Added detailed debugging information
- Better error reporting when handlers are missing

### 4. Fixed Initialization Order
- Call service initializes first
- WebSocket connects after handlers are set up
- Message listeners are configured after connection

## Key Changes Made

1. **main.dart**: Enhanced `_setupGlobalCallHandler()` with proper initialization and logging
2. **home_screen.dart**: 
   - Removed duplicate call handler in `_initializeCallService()`
   - Fixed initialization order in `initState()`
   - Improved WebSocket listener setup
3. **websocket_service.dart**: Enhanced `_handleMessage()` with better call message logging

## Testing the Fix

1. **Driver Side**: When driver initiates a call, passenger should see the incoming call overlay
2. **Passenger Side**: When passenger receives a call, the global call handler should trigger
3. **Logs**: Check console for detailed call flow logging with tags like `MAIN_APP`, `PASSENGER_CALL`, `HOME_WEBSOCKET`

## Expected Behavior After Fix

1. ✅ Driver calls passenger → Passenger sees incoming call overlay
2. ✅ Passenger calls driver → Driver sees incoming call notification  
3. ✅ Proper call state management (ringing, connected, ended)
4. ✅ No duplicate handlers or conflicts
5. ✅ Comprehensive logging for debugging

## Debug Commands

To verify the fix is working:

```dart
// Check if handlers are properly set up
AppLogger.log('WebSocket onIncomingCall handler: ${_webSocketService.onIncomingCall != null}');

// Monitor call flow in logs
AppLogger.log('Call handler status check', tag: 'CALL_DEBUG');
```

The fix ensures a single, reliable call handling flow through the global handler in `main.dart`.