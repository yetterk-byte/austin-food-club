# Austin Food Club

A full-stack food discovery and social platform connecting food enthusiasts with local restaurants through weekly featured spots and social interactions.

## 🏗️ Architecture

- **Backend**: Node.js/Express API with standardized response format
- **Frontend**: Flutter web application with responsive design
- **Admin Dashboard**: React-based admin interface
- **Database**: Prisma ORM with PostgreSQL
- **External APIs**: Yelp integration for restaurant data
- **Real-time**: WebSocket support for live updates

## 🚀 Quick Start

### Prerequisites

- Node.js 18+
- Flutter 3.0+
- PostgreSQL database
- Yelp API key

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd austin-food-club
   ```

2. **Backend Setup**
   ```bash
   cd server
   npm install
   cp .env.example .env
   # Configure your environment variables
   npm start
   ```

3. **Frontend Setup**
   ```bash
   cd mobile
   flutter pub get
   flutter run -d chrome --web-port=8089
   ```

4. **Admin Dashboard**
   ```bash
   # Access at http://localhost:3001/admin-dashboard.html
   # Login: admin@austinfoodclub.com / admin123
   ```

## 📚 Documentation

### API Documentation
- **[API Documentation](API_DOCUMENTATION.md)** - Complete API reference with examples
- **[Developer Guide](DEVELOPER_GUIDE.md)** - Step-by-step guide for implementing new endpoints

### Testing
- **[API Consistency Test](test-api-consistency.js)** - Automated testing script for API standardization

## 🔧 Key Features

### Restaurant Management
- Weekly featured restaurant rotation
- Yelp API integration for restaurant data
- Multi-city support (Austin, Denver, Portland)
- Restaurant queue management with drag-and-drop reordering

### Social Features
- User profiles with verified visits
- Friends system and social activity feed
- City-wide activity feed
- Photo sharing for verified visits

### Admin Dashboard
- Real-time analytics and metrics
- Restaurant queue management
- City management and activation
- User activity monitoring

### API Features
- Standardized response format
- Comprehensive input validation
- Centralized error handling
- Real-time WebSocket updates

## 🏛️ API Architecture

### Standardized Response Format

All API responses follow this consistent structure:

```json
{
  "success": boolean,
  "message": string,
  "timestamp": string (ISO 8601),
  "data": object | array | null,
  "meta": object | null,
  "error": string | null
}
```

### Example Endpoints

```bash
# Get current featured restaurant
GET /api/restaurants/current?citySlug=austin

# Get user's friends
GET /api/friends/user/1

# Get social activity feed
GET /api/social-feed/user/1

# Get city activity
GET /api/city-activity/user/1

# Create verified visit
POST /api/verified-visits
```

## 🧪 Testing

### Run API Consistency Tests

```bash
node test-api-consistency.js
```

This script tests all endpoints to ensure they follow the standardized response format.

### Manual Testing

```bash
# Test basic endpoint
curl -X GET http://localhost:3001/api/test | jq .

# Test admin login
curl -X POST http://localhost:3001/api/auth/admin-login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@austinfoodclub.com","password":"admin123"}' | jq .

# Test restaurant endpoint
curl -X GET "http://localhost:3001/api/restaurants/current?citySlug=austin" | jq .
```

## 🏙️ Multi-City Support

The platform supports multiple cities with:

- **City-specific restaurant queues**
- **Independent featured restaurants**
- **City-based user activity feeds**
- **Admin dashboard city switching**
- **City activation/deactivation controls**

### Supported Cities
- Austin (Primary)
- Denver
- Portland

## 🔐 Authentication

### User Authentication
- Magic link authentication
- OAuth integration
- JWT token-based sessions

### Admin Authentication
- Demo admin credentials: `admin@austinfoodclub.com` / `admin123`
- Role-based access control
- Admin dashboard protection

## 📱 Frontend Integration

### Flutter Services
The Flutter app includes services for:
- Restaurant data fetching
- Social features (friends, activity feeds)
- Verified visits management
- User authentication

### Response Handling
All Flutter services handle the standardized API response format:

```dart
// Handle standardized API response format
if (responseData['success'] == true && responseData['data'] != null) {
  final Map<String, dynamic> data = responseData['data'] as Map<String, dynamic>;
  if (data['items'] != null) {
    final List<dynamic> items = data['items'] as List<dynamic>;
    return items.cast<Map<String, dynamic>>();
  }
}
```

## 🛠️ Development

### Adding New Endpoints

1. Follow the [Developer Guide](DEVELOPER_GUIDE.md)
2. Use the standardized middleware:
   ```javascript
   const { asyncHandler, NotFoundError, AppError } = require('../middleware/errorHandler');
   const { validate, validateQuery } = require('../middleware/validation');
   ```
3. Use response helpers:
   ```javascript
   res.api.success.ok(res, 'Data retrieved successfully', data);
   ```
4. Add to test script
5. Update documentation

### Code Standards

- **ESLint** configuration for consistent code style
- **Standardized error handling** with custom error classes
- **Input validation** with centralized rules
- **Comprehensive logging** for debugging
- **Type safety** in Flutter with proper casting

## 📊 Monitoring

### Real-time Analytics
- User engagement metrics
- Restaurant performance tracking
- Social activity monitoring
- System health indicators

### WebSocket Events
- Real-time dashboard updates
- Live user activity feeds
- Admin notification system
- City-specific room management

## 🚀 Deployment

### Environment Variables

```env
# Database
DATABASE_URL="postgresql://user:password@localhost:5432/austin_food_club"

# Yelp API
YELP_API_KEY="your_yelp_api_key"

# Authentication
JWT_SECRET="your_jwt_secret"
SUPABASE_URL="your_supabase_url"
SUPABASE_ANON_KEY="your_supabase_anon_key"

# Server
PORT=3001
NODE_ENV=development
```

### Production Considerations

- Database connection pooling
- API rate limiting
- Caching strategies
- Error monitoring
- Performance optimization

## 🤝 Contributing

1. Follow the [Developer Guide](DEVELOPER_GUIDE.md)
2. Ensure all tests pass: `node test-api-consistency.js`
3. Update documentation for new features
4. Follow the established code standards
5. Test thoroughly across all platforms

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For questions or issues:
1. Check the [API Documentation](API_DOCUMENTATION.md)
2. Review the [Developer Guide](DEVELOPER_GUIDE.md)
3. Run the consistency tests to identify issues
4. Check server logs for detailed error information

## 🎯 Roadmap

- [ ] Enhanced mobile app features
- [ ] Advanced analytics dashboard
- [ ] Restaurant owner portal
- [ ] Event management system
- [ ] Advanced social features
- [ ] Multi-language support
- [ ] API versioning
- [ ] Performance optimization

---

**Austin Food Club** - Connecting food lovers with amazing local restaurants! 🍽️