# Push Notification Implementation Guide

## Overview
This guide explains how to complete the push notification setup for your Muvam app.

## What's Already Done ✅

1. **Flutter Dependencies Added**:
   - `firebase_core`
   - `firebase_messaging`
   - `cloud_firestore`
   - `flutter_local_notifications`
   - `vibration`

2. **Services Created**:
   - `FCMNotificationService`: Handles FCM initialization, token management, and notification display
   - `NotificationHelper`: Provides methods for all notification use cases

3. **Android Configuration**:
   - Permissions added (POST_NOTIFICATIONS, VIBRATE)
   - Google Services plugin configured
   - Firebase dependencies added

4. **Main.dart Updated**:
   - Firebase initialized
   - FCM background handler registered
   - FCM service initialized on app start

5. **Token Management**:
   - FCM tokens automatically saved to Firestore at `users/{userId}/tokens/{token}`
   - Tokens refresh automatically
   - Tokens deleted on logout

## What You Need to Do 🔧

### 1. Install Dependencies
```bash
cd c:\WORK_NEW\muvam
flutter pub get
```

### 2. Create Firebase Service Account File
Create a file named `firebase-service-account.json` in the project root with the service account credentials provided.

**Location**: `c:\WORK_NEW\muvam\firebase-service-account.json`

⚠️ **IMPORTANT**: This file is already in `.gitignore` and will NOT be committed to Git.

### 3. iOS Configuration (if supporting iOS)

#### a. Add GoogleService-Info.plist
1. Download `GoogleService-Info.plist` from Firebase Console
2. Place it in `ios/Runner/`
3. Add it to Xcode project

#### b. Update Info.plist
Add to `ios/Runner/Info.plist`:
```xml
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

#### c. Update AppDelegate.swift
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

### 4. Deploy Cloud Functions

You need to deploy a Cloud Function to send FCM notifications. Here's the structure:

#### a. Install Firebase CLI
```bash
npm install -g firebase-tools
firebase login
```

#### b. Initialize Functions
```bash
cd c:\WORK_NEW\muvam
firebase init functions
```

#### c. Deploy the Function
See `CLOUD_FUNCTION_TEMPLATE.js` for the function code, then:
```bash
firebase deploy --only functions
```

### 5. Update AuthProvider to Save User ID

Ensure that when a user logs in, their user ID is saved to SharedPreferences:

```dart
final prefs = await SharedPreferences.getInstance();
await prefs.setString('user_id', userId);
```

This is required for token management.

### 6. Update Logout to Delete Token

In your logout method, add:
```dart
await FCMNotificationService().deleteToken();
```

## How to Use Notifications

### From Your Backend/Server

When you want to send a notification, create a document in Firestore:

```javascript
// Example: Send ride accepted notification
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

The Cloud Function will automatically:
1. Detect the new notification
2. Get the user's FCM tokens
3. Send the notification to all user's devices
4. Mark the notification as sent

### From Flutter App

Use the `NotificationHelper`:

```dart
// Ride accepted
await NotificationHelper().sendRideAcceptedNotification(
  userId: 'user123',
  driverName: 'John',
  rideId: 'ride456',
);

// Driver arrived
await NotificationHelper().sendDriverArrivedNotification(
  userId: 'user123',
  driverName: 'John',
  rideId: 'ride456',
);

// New message
await NotificationHelper().sendNewMessageNotification(
  userId: 'user123',
  senderName: 'John',
  message: 'I am on my way',
  chatId: 'chat789',
);
```

## Notification Types & Vibration Patterns

Each notification type has a unique vibration pattern:

- **Incoming Call**: Long vibration (1000ms)
- **New Message**: Double short vibration (200ms, 100ms pause, 200ms)
- **Ride Updates**: Medium vibration (500ms)
- **Default**: Short vibration (300ms)

## Testing

### Test FCM Token Generation
1. Run the app
2. Check logs for: `FCM Token: ...`
3. Verify token is saved in Firestore at `users/{userId}/tokens/{token}`

### Test Notifications
1. Send a test notification from Firebase Console
2. Or create a test document in Firestore `notifications` collection
3. Verify notification appears and device vibrates

## Troubleshooting

### No FCM Token Generated
- Check Firebase is initialized in `main()`
- Check notification permissions are granted
- Check `google-services.json` is present

### Notifications Not Received
- Verify Cloud Function is deployed
- Check Firestore rules allow writing to `notifications` collection
- Verify user has valid tokens in Firestore

### No Vibration
- Check `VIBRATE` permission in AndroidManifest.xml
- Test on physical device (emulator may not vibrate)

### iOS Notifications Not Working
- Verify APNs certificate is configured in Firebase Console
- Check `GoogleService-Info.plist` is added to Xcode project
- Ensure app has notification permissions

## Security Notes

⚠️ **NEVER commit these files to Git**:
- `firebase-service-account.json`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

These files are already in `.gitignore`.

## Next Steps

1. Run `flutter pub get`
2. Create the service account file
3. Deploy Cloud Functions
4. Test notifications
5. Integrate notification handling into your app's navigation

For navigation handling, update the `_handleNotificationTap` method in `fcm_notification_service.dart` to navigate to the appropriate screens based on notification data.
