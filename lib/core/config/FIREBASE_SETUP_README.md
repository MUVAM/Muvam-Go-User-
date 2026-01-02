# Firebase Service Account Setup

## ⚠️ SECURITY WARNING
This file contains sensitive Firebase service account credentials. **NEVER commit this file to version control!**

## Setup Instructions

### 1. Get Your Firebase Service Account Credentials

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **muvam-go**
3. Click the gear icon ⚙️ → **Project settings**
4. Go to the **Service accounts** tab
5. Click **Generate new private key**
6. Download the JSON file

### 2. Update the Dart File

Open `lib/core/config/firebase_service_account.dart` and replace the placeholder values with your actual credentials from the downloaded JSON file:

```dart
static const Map<String, dynamic> credentials = {
  "type": "service_account",
  "project_id": "muvam-go",  // Should already be correct
  "private_key_id": "abc123...",  // Copy from JSON
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----\n",  // Copy from JSON
  "client_email": "firebase-adminsdk-xxxxx@muvam-go.iam.gserviceaccount.com",  // Copy from JSON
  "client_id": "123456789...",  // Copy from JSON
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/...",  // Copy from JSON
  "universe_domain": "googleapis.com"
};
```

### 3. Important Notes

- **The private_key must include the newline characters (`\n`)**
- Keep the `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----` markers
- The file is already in `.gitignore` so it won't be committed

### 4. Verify Setup

Run your app and check the logs. You should see:
```
✅ CONFIG DEBUG: Service account config loaded and cached
🔑 CONFIG DEBUG: Project ID: muvam-go
🔑 CONFIG DEBUG: Client Email: firebase-adminsdk-xxxxx@muvam-go.iam.gserviceaccount.com
```

If you see an error about placeholder values, you haven't updated the credentials yet.

## Before Pushing to Git

The file `firebase_service_account.dart` is already in `.gitignore`, so it won't be committed. However, **always double-check** before pushing:

```bash
git status
```

Make sure `lib/core/config/firebase_service_account.dart` is NOT listed in the changes.

## Security Reminder

⚠️ **CRITICAL**: These credentials give **FULL ACCESS** to your Firebase project. Anyone with these credentials can:
- Read/write/delete all Firestore data
- Send unlimited FCM notifications
- Access all Firebase services
- Potentially rack up large bills

**Keep them secure!**
