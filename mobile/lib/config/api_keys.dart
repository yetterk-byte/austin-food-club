class ApiKeys {
  // Google Maps API Key
  static const String googleMapsApiKey = 'AIzaSyA6pcXA40sTWfiNL5lWA-pZZJsFJv0f5xQ';
  
  // For development/testing, use the real API key
  static const String googleMapsApiKeyDev = 'AIzaSyA6pcXA40sTWfiNL5lWA-pZZJsFJv0f5xQ';
  
  // Use production key in release mode, dev key in debug mode
  static String get currentGoogleMapsApiKey {
    const bool isProduction = bool.fromEnvironment('dart.vm.product');
    return isProduction ? googleMapsApiKey : googleMapsApiKeyDev;
  }
}

// Instructions for setting up your API key:
// 
// 1. Go to https://console.cloud.google.com/
// 2. Create a new project or select existing
// 3. Enable these APIs:
//    - Maps Static API
//    - Maps Embed API
//    - Maps SDK for Android (if building for Android)
//    - Maps SDK for iOS (if building for iOS)
// 4. Create credentials > API Key
// 5. Replace 'YOUR_GOOGLE_MAPS_API_KEY_HERE' above with your key
// 6. Restrict your API key:
//    - Application restrictions: HTTP referrers for web
//    - API restrictions: Only the Maps APIs you enabled
//
// For production, consider using environment variables or
// a secrets management system instead of hardcoding the key.
