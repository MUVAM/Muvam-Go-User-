# Push Notifications Setup

## Setup Steps

### 1. Place Service Account File
- Put your `firebase-service-account.json` file in the `assets/` folder
- Path: `assets/firebase-service-account.json`

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Usage

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

## How It Works

- Uses OAuth2 service account authentication (same as your WorkPal app)
- Sends notifications directly via FCM HTTP v1 API
- Automatically handles invalid tokens
- Includes vibration for all notifications
- No Cloud Functions required

## Notification Channels

- **calls** - For incoming calls (MAX priority)
- **messages** - For chat messages (HIGH priority)
- **ride_updates** - For ride status updates (HIGH priority)
