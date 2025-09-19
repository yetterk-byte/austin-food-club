# Austin Food Club 🍽️

A full-stack **event-focused** application for Austin's weekly featured restaurant. Connect with the community, RSVP for the restaurant of the week, and share your dining experiences.

## 🎪 **Event-Focused Concept**

Austin Food Club is **not a restaurant discovery or review app** - it's a **weekly community event** centered around one carefully selected Austin restaurant. Each week, we feature a single restaurant where the community gathers to dine and connect.

## 🚀 **Current Features**

### 🎯 **Core Event Features**
- **📅 Restaurant of the Week** - Single featured restaurant (currently: Suerte)
- **🙋‍♀️ RSVP System** - Reserve your spot for specific days with real-time counts
- **📍 Precise Location** - Google Maps integration with exact restaurant coordinates
- **👥 Social Community** - See who else is going, connect with fellow food lovers
- **✅ Visit Verification** - Photo verification system for confirmed visits
- **📱 Cross-Platform** - Web app (React) + Mobile app (Flutter)

### 🎨 **User Experience**
- **🌙 Dark Theme** - Professional, mobile-optimized design
- **📲 Mobile-First** - Optimized for on-the-go restaurant planning
- **🔐 Secure Auth** - Phone/SMS and email authentication options
- **👫 Friends System** - Build your foodie network in Austin

## 🛠️ **Tech Stack**

### 🌐 **Web Frontend (React)**
- **React 18** - Modern React with hooks and state management
- **React Router** - Client-side routing
- **Axios** - HTTP client for API calls
- **CSS3** - Custom dark theme with mobile-first design

### 📱 **Mobile App (Flutter)**
- **Flutter 3.16.0** - Cross-platform mobile development
- **Provider** - State management architecture
- **Dart** - Modern programming language
- **Material Design 3** - Native mobile UI components

### 🖥️ **Backend (Shared)**
- **Node.js** - JavaScript runtime
- **Express.js** - RESTful API framework
- **Prisma** - Database ORM with type safety
- **SQLite** - Lightweight local database
- **CORS** - Cross-origin resource sharing

### 🗺️ **Integrations**
- **Google Maps Static API** - Precise restaurant location mapping
- **Supabase** - Authentication and real-time features
- **SMS/Phone Auth** - Secure verification system

## 📁 **Project Structure**

```
austin-food-club/
├── client/                 # 🌐 React Web App
│   ├── public/            # Static assets
│   ├── src/
│   │   ├── components/    # Reusable UI components
│   │   ├── pages/         # Page components (Current, Profile)
│   │   ├── services/      # API and Supabase services
│   │   └── context/       # React context providers
│   └── package.json
├── mobile/                 # 📱 Flutter Mobile App
│   ├── lib/
│   │   ├── screens/       # Mobile screens (Restaurant, Profile, Friends)
│   │   ├── widgets/       # Reusable Flutter widgets
│   │   ├── services/      # API services and data management
│   │   ├── models/        # Data models (User, Restaurant, RSVP)
│   │   └── providers/     # State management
│   ├── android/           # Android-specific configuration
│   ├── ios/               # iOS-specific configuration
│   └── pubspec.yaml       # Flutter dependencies
├── server/                # 🖥️ Shared Backend API
│   ├── src/
│   │   └── server.js      # Express server with API endpoints
│   ├── prisma/
│   │   └── schema.prisma  # Database schema
│   └── package.json
├── database/              # 🗄️ Database files and migrations
└── docs/                  # 📚 Documentation and setup guides
```

## 🚀 **Getting Started**

### 📋 **Prerequisites**
- **Node.js** (v18 or higher) - For backend and React web app
- **Flutter SDK** - For mobile app development
- **npm or yarn** - Package management
- **Git** - Version control

### 🔧 **Installation**

1. **Clone the repository**
   ```bash
   git clone https://github.com/yetterk-byte/austin-food-club.git
   cd austin-food-club
   ```

2. **🖥️ Set up Backend API**
   ```bash
   cd server
   npm install
   npx prisma generate
   npx prisma migrate dev --name init
   npm start  # Runs on http://localhost:3001
   ```

3. **🌐 Set up Web App (React)**
   ```bash
   cd client
   npm install
   # Create client/.env with your Supabase credentials
   npm start  # Runs on http://localhost:3000
   ```

4. **📱 Set up Mobile App (Flutter)**
   ```bash
   cd mobile
   flutter pub get
   flutter run -d chrome --web-port=8080  # For web testing
   # OR
   flutter run  # For mobile device/emulator
   ```

### 🔑 **Environment Variables**

**Client (.env):**
```env
REACT_APP_SUPABASE_URL=your_supabase_url
REACT_APP_SUPABASE_ANON_KEY=your_supabase_anon_key
```

**Mobile (lib/config/api_keys.dart):**
```dart
static const String googleMapsApiKey = 'your_google_maps_api_key';
```

### 🌐 **Access Points**
- **Web App**: http://localhost:3000
- **Mobile App**: http://localhost:8080 (web testing)
- **Backend API**: http://localhost:3001

## 📱 **App Features & Screens**

### 🎪 **Restaurant of the Week Screen**
- **📸 Hero Image** - Beautiful restaurant photography
- **📍 Interactive Map** - Google Maps with precise location (click to navigate)
- **🙋‍♀️ RSVP Section** - Day selector with real-time attendance counts
- **ℹ️ Restaurant Details** - Hours, specialties, description
- **⭐ Rating System** - Community-driven ratings

### 👤 **Profile Screen**
- **📊 User Stats** - Total visits, average rating, friend count
- **✅ Verified Visits** - Photo-verified restaurant experiences
- **👥 Friends List** - Connect with other Austin food lovers
- **📅 RSVP History** - Track your upcoming and past events

### 👫 **Friends Screen**
- **🔍 Find Friends** - Connect with other community members
- **📈 Friend Stats** - See verified visits and last visit dates
- **🤝 Social Features** - Build your Austin foodie network

### 🔐 **Authentication**
- **📱 Phone Auth** - SMS verification for secure login
- **📧 Email Option** - Traditional email/password fallback
- **🔒 Supabase Integration** - Secure user management

## 🗄️ **Database Schema**

**Prisma with SQLite** powers the shared backend:

- **👤 User** - User accounts, profiles, and authentication
- **🍽️ Restaurant** - Weekly featured restaurant information  
- **🙋‍♀️ RSVP** - User reservations with day selection and status
- **✅ VerifiedVisit** - Photo-confirmed restaurant visits with ratings
- **👫 Friendship** - Social connections between users

## 🧪 **API Testing**

```bash
# Test backend health
curl http://localhost:3001/api/test

# Get current featured restaurant (Suerte)
curl http://localhost:3001/api/restaurants/current

# Create RSVP for this week
curl -X POST http://localhost:3001/api/rsvp \
  -H "Content-Type: application/json" \
  -d '{"userId":"user123","day":"friday","status":"going"}'

# Get RSVP counts for the week
curl http://localhost:3001/api/rsvp/counts
```

## 🗺️ **Google Maps Integration**

**Precise location mapping** for the featured restaurant:
- **📍 Static Maps API** - Shows exact restaurant location
- **🎯 Address-based geocoding** - Uses full address for accuracy
- **📱 Click-to-navigate** - Opens Google Maps for directions
- **🔧 API Key setup** - Configured in `mobile/lib/config/api_keys.dart`

## 📦 **Deployment**

### 🌐 **Web App (React)**
- **Vercel/Netlify** - Deploy `client/build` folder
- **Environment**: Supabase credentials required

### 📱 **Mobile App (Flutter)**
- **iOS**: `flutter build ios --release`
- **Android**: `flutter build apk --release`
- **Web**: `flutter build web`

### 🖥️ **Backend (Node.js)**
- **Railway/Heroku** - Deploy with database migration
- **Environment**: Database and auth credentials

## 🎯 **Current Focus: Suerte Restaurant**

**This Week's Featured Restaurant:**
- **📍 Suerte** - 1800 E 6th St, Austin, TX 78702
- **🍽️ Cuisine** - Contemporary Mexican
- **⭐ Rating** - 4.8/5 stars
- **💰 Price** - $$$ 
- **⏰ Wait Time** - 30-45 minutes

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch (`feature/new-restaurant-week`)
3. Make your changes
4. Submit a pull request

## 📄 **License**

MIT License - Built with ❤️ for the Austin food community.

---

## 🎪 **Austin Food Club: Where Austin Eats Together**

**Not just an app - it's a weekly community event.** Join us each week at Austin's finest restaurants and connect with fellow food lovers who share your passion for great dining experiences.
