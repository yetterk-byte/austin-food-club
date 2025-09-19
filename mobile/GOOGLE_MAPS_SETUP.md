# 🗺️ Google Maps API Setup Guide

## Step 1: Get Your Google Maps API Key

1. **Go to Google Cloud Console**: https://console.cloud.google.com/
2. **Create a new project** (or select existing):
   - Click "Select a project" dropdown
   - Click "New Project"
   - Name it "Austin Food Club"
   - Click "Create"

3. **Enable Required APIs**:
   - Go to "APIs & Services" > "Library"
   - Search for and enable these APIs:
     - ✅ **Maps Static API** (for map images)
     - ✅ **Maps Embed API** (for embedded maps)
     - ✅ **Maps SDK for Android** (if building Android app)
     - ✅ **Maps SDK for iOS** (if building iOS app)

4. **Create API Key**:
   - Go to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "API Key"
   - Copy the generated API key (starts with `AIza...`)

## Step 2: Configure Your Flutter App

### Option A: Quick Setup (For Development)
Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` in these files:

1. **`lib/config/api_keys.dart`**:
   ```dart
   static const String googleMapsApiKey = 'AIza...YOUR_KEY_HERE';
   ```

2. **`android/app/src/main/AndroidManifest.xml`**:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="AIza...YOUR_KEY_HERE" />
   ```

3. **`ios/Runner/AppDelegate.swift`**:
   ```swift
   GMSServices.provideAPIKey("AIza...YOUR_KEY_HERE")
   ```

### Option B: Secure Setup (For Production)

1. **Create `.env` file** (add to `.gitignore`):
   ```
   GOOGLE_MAPS_API_KEY=AIza...YOUR_KEY_HERE
   ```

2. **Use environment variables** in your config files instead of hardcoding

## Step 3: Restrict Your API Key (Important!)

1. **In Google Cloud Console**, go to "Credentials"
2. **Click on your API key**
3. **Set Application Restrictions**:
   - **For Web**: HTTP referrers, add your domains
   - **For Android**: Android apps, add package name
   - **For iOS**: iOS apps, add bundle identifier

4. **Set API Restrictions**:
   - Select "Restrict key"
   - Choose only the APIs you enabled above

## Step 4: Test Your Setup

1. **Run your Flutter app**:
   ```bash
   flutter run -d chrome --web-port=8080
   ```

2. **Check the Location section** - you should see:
   - ✅ Real Google Maps imagery
   - ✅ Actual streets and landmarks
   - ✅ Orange marker at restaurant location
   - ✅ Click-to-navigate functionality

## Troubleshooting

### If you see the fallback pattern instead of real maps:
- ✅ Check that your API key is correct
- ✅ Verify the APIs are enabled in Google Cloud
- ✅ Check browser developer tools for error messages
- ✅ Ensure API key restrictions allow your domain

### Common Errors:
- **"This page can't load Google Maps correctly"** → API key issue
- **Watermarked map** → API key not configured
- **Generic pattern** → API key empty or invalid

### Free Tier Limits:
- **Static Maps**: 28,000 loads/month free
- **Embed API**: Unlimited (with restrictions)
- **Monitor usage** in Google Cloud Console

## Current Status

- ✅ **Configuration files created**
- ⏳ **API key needs to be added**
- ⏳ **APIs need to be enabled**
- ✅ **Fallback system working**

Once you add your API key, the app will automatically show real Google Maps!

---

## Quick Commands

```bash
# Navigate to project
cd /Users/kennyyetter/Desktop/austin_food_club_flutter

# Run app
flutter run -d chrome --web-port=8080

# Check if maps are loading
# Look for "Location" section on This Week page
```

**Need help?** The app works perfectly with the fallback system, but real Google Maps will show actual satellite imagery and street data!
