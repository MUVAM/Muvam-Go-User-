# Token Handling Update Summary

## Overview
Updated the authentication system to handle the new token response format from the `/verify-otp` endpoint.

## New API Response Format
```json
{
    "isNew": false,
    "message": "Phone number verified successfully",
    "token": {
        "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        "expires_in": 3600
    },
    "user": {
        "ID": 2,
        "first_name": "Chukwuebuka",
        "last_name": "Driver",
        "Email": "driver@gmail.com",
        ...
    }
}
```

## Changes Made

### 1. Auth Models (`auth_models.dart`)
- **Added `TokenData` class** to represent the nested token object:
  - `accessToken`: The JWT access token
  - `refreshToken`: The JWT refresh token for obtaining new access tokens
  - `expiresIn`: Token validity duration in seconds (e.g., 3600 = 1 hour)

- **Updated `VerifyOtpResponse`**:
  - Changed `token` field from `String?` to `TokenData?`
  - Updated `fromJson` factory to parse the nested token object

### 2. Auth Service (`auth_service.dart`)
- **Added new constants**:
  - `_refreshTokenKey`: For storing the refresh token
  - `_tokenExpiryKey`: For storing the token expiry timestamp

- **Added `_saveTokenData()` method**:
  - Saves access token, refresh token, and calculates expiry time
  - Converts `expires_in` (seconds) to absolute expiry timestamp
  - Logs all saved token information

- **Updated `verifyOtp()` method**:
  - Now calls `_saveTokenData()` instead of `_saveToken()`
  - Also saves user email to SharedPreferences

- **Enhanced `getToken()` method**:
  - Checks new token format with expiry time first
  - Falls back to legacy token format with timestamp for backward compatibility
  - Returns null if token is expired
  - Logs remaining token validity time

- **Added `getRefreshToken()` method**:
  - Retrieves the stored refresh token
  - Can be used to implement token refresh logic in the future

- **Updated `clearToken()` method**:
  - Now clears all token-related data (access token, refresh token, expiry time, and legacy timestamp)

- **Kept `_saveToken()` for backward compatibility**:
  - Still used by `registerUser()` method
  - Maintains legacy timestamp-based expiry

## User Data Storage
The following user data is now stored in SharedPreferences after successful OTP verification:
- `user_id`: User's ID from the database
- `user_name`: Full name (first_name + last_name)
- `user_email`: User's email address

## Token Expiry Logic
- **New format**: Uses the exact `expires_in` value from the API (typically 3600 seconds = 1 hour)
- **Legacy format**: Uses hardcoded 2-hour expiry for backward compatibility
- Token is automatically cleared when expired

## Backward Compatibility
The implementation maintains backward compatibility:
- Services using `getToken()` continue to work without changes
- Legacy tokens (from registration) still work with timestamp-based expiry
- New tokens use the more accurate expiry time from the API

## Future Enhancements
Consider implementing:
1. **Token Refresh**: Use the `getRefreshToken()` method to automatically refresh expired access tokens
2. **Automatic Retry**: Retry failed API calls after refreshing the token
3. **Token Refresh Endpoint**: Add support for the token refresh API endpoint
