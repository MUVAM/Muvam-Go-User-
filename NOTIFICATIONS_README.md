# 🔔 Push Notifications - Complete Implementation

## 📋 Table of Contents
1. [Overview](#overview)
2. [What's Implemented](#whats-implemented)
3. [Quick Start](#quick-start)
4. [Detailed Setup](#detailed-setup)
5. [Usage Examples](#usage-examples)
6. [Testing](#testing)
7. [Troubleshooting](#troubleshooting)

## Overview

Complete push notification system for Muvam using Firebase Cloud Messaging (FCM) with support for:
- ✅ Ride status updates (accepted, arrived, started, completed)
- ✅ New messages
- ✅ Incoming calls
- ✅ Device vibration for all notifications
- ✅ iOS and Android support
- ✅ Automatic token management
- ✅ Background and foreground notifications

## What's Implemented

### ✅ Flutter Code
- **FCMNotificationService**: Complete FCM integration with token management
- **NotificationHelper**: Helper methods for all notification types
- **Main.dart**: Firebase initialization and FCM setup
- **AuthService**: FCM token cleanup on logout
- **Dependencies**: All required packages added to pubspec.yaml

### ✅ Android Configuration
- Permissions added (POST_NOTIFICATIONS, VIBRATE)
- Google Services plugin configured
- Firebase dependencies added
- Notification channels created

### ✅ Token Management
- Automatic token generation on app start
- Tokens saved to Firestore: `users/{userId}/tokens/{token}`
- Automatic token refresh
- Token deletion on logout

### ✅ Notification Features
- Foreground notifications with local display
- Background notifications
- Custom vibration patterns per notification type
- Notification channels for Android
- Tap handling with navigation support

## Quick Start

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Create Service Account File
Create `firebase-service-account.json` in project root with the credentials provided.

⚠️ **This file is gitignored - DO NOT commit it!**

### 3. Run the App
```bash
flutter run
```

The FCM token will be automatically generated and saved to Firestore.

## Detailed Setup

### Step 1: Firebase Configuration

#### Android (Already Done ✅)
- `google-services.json` is already in `android/app/`
- Google Services plugin is configured
- Firebase dependencies are added

#### iOS (If Supporting iOS)
1. Download `GoogleService-Info.plist` from Firebase Console
2. Add to `ios/Runner/` directory
3. Add to Xcode project
4. Update `ios/Runner/Info.plist`:
```xml
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

5. Update `ios/Runner/AppDelegate.swift`:
```swift
import UIKit
import Flutter
import Firebase
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### Step 2: Deploy Cloud Functions

1. **Install Firebase CLI**:
```bash
npm install -g firebase-tools
firebase login
```

2. **Initialize Functions**:
```bash
cd c:\WORK_NEW\muvam
firebase init functions
```
- Select JavaScript or TypeScript
- Install dependencies

3. **Copy Function Code**:
Copy the code from `CLOUD_FUNCTION_TEMPLATE.js` to `functions/index.js`

4. **Install Dependencies**:
```bash
cd functions
npm install firebase-admin firebase-functions
```

5. **Deploy**:
```bash
firebase deploy --only functions
```

### Step 3: Firestore Security Rules

Add these rules to allow notification creation:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to manage their own tokens
    match /users/{userId}/tokens/{token} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow authenticated users to create notifications
    match /notifications/{notificationId} {
      allow create: if request.auth != null;
      allow read, update: if request.auth != null;
    }
  }
}
```

## Usage Examples

### From Your Backend/API

When you want to send a notification, create a document in Firestore:

```javascript
// Example: Ride accepted
await db.collection('notifications').add({
  userId: 'user123',
  type: 'ride_accepted',
  title: 'Ride Accepted! 🚗',
  body: 'John has accepted your ride request',
  data: {
    rideId: 'ride456',
    driverName: 'John',
    screen: 'ride_details'
  },
  createdAt: admin.firestore.FieldValue.serverTimestamp(),
  sent: false
});
```

### From Flutter App

Use the `NotificationHelper` class:

```dart
import 'package:muvam/core/services/notification_helper.dart';

// Ride accepted
await NotificationHelper().sendRideAcceptedNotification(
  userId: 'user123',
  driverName: 'John Doe',
  rideId: 'ride456',
);

// Driver arrived
await NotificationHelper().sendDriverArrivedNotification(
  userId: 'user123',
  driverName: 'John Doe',
  rideId: 'ride456',
);

// Ride started
await NotificationHelper().sendRideStartedNotification(
  userId: 'user123',
  driverName: 'John Doe',
  rideId: 'ride456',
);

// Ride completed
await NotificationHelper().sendRideCompletedNotification(
  userId: 'user123',
  driverName: 'John Doe',
  rideId: 'ride456',
  fare: 25.50,
);

// New message
await NotificationHelper().sendNewMessageNotification(
  userId: 'user123',
  senderName: 'John Doe',
  message: 'I am on my way!',
  chatId: 'chat789',
);

// Incoming call
await NotificationHelper().sendIncomingCallNotification(
  userId: 'user123',
  callerName: 'John Doe',
  sessionId: 'session123',
  rideId: 'ride456',
);
```

## Notification Types & Vibration Patterns

| Type | Vibration Pattern | Channel | Priority |
|------|------------------|---------|----------|
| Incoming Call | 1000ms long | calls | MAX |
| New Message | 200ms, 100ms pause, 200ms | messages | HIGH |
| Ride Accepted | 500ms medium | ride_updates | HIGH |
| Driver Arrived | 500ms medium | ride_updates | HIGH |
| Ride Started | 500ms medium | ride_updates | HIGH |
| Ride Completed | 500ms medium | ride_updates | HIGH |
| Default | 300ms short | ride_updates | HIGH |

## Testing

### Test 1: Verify FCM Token Generation
1. Run the app
2. Check logs for:
   ```
   FCM Token: <your-token>
   Token saved to Firestore for user: <user-id>
   ```
3. Verify in Firestore Console:
   - Navigate to `users/{userId}/tokens`
   - You should see a document with your FCM token

### Test 2: Send Test Notification from Firebase Console
1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Enter title and body
4. Select your app
5. Send test message

### Test 3: Send Notification via Firestore
1. Go to Firestore Console
2. Create a document in `notifications` collection:
```json
{
  "userId": "your-user-id",
  "type": "ride_accepted",
  "title": "Test Notification",
  "body": "This is a test",
  "data": {
    "rideId": "test123"
  },
  "sent": false,
  "createdAt": "2024-01-01T00:00:00Z"
}
```
3. The Cloud Function will automatically send it
4. Check your device for notification and vibration

### Test 4: Test All Notification Types
```dart
// In your test code
final helper = NotificationHelper();
final userId = 'your-user-id';

// Test ride accepted
await helper.sendRideAcceptedNotification(
  userId: userId,
  driverName: 'Test Driver',
  rideId: 'test123',
);

// Wait a few seconds between each test
await Future.delayed(Duration(seconds: 3));

// Test driver arrived
await helper.sendDriverArrivedNotification(
  userId: userId,
  driverName: 'Test Driver',
  rideId: 'test123',
);

// Continue for other types...
```

## Troubleshooting

### Issue: No FCM Token Generated
**Possible Causes:**
- Firebase not initialized
- Notification permissions not granted
- `google-services.json` missing or incorrect

**Solutions:**
1. Check logs for Firebase initialization: `Firebase initialized`
2. Request notification permissions manually
3. Verify `google-services.json` is in `android/app/`
4. Run `flutter clean && flutter pub get`

### Issue: Notifications Not Received
**Possible Causes:**
- Cloud Function not deployed
- Firestore rules blocking writes
- No valid tokens in Firestore
- App in background without notification permission

**Solutions:**
1. Verify Cloud Function is deployed: `firebase functions:list`
2. Check Firestore rules allow writing to `notifications`
3. Verify tokens exist in `users/{userId}/tokens`
4. Check notification permissions in device settings

### Issue: No Vibration
**Possible Causes:**
- Testing on emulator
- Device vibration disabled
- Missing VIBRATE permission

**Solutions:**
1. Test on physical device
2. Check device settings for vibration
3. Verify `VIBRATE` permission in AndroidManifest.xml

### Issue: iOS Notifications Not Working
**Possible Causes:**
- APNs certificate not configured
- `GoogleService-Info.plist` missing
- Notification permissions not granted

**Solutions:**
1. Configure APNs certificate in Firebase Console
2. Add `GoogleService-Info.plist` to Xcode project
3. Request notification permissions
4. Check iOS device notification settings

### Issue: Background Notifications Not Working
**Possible Causes:**
- Background handler not registered
- App killed by system
- Battery optimization enabled

**Solutions:**
1. Verify `FirebaseMessaging.onBackgroundMessage` is registered in `main()`
2. Disable battery optimization for the app
3. Check device background app settings

## Security Best Practices

### ⚠️ NEVER Commit These Files:
- `firebase-service-account.json`
- `android/app/google-services.json` (if it contains sensitive data)
- `ios/Runner/GoogleService-Info.plist`

These files are already in `.gitignore`.

### 🔒 Firestore Security:
- Always validate user authentication
- Only allow users to write their own tokens
- Implement rate limiting for notification creation

### 🔑 API Keys:
- Use environment variables for sensitive data
- Rotate keys regularly
- Monitor Firebase usage for anomalies

## Next Steps

### 1. Implement Navigation Handling
Update `_handleNotificationTap` in `fcm_notification_service.dart`:

```dart
void _handleNotificationTap(RemoteMessage message) {
  final data = message.data;
  final screen = data['screen'];
  
  switch (screen) {
    case 'ride_details':
      // Navigate to ride details
      MyApp.navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => RideDetailsScreen(
            rideId: data['rideId'],
          ),
        ),
      );
      break;
    case 'chat':
      // Navigate to chat
      MyApp.navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: data['chatId'],
          ),
        ),
      );
      break;
    // Add more cases as needed
  }
}
```

### 2. Add Analytics
Track notification events:
```dart
await FirebaseAnalytics.instance.logEvent(
  name: 'notification_received',
  parameters: {
    'type': type,
    'userId': userId,
  },
);
```

### 3. Add Notification Badges
Update badge count when notifications are received.

### 4. Implement Notification History
Store received notifications locally for user reference.

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review Firebase Console logs
3. Check Cloud Function logs: `firebase functions:log`
4. Verify Firestore data structure

## Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Firebase Cloud Functions](https://firebase.google.com/docs/functions)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
