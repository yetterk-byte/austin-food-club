# Push Notifications Setup Guide

This guide walks you through setting up push notifications for Austin Food Club on both web and mobile platforms.

## 🔧 Environment Variables Required

### Backend (.env)
```bash
# VAPID Keys for Web Push (generate with: npx web-push generate-vapid-keys)
VAPID_PUBLIC_KEY=your_vapid_public_key_here
VAPID_PRIVATE_KEY=your_vapid_private_key_here

# Firebase Admin SDK for Mobile Push
FIREBASE_PROJECT_ID=your_firebase_project_id
FIREBASE_CLIENT_EMAIL=your_firebase_client_email
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nyour_firebase_private_key_here\n-----END PRIVATE KEY-----"
```

### Frontend (.env)
```bash
# VAPID Public Key for Web Push Subscription
REACT_APP_VAPID_PUBLIC_KEY=your_vapid_public_key_here
REACT_APP_API_URL=http://localhost:3001
```

## 🚀 Setup Steps

### 1. Generate VAPID Keys
```bash
cd server
npx web-push generate-vapid-keys
```

### 2. Firebase Setup for Mobile
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create new project or use existing
3. Enable Cloud Messaging
4. Download service account key:
   - Project Settings → Service Accounts → Generate New Private Key
5. Add the credentials to your `.env` file

### 3. Flutter Firebase Configuration
```bash
cd mobile
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for Flutter
flutterfire configure
```

### 4. Update Dependencies
```bash
# Backend
cd server
npm install web-push firebase-admin

# Flutter
cd mobile  
flutter pub get
```

### 5. Database Migration
```bash
cd server
npx prisma db push
```

## 📱 Testing Push Notifications

### Test Web Push
```bash
# 1. Start the server
cd server && npm start

# 2. Open React app
cd client && npm start

# 3. Go to Profile → Notification Settings
# 4. Enable push notifications
# 5. Send test notification
```

### Test Mobile Push
```bash
# 1. Run Flutter app
cd mobile && flutter run

# 2. Go to Profile → Notification Settings  
# 3. Enable push notifications
# 4. Send test notification via admin dashboard
```

### Test via API
```bash
# Get notification status
curl http://localhost:3001/api/notifications/status

# Send test notification (requires auth)
curl -X POST http://localhost:3001/api/notifications/test \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json"
```

## 🔔 Notification Types

### Automatic Notifications
- **Weekly Announcement** - Monday 9 AM CT when restaurant rotates
- **RSVP Reminders** - 2 hours before user's restaurant visit (customizable)
- **Visit Reminders** - Daily 6 PM CT for unverified visits
- **Friend Activity** - Real-time when friends RSVP or verify visits

### Manual Notifications
- **Admin Broadcasts** - Custom messages from admin dashboard
- **Test Notifications** - For testing and verification

## 🎯 API Endpoints

### Public
```
GET    /api/notifications/status              # Service status
```

### User (requires auth)
```
POST   /api/notifications/subscribe           # Subscribe to push
DELETE /api/notifications/unsubscribe         # Unsubscribe
GET    /api/notifications/subscription-status # Check status
GET    /api/notifications/preferences         # Get preferences
PUT    /api/notifications/preferences         # Update preferences
POST   /api/notifications/test                # Send test notification
GET    /api/notifications/logs                # Get user's notification logs
```

### Admin (requires admin auth)
```
POST   /api/notifications/admin/broadcast     # Send broadcast
GET    /api/notifications/admin/stats         # Get statistics
GET    /api/notifications/admin/logs          # Get all logs
POST   /api/notifications/admin/test-subscription/:id  # Test specific subscription
POST   /api/notifications/admin/cleanup       # Clean up old data
```

## 🔧 Configuration Options

### User Preferences
```json
{
  "weeklyAnnouncement": true,
  "rsvpReminders": true,
  "friendActivity": true,
  "visitReminders": true,
  "adminAlerts": false,
  "pushEnabled": true,
  "quietHoursStart": "22:00",
  "quietHoursEnd": "08:00",
  "reminderHoursBefore": 2
}
```

### Notification Payload Structure
```json
{
  "title": "🍽️ This Week: Uchi Austin",
  "body": "Join us at Uchi Austin - Japanese in Austin",
  "data": {
    "type": "weekly_announcement",
    "restaurantId": "restaurant_id_here",
    "action": "view_restaurant"
  },
  "actions": [
    { "action": "rsvp", "title": "RSVP Now" },
    { "action": "details", "title": "View Details" }
  ]
}
```

## 🛠️ Troubleshooting

### Common Issues

**Web Push Not Working:**
1. Check VAPID keys are correctly set
2. Verify service worker is registered
3. Check browser console for errors
4. Ensure HTTPS in production

**Mobile Push Not Working:**
1. Verify Firebase configuration
2. Check FCM token generation
3. Verify service account permissions
4. Check device notification permissions

**Notifications Not Received:**
1. Check user preferences are enabled
2. Verify subscription is active
3. Check quiet hours settings
4. Review notification logs in admin panel

### Debug Commands
```bash
# Check notification service status
curl http://localhost:3001/api/notifications/status

# View notification statistics
curl -H "Authorization: Bearer ADMIN_TOKEN" \
  http://localhost:3001/api/notifications/admin/stats

# Test specific subscription
curl -X POST -H "Authorization: Bearer ADMIN_TOKEN" \
  http://localhost:3001/api/notifications/admin/test-subscription/SUBSCRIPTION_ID
```

## 📊 Monitoring

### Admin Dashboard Features
- Real-time notification statistics
- User subscription management
- Notification delivery logs
- Push notification testing tools
- Broadcast messaging interface

### Analytics Tracked
- Notification delivery rates
- User engagement (clicks)
- Platform distribution (web vs mobile)
- Opt-in/opt-out rates
- Error rates and types

## 🚀 Production Deployment

### Security Considerations
1. Store VAPID keys securely
2. Restrict Firebase service account permissions
3. Validate all notification payloads
4. Rate limit notification endpoints
5. Implement user consent management

### Performance Optimizations
1. Batch notification sending
2. Queue failed notifications for retry
3. Cache user preferences
4. Use background jobs for large broadcasts
5. Monitor delivery rates and adjust timing

## 🔮 Future Enhancements

1. **Rich Notifications** - Images, action buttons, custom sounds
2. **Geofencing** - Location-based restaurant notifications
3. **Smart Timing** - ML-based optimal notification timing
4. **A/B Testing** - Test different notification content
5. **Analytics Dashboard** - Detailed engagement metrics
6. **Multi-language** - Localized notifications for different cities

---

This push notification system provides a solid foundation for keeping Austin Food Club users engaged with timely, relevant notifications across all platforms.
