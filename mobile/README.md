# Austin Food Club Flutter App

A Flutter mobile application for the Austin Food Club, featuring a modern dark theme with custom typography and comprehensive restaurant discovery features.

## 🎨 Design & Typography

The app features a distinctive design system:
- **Monoton Font**: Used for "Austin Food Club" branding throughout the app
- **Roboto Condensed**: Clean, modern headings and titles
- **Inter Font**: Readable body text and UI elements
- **Dark Theme**: Professional dark interface with orange accents
- **Glassmorphism**: Translucent app bars with smart navigation

## 🚀 Current Features

### ✅ Implemented Features
- **Featured Restaurant Display**: Weekly restaurant spotlight with full details
- **RSVP System**: Reserve spots for restaurant visits with day-specific counts
- **Photo Verification**: Upload photos and star ratings to verify restaurant visits
- **Social Features**: 
  - Friends list and friend requests
  - Social activity feed (following tab)
  - City activity feed (public verified visits)
  - Friend profiles with visit history
- **Restaurant Search**: Yelp-powered smart search for verifying visits
- **Profile Management**: View verified visits, favorite restaurants, and statistics
- **Multi-City Architecture**: Backend supports multiple cities (Austin, Denver, Portland)
- **Real-time Updates**: WebSocket integration for live dashboard updates

### 🔧 Technical Features
- **Provider State Management**: Robust state management with Provider pattern
- **API Integration**: Full backend integration with Express.js server
- **Mock Data Support**: Comprehensive mock data for testing and development
- **Error Handling**: Graceful error handling with user-friendly messages
- **Responsive Design**: Optimized for mobile and web platforms

## 🛠️ Setup Instructions

### 1. Prerequisites
- Flutter SDK (>=3.13.0)
- Node.js backend running on `http://localhost:3001`
- Chrome browser for web development

### 2. Dependencies

Install Flutter dependencies:

```bash
flutter pub get
```

### 3. Backend Connection

This Flutter app connects to your Express backend running on `http://localhost:3001`. Make sure your backend is running before testing the app.

### 4. Project Structure

```
lib/
├── main.dart                    # App entry point with auth wrapper
├── config/
│   ├── app_theme.dart          # Custom theme with Google Fonts
│   └── city_config.dart        # Multi-city configuration
├── models/
│   ├── user.dart               # User data model
│   ├── restaurant.dart         # Restaurant data model
│   ├── friend.dart             # Friend and social models
│   └── verified_visit.dart     # Verified visit data model
├── services/
│   ├── api_service.dart        # HTTP API calls
│   ├── restaurant_service.dart # Restaurant data service
│   ├── social_service.dart     # Social features service
│   ├── search_service.dart     # Yelp search integration
│   └── verified_visits_service.dart # Visit verification
├── providers/
│   └── auth_provider.dart      # Authentication state management
├── screens/
│   ├── home_screen.dart        # Main featured restaurant screen
│   ├── profile_screen.dart     # User profile with verified visits
│   ├── friends_screen.dart     # Social features and activity
│   ├── restaurant_screen.dart  # Detailed restaurant view
│   ├── friend_profile_screen.dart # Friend profile view
│   └── photo_verification_screen.dart # Visit verification
└── widgets/
    ├── restaurant_card.dart    # Restaurant display components
    ├── restaurant_search_widget.dart # Smart search widget
    ├── rsvp_section.dart       # RSVP functionality
    └── simple_map_widget.dart  # Web-compatible map display
```

## 🌐 API Integration

The app integrates with these backend endpoints:

### Restaurant Features
- `GET /api/restaurants/current?citySlug=austin` - Get featured restaurant
- `GET /api/restaurants/search?term=...` - Yelp-powered restaurant search

### Social Features
- `GET /api/friends/user/:userId` - Get friends list
- `POST /api/friends/add` - Add friend
- `GET /api/social-feed/user/:userId` - Get social activity
- `GET /api/city-activity/user/:userId` - Get city-wide activity

### Verification Features
- `GET /api/verified-visits/user/:userId` - Get user's verified visits
- `POST /api/verified-visits` - Submit new verification

### RSVP Features
- `GET /api/rsvps/restaurant/:restaurantId/counts` - Get RSVP counts by day

## 🚀 Development

### Run the App

```bash
# Web development (recommended)
flutter run -d chrome --web-port=8089

# Mobile development
flutter run
```

### Hot Reload
The app supports hot reload for rapid development:
- Press `r` in the terminal for hot reload
- Press `R` for hot restart

## 🎯 Current Status

**✅ Fully Functional Features:**
- Featured restaurant display with Monoton branding
- Complete RSVP system with day-specific counts
- Photo verification with star ratings
- Social features (friends, activity feeds, profiles)
- Smart restaurant search with Yelp integration
- Multi-city backend architecture
- Real-time dashboard updates via WebSocket

**🔧 Known Issues:**
- Some API endpoints return mock data for development
- Google Maps functionality simplified for web compatibility
- City activity shows some type conversion warnings (non-blocking)

## 🏗️ Architecture

The app follows a clean architecture pattern:
- **Models**: Data structures for API responses
- **Services**: API communication and business logic
- **Providers**: State management with Provider pattern
- **Screens**: UI components and user interactions
- **Widgets**: Reusable UI components

## 📱 Platform Support

- **Web**: Fully functional with Chrome browser
- **Mobile**: Ready for iOS and Android deployment
- **Cross-platform**: Shared codebase with platform-specific optimizations