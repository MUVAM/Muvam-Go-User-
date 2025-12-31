/**
 * Firebase Cloud Function for sending FCM notifications
 * 
 * This function listens for new documents in the 'notifications' collection
 * and sends FCM notifications to the specified user's devices.
 * 
 * Deploy with: firebase deploy --only functions
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp();

/**
 * Send FCM notification when a new notification document is created
 */
exports.sendNotification = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    const notificationId = context.params.notificationId;

    console.log('New notification created:', notificationId, notification);

    // Check if already sent
    if (notification.sent) {
      console.log('Notification already sent, skipping');
      return null;
    }

    const { userId, type, title, body, data } = notification;

    if (!userId || !title || !body) {
      console.error('Missing required fields:', { userId, title, body });
      return null;
    }

    try {
      // Get user's FCM tokens
      const tokensSnapshot = await admin.firestore()
        .collection('users')
        .doc(userId)
        .collection('tokens')
        .get();

      if (tokensSnapshot.empty) {
        console.log('No tokens found for user:', userId);
        await snap.ref.update({ sent: true, error: 'No tokens found' });
        return null;
      }

      const tokens = tokensSnapshot.docs.map(doc => doc.data().token);
      console.log(`Found ${tokens.length} tokens for user ${userId}`);

      // Prepare notification payload
      const payload = {
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: type || 'default',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
          ...data,
        },
        android: {
          priority: 'high',
          notification: {
            channelId: getChannelId(type),
            priority: 'high',
            sound: 'default',
            vibrationPattern: getVibrationPattern(type),
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: title,
                body: body,
              },
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      // Send to all tokens
      const response = await admin.messaging().sendEachForMulticast({
        tokens: tokens,
        ...payload,
      });

      console.log('Notification sent successfully:', response);

      // Handle failed tokens
      if (response.failureCount > 0) {
        const failedTokens = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            failedTokens.push(tokens[idx]);
            console.error('Failed to send to token:', tokens[idx], resp.error);
          }
        });

        // Remove invalid tokens
        const batch = admin.firestore().batch();
        for (const token of failedTokens) {
          const tokenRef = admin.firestore()
            .collection('users')
            .doc(userId)
            .collection('tokens')
            .doc(token);
          batch.delete(tokenRef);
        }
        await batch.commit();
        console.log('Removed invalid tokens:', failedTokens.length);
      }

      // Mark notification as sent
      await snap.ref.update({
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        successCount: response.successCount,
        failureCount: response.failureCount,
      });

      return { success: true, successCount: response.successCount };
    } catch (error) {
      console.error('Error sending notification:', error);
      await snap.ref.update({
        sent: true,
        error: error.message,
      });
      return null;
    }
  });

/**
 * Get Android notification channel ID based on type
 */
function getChannelId(type) {
  switch (type) {
    case 'call':
      return 'calls';
    case 'message':
      return 'messages';
    case 'ride_accepted':
    case 'driver_arrived':
    case 'ride_started':
    case 'ride_completed':
      return 'ride_updates';
    default:
      return 'ride_updates';
  }
}

/**
 * Get vibration pattern based on notification type
 */
function getVibrationPattern(type) {
  switch (type) {
    case 'call':
      return [0, 1000]; // Long vibration
    case 'message':
      return [0, 200, 100, 200]; // Double short vibration
    case 'ride_accepted':
    case 'driver_arrived':
    case 'ride_started':
    case 'ride_completed':
      return [0, 500]; // Medium vibration
    default:
      return [0, 300]; // Default short vibration
  }
}

/**
 * Clean up old notifications (optional - run daily)
 */
exports.cleanupOldNotifications = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - 7); // Keep last 7 days

    const snapshot = await admin.firestore()
      .collection('notifications')
      .where('createdAt', '<', cutoffDate)
      .get();

    if (snapshot.empty) {
      console.log('No old notifications to delete');
      return null;
    }

    const batch = admin.firestore().batch();
    snapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`Deleted ${snapshot.size} old notifications`);
    return null;
  });
