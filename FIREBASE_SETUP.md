# Firebase Service Account Setup

## IMPORTANT: Do NOT commit the service account file to Git!

### Setup Instructions:

1. Create a file named `firebase-service-account.json` in the root directory of the project
2. Copy the Firebase service account JSON content that was provided to you
3. This file is already in `.gitignore` and will not be committed to version control

### File Location:
```
muvam/
├── firebase-service-account.json  <-- Create this file here
├── lib/
├── android/
└── ios/
```

### File Content:
The file should contain your Firebase service account credentials in JSON format.

**Note**: This file is critical for server-side operations but should NEVER be committed to Git for security reasons.
