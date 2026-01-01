# Fix GitHub Push Protection - Secret Removal Guide

## Problem
GitHub detected Google Cloud Service Account credentials hardcoded in `lib/core/services/firebase_config_service.dart` and blocked your push.

## Solution Implemented
I've moved the credentials to a separate JSON file and added it to `.gitignore` so it won't be committed.

## Files Changed

### 1. Created: `lib/core/config/firebase_service_account.json`
- Contains your Firebase service account credentials
- **This file is now gitignored and won't be pushed to GitHub**

### 2. Updated: `.gitignore`
- Added `lib/core/config/firebase_service_account.json` to the ignore list

### 3. Updated: `lib/core/services/firebase_config_service.dart`
- Removed hardcoded credentials
- Now loads credentials from the JSON file instead

## Steps to Fix the Git Issue

### Step 1: Remove the file from git cache
Run this command to unstage the file with secrets:
```bash
git rm --cached lib/core/services/firebase_config_service.dart
```

### Step 2: Add the updated files
```bash
git add .gitignore
git add lib/core/services/firebase_config_service.dart
git add lib/core/config/
git add lib/features/auth/data/models/auth_models.dart
git add lib/core/services/auth_service.dart
```

### Step 3: Commit the changes
```bash
git commit -m "refactor: move Firebase credentials to gitignored file and update token handling"
```

### Step 4: Push to your branch
```bash
git push origin callfix
```

## Important Notes

### For Team Members
When other developers clone the repository, they will need to:
1. Create `lib/core/config/firebase_service_account.json`
2. Add the Firebase service account credentials to it
3. The file structure should match the JSON format in the file

### For Production/Deployment
- The `firebase_service_account.json` file should be added to your deployment environment
- Consider using environment variables or secret management services for production
- The code tries to load from assets first, then falls back to file system

### Backup
Your credentials are safely stored in:
- `lib/core/config/firebase_service_account.json` (local only, not in git)
- Firestore `Admin/Admin` document (if configured)

## Alternative: If You Still Can't Push

If GitHub still blocks the push because the secrets are in the commit history:

### Option 1: Rewrite commit history (if the commit hasn't been pushed yet)
```bash
git reset --soft HEAD~1
git add .
git commit -m "refactor: move Firebase credentials to gitignored file and update token handling"
git push origin callfix
```

### Option 2: Use GitHub's secret bypass URL
GitHub provided URLs to allow the secrets (use with caution):
- https://github.com/MUVAM/Muvam-Go-User-/security/secret-scanning/unblock-secret/37dMjLaeSNquA81OQNFWblOIqXb
- https://github.com/MUVAM/Muvam-Go-User-/security/secret-scanning/unblock-secret/37dMjIjbBFNInlbEVncInLz0xDb

**Note:** Using the bypass is NOT recommended as it leaves secrets in your git history.

### Option 3: Create a new branch without the secrets
```bash
# Create a new branch from the previous commit (before the secrets were added)
git checkout -b callfix-clean HEAD~1

# Cherry-pick the changes without the secrets
git add .gitignore
git add lib/core/services/firebase_config_service.dart
git add lib/features/auth/data/models/auth_models.dart
git add lib/core/services/auth_service.dart
git commit -m "refactor: move Firebase credentials to gitignored file and update token handling"

# Push the new branch
git push origin callfix-clean

# Delete the old branch (optional)
git push origin --delete callfix
```

## Summary of Changes

### Token Handling Updates
- Updated `auth_models.dart` to handle new token response format with `access_token`, `refresh_token`, and `expires_in`
- Updated `auth_service.dart` to save and manage tokens properly
- Added support for token expiry tracking

### Security Improvements
- Removed hardcoded Firebase credentials from source code
- Moved credentials to gitignored JSON file
- Credentials are now loaded at runtime from file or Firestore

## Testing
After making these changes, test that:
1. The app still connects to Firebase
2. FCM notifications still work
3. Authentication still works with the new token format
