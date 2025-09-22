# Environment Variables Template

## Server Environment Variables (server/.env)

Add these to your `server/.env` file:

```bash
# Push Notification Configuration
VAPID_PUBLIC_KEY=BCaVgm8OH2YpGBpcsQI2OdP951AHiJEHSg81wczPLUTFLK1UaBj9J13VlLV-z8VdKR-ke0irxoXQGVELyAt_Ofk
VAPID_PRIVATE_KEY=X6aj2CEVQP4LDl_C2sj24W9tuHWbWJZN70cfiyeRE40

# Firebase Configuration (for mobile push notifications)
# Get these from Firebase Console → Project Settings → Service Accounts
FIREBASE_PROJECT_ID=your_firebase_project_id
FIREBASE_CLIENT_EMAIL=your_firebase_client_email@your_project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nyour_firebase_private_key_here\n-----END PRIVATE KEY-----"
```

## Frontend Environment Variables (client/.env)

Create `client/.env` with:

```bash
# VAPID Public Key for Web Push Subscription
REACT_APP_VAPID_PUBLIC_KEY=BCaVgm8OH2YpGBpcsQI2OdP951AHiJEHSg81wczPLUTFLK1UaBj9J13VlLV-z8VdKR-ke0irxoXQGVELyAt_Ofk
REACT_APP_API_URL=http://localhost:3001
```

## Firebase Setup for Mobile

1. **Create Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create new project: "Austin Food Club"
   - Enable Google Analytics (optional)

2. **Enable Cloud Messaging**
   - Go to Project Settings → Cloud Messaging
   - Note your Project ID

3. **Add Android App**
   - Package name: `com.austinfoodclub.app`
   - Download `google-services.json`
   - Place in `mobile/android/app/`

4. **Add iOS App**
   - Bundle ID: `com.austinfoodclub.app`
   - Download `GoogleService-Info.plist`
   - Place in `mobile/ios/Runner/`

5. **Generate Service Account Key**
   - Project Settings → Service Accounts
   - Click "Generate new private key"
   - Add credentials to server `.env`

## Quick Test Commands

```bash
# Test notification system status
curl http://localhost:3001/api/notifications/status

# Generate new VAPID keys if needed
cd server && npx web-push generate-vapid-keys
```
