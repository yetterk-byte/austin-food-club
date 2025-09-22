# Multi-City Food Club Architecture

This document outlines the comprehensive multi-city architecture for Food Club applications, enabling support for Austin Food Club, NOLA Food Club, Boston Food Club, NYC Food Club, and future cities.

## 🏗️ Architecture Overview

The multi-city architecture is designed to support multiple cities from a single codebase while maintaining city-specific branding, configurations, and data isolation.

### Core Components

1. **City Configuration System** - Database-driven city settings
2. **City Context Middleware** - Automatic city detection and context injection
3. **City-Aware Services** - All backend services respect city boundaries
4. **Multi-City Frontend** - React and Flutter apps with city selection
5. **Flexible Deployment** - Support for both single and multi-tenant deployments

## 📊 Database Schema

### New Models

#### City Model
```prisma
model City {
  id              String    @id @default(cuid())
  name            String    @unique // "Austin", "New Orleans"
  slug            String    @unique // "austin", "nola"
  state           String    // "TX", "LA"
  displayName     String    // "Austin Food Club"
  timezone        String    // "America/Chicago"
  
  // Yelp API Configuration
  yelpLocation    String    // "Austin, TX"
  yelpRadius      Int       @default(24140)
  
  // Branding
  brandColor      String    @default("#20b2aa")
  logoUrl         String?
  heroImageUrl    String?
  
  // App Configuration  
  rotationDay     String    @default("tuesday")
  rotationTime    String    @default("09:00")
  minQueueSize    Int       @default(3)
  
  // Status
  isActive        Boolean   @default(true)
  launchDate      DateTime?
  
  // Relations
  users           User[]
  restaurants     Restaurant[]
  rotationConfigs RotationConfig[]
}
```

### Updated Models

- **Restaurant**: Added `cityId` foreign key
- **User**: Added optional `cityId` for user's primary city
- **RotationConfig**: Now city-specific with `cityId`

## 🚀 Backend Implementation

### City Context System

#### City Detection Priority
1. `X-City-Slug` header
2. `city` query parameter  
3. Subdomain (e.g., `austin.foodclub.com`)
4. Default to Austin

#### City Context Middleware
```javascript
const { cityContext, requireActiveCity } = require('./middleware/cityContext');

// Apply to all routes
app.use(cityContext);

// Require active city for public routes
app.use('/api/restaurants', requireActiveCity);
```

### City-Aware Services

#### Yelp Service
```javascript
// Legacy: yelpService.searchRestaurants('Austin, TX', 'pizza')
// New: yelpService.searchRestaurants(cityConfig, 'pizza')

const cityConfig = await CityService.getCityConfig(cityId);
const results = await yelpService.searchRestaurants(cityConfig, 'pizza');
```

#### Restaurant Service
```javascript
// Get city-specific featured restaurant
const featured = await CityService.getFeaturedRestaurant(cityId);

// Get city-specific queue
const queue = await CityService.getCityQueue(cityId);
```

### New API Endpoints

```
GET    /api/cities              # List all active cities
GET    /api/cities/current      # Get current city config
GET    /api/cities/:slug        # Get specific city
POST   /api/cities              # Create city (admin)
PUT    /api/cities/:slug        # Update city (admin)
GET    /api/cities/:slug/stats  # City statistics (admin)
```

## 📱 Frontend Implementation

### Flutter App Changes

#### City Configuration
```dart
import 'package:austin_food_club/config/city_config.dart';

// Set current city
CityService.setCityBySlug('austin');

// Get city-aware API headers
final headers = CityService.getApiHeaders();

// Get city-specific theme
final theme = CityTheme.getTheme(CityService.currentCity);
```

#### City Selection UI
- City picker on app startup
- Settings page for city switching
- City-specific branding and colors

### React App Changes

#### City Context Provider
```jsx
import { CityProvider, useCity } from './contexts/CityContext';

function App() {
  return (
    <CityProvider>
      <Router>
        <Routes>
          <Route path="/" element={<HomePage />} />
        </Routes>
      </Router>
    </CityProvider>
  );
}
```

## 🌍 Deployment Strategies

### Strategy 1: Single Multi-Tenant Instance
- One deployment serves all cities
- City detection via headers/subdomains
- Shared database with city isolation
- Cost-effective for smaller scale

```nginx
# Nginx configuration for subdomains
server {
  server_name austin.foodclub.com;
  location / {
    proxy_pass http://backend;
    proxy_set_header X-City-Slug austin;
  }
}

server {
  server_name nola.foodclub.com;
  location / {
    proxy_pass http://backend;
    proxy_set_header X-City-Slug nola;
  }
}
```

### Strategy 2: City-Specific Instances
- Separate deployments per city
- Dedicated databases per city
- Independent scaling and customization
- Better for large scale operations

```yaml
# Docker Compose per city
version: '3.8'
services:
  austin-backend:
    environment:
      - DEFAULT_CITY=austin
      - DATABASE_URL=postgresql://austin_db
  
  nola-backend:
    environment:
      - DEFAULT_CITY=nola
      - DATABASE_URL=postgresql://nola_db
```

### Strategy 3: Hybrid Approach
- Shared backend with city routing
- City-specific frontends
- Database per city for data isolation
- Load balancer with city-based routing

## 🔧 Configuration Management

### Environment Variables
```bash
# Multi-city support
MULTI_CITY_ENABLED=true
DEFAULT_CITY=austin
CITY_DETECTION_MODE=header # header|subdomain|param

# City-specific overrides
AUSTIN_YELP_LOCATION="Austin, TX"
NOLA_YELP_LOCATION="New Orleans, LA"
BOSTON_YELP_LOCATION="Boston, MA"
NYC_YELP_LOCATION="New York, NY"
```

### City-Specific Configurations
```json
{
  "cities": {
    "austin": {
      "displayName": "Austin Food Club",
      "brandColor": "#20b2aa",
      "timezone": "America/Chicago",
      "features": {
        "rsvp": true,
        "socialFeed": true,
        "verifiedVisits": true
      }
    },
    "nola": {
      "displayName": "NOLA Food Club", 
      "brandColor": "#8b4513",
      "timezone": "America/Chicago",
      "features": {
        "rsvp": true,
        "socialFeed": false,
        "verifiedVisits": false
      }
    }
  }
}
```

## 🚀 Migration Guide

### From Single City to Multi-City

1. **Database Migration**
   ```bash
   cd server
   npx prisma db push --accept-data-loss
   node src/scripts/initializeCities.js
   ```

2. **Update API Calls**
   ```javascript
   // Before
   const response = await fetch('/api/restaurants/current');
   
   // After  
   const response = await fetch('/api/restaurants/current', {
     headers: { 'X-City-Slug': 'austin' }
   });
   ```

3. **Update Frontend**
   ```dart
   // Flutter - Add city context
   final headers = CityService.getApiHeaders();
   final response = await http.get(url, headers: headers);
   ```

### Adding a New City

1. **Create City Configuration**
   ```bash
   curl -X POST http://localhost:3001/api/cities \
     -H "Content-Type: application/json" \
     -d '{
       "name": "Chicago",
       "slug": "chicago", 
       "displayName": "Chicago Food Club",
       "state": "IL",
       "yelpLocation": "Chicago, IL",
       "brandColor": "#1f4e79"
     }'
   ```

2. **Activate City**
   ```bash
   curl -X PUT http://localhost:3001/api/cities/chicago \
     -H "Content-Type: application/json" \
     -d '{"isActive": true}'
   ```

3. **Update Frontend City List**
   ```dart
   // Add to Cities class in city_config.dart
   static const chicago = CityConfig(
     slug: 'chicago',
     displayName: 'Chicago Food Club',
     // ... other config
   );
   ```

## 📊 Monitoring & Analytics

### City-Specific Metrics
- Restaurant count per city
- User engagement per city  
- RSVP rates per city
- Queue health per city

### Admin Dashboard
- City management interface
- Per-city analytics
- City activation/deactivation
- Brand customization

## 🔒 Security Considerations

### Data Isolation
- All queries filtered by cityId
- Admin access scoped to cities
- User data isolated per city

### City Access Control
```javascript
// Middleware to ensure users only access their city data
const cityAccessControl = (req, res, next) => {
  if (req.user.cityId && req.user.cityId !== req.city.id) {
    return res.status(403).json({ error: 'City access denied' });
  }
  next();
};
```

## 🎯 Future Enhancements

1. **City-Specific Features**
   - Custom restaurant categories per city
   - City-specific events and promotions
   - Local partnership integrations

2. **Advanced Deployment**
   - Auto-scaling per city
   - City-specific CDN configurations
   - Geographic load balancing

3. **Enhanced Branding**
   - Custom themes per city
   - City-specific logos and imagery
   - Local language support

4. **Analytics & Insights**
   - Cross-city performance comparison
   - City expansion recommendations
   - Market analysis tools

## 📚 API Documentation

### City Management
- [City API Reference](./docs/api/cities.md)
- [Migration Scripts](./docs/scripts/migration.md)
- [Deployment Guide](./docs/deployment/multi-city.md)

## 🤝 Contributing

When adding features to the multi-city architecture:

1. Ensure all new features respect city boundaries
2. Add city context to new API endpoints
3. Update both React and Flutter implementations
4. Add appropriate tests for multi-city scenarios
5. Update documentation

---

This architecture provides a solid foundation for expanding Food Club to multiple cities while maintaining code reusability, data isolation, and city-specific customization capabilities.
