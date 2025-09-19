# Austin Food Club Flutter App

A Flutter mobile application for the Austin Food Club, connecting to the existing Express backend API.

## Setup Instructions

### 1. Environment Configuration

Create a `.env` file in the root directory with the following variables:

```env
# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key

# API Configuration
API_BASE_URL=http://localhost:3001/api

# App Configuration
APP_NAME=Austin Food Club
APP_VERSION=1.0.0
```

### 2. Dependencies

Install Flutter dependencies:

```bash
flutter pub get
```

### 3. Backend Connection

This Flutter app connects to your existing Express backend running on `http://localhost:3001`. Make sure your backend is running before testing the app.

### 4. Project Structure

```
lib/
├── main.dart                 # App entry point
├── config/
│   ├── theme.dart           # Dark theme configuration
│   ├── constants.dart       # App constants and API URLs
│   └── routes.dart          # Navigation routes
├── models/
│   ├── user.dart            # User data model
│   ├── restaurant.dart      # Restaurant data model
│   ├── rsvp.dart           # RSVP data model
│   ├── wishlist.dart       # Wishlist data model
│   └── verified_visit.dart # Verified visit data model
├── services/               # API and external services
├── providers/              # State management
├── screens/                # App screens
├── widgets/                # Reusable UI components
└── utils/                  # Utility functions
```

### 5. Features

- **Authentication**: Supabase integration for user management
- **Restaurant Discovery**: Browse and view restaurant details
- **RSVP System**: Reserve spots for restaurant visits
- **Photo Verification**: Upload photos to verify visits
- **Wishlist**: Save restaurants for later
- **Profile Management**: View visit history and statistics

### 6. API Endpoints

The app connects to these backend endpoints:

- `GET /api/restaurants` - Fetch restaurants
- `POST /api/rsvp` - Create/update RSVP
- `GET /api/rsvp/counts` - Get RSVP counts
- `GET /api/verified-visits` - Get verified visits
- `POST /api/verified-visits` - Submit verification
- `GET /api/wishlist` - Get wishlist items

### 7. Development

Run the app in development mode:

```bash
flutter run
```

### 8. Building

Build for production:

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## Next Steps

1. Implement the service classes (API, Auth, Storage, Photo)
2. Create provider classes for state management
3. Build the screen widgets
4. Add reusable UI components
5. Implement utility functions and validators