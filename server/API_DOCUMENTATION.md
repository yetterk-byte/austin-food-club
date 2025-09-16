# Austin Food Club API Documentation

## Overview

The Austin Food Club API is a RESTful service that provides restaurant discovery, RSVP management, and user functionality for the Austin Food Club application.

**Base URL:** `http://localhost:3001/api/v1`  
**Version:** 1.0.0  
**Content-Type:** `application/json`

## Authentication

Most endpoints require authentication via Bearer token in the Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

For development, mock tokens are accepted:
- `mock-token-consistent` - For consistent testing
- `mock-token-<timestamp>` - For unique testing

## Response Format

All API responses follow a consistent JSON format:

### Success Response
```json
{
  "success": true,
  "status": 200,
  "message": "Operation completed successfully",
  "data": { ... },
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

### Error Response
```json
{
  "success": false,
  "status": 400,
  "message": "Error description",
  "details": { ... },
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

## Endpoints

### System Endpoints

#### Health Check
- **GET** `/health`
- **Description:** Check API health status
- **Authentication:** None required
- **Response:**
```json
{
  "success": true,
  "status": 200,
  "message": "API is healthy",
  "data": {
    "service": "Austin Food Club API",
    "version": "1.0.0",
    "status": "healthy",
    "uptime": 3600,
    "timestamp": "2024-01-15T10:30:00.000Z"
  }
}
```

#### API Information
- **GET** `/info`
- **Description:** Get API information and available endpoints
- **Authentication:** None required
- **Response:**
```json
{
  "success": true,
  "status": 200,
  "message": "API information retrieved",
  "data": {
    "name": "Austin Food Club API",
    "version": "1.0.0",
    "description": "REST API for Austin Food Club restaurant discovery and RSVP system",
    "endpoints": {
      "restaurants": "/api/v1/restaurants",
      "auth": "/api/v1/auth",
      "users": "/api/v1/users",
      "system": "/api/v1/system"
    }
  }
}
```

### Restaurant Endpoints

#### Get All Restaurants
- **GET** `/restaurants`
- **Description:** Get paginated list of restaurants
- **Authentication:** None required
- **Query Parameters:**
  - `page` (optional): Page number (default: 1)
  - `limit` (optional): Items per page (default: 20)
  - `search` (optional): Search term for restaurant name
  - `cuisine` (optional): Filter by cuisine type
  - `price` (optional): Filter by price range ($, $$, $$$, $$$$)
  - `rating` (optional): Minimum rating (1-5)
- **Example:** `GET /restaurants?page=1&limit=10&cuisine=bbq&rating=4.0`
- **Response:**
```json
{
  "success": true,
  "status": 200,
  "message": "Restaurants retrieved successfully",
  "data": {
    "restaurants": [
      {
        "id": "restaurant-123",
        "name": "Franklin Barbecue",
        "address": "900 E 11th St, Austin, TX 78702",
        "rating": 4.5,
        "priceRange": "$$",
        "categories": ["bbq", "american"],
        "imageUrl": "https://example.com/image.jpg",
        "yelpId": "franklin-barbecue-austin"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 50,
      "pages": 5
    }
  }
}
```

#### Get Featured Restaurant
- **GET** `/restaurants/featured`
- **Description:** Get current week's featured restaurant
- **Authentication:** None required
- **Response:**
```json
{
  "success": true,
  "status": 200,
  "message": "Featured restaurant retrieved successfully",
  "data": {
    "id": "restaurant-123",
    "name": "Franklin Barbecue",
    "description": "Award-winning BBQ in Austin",
    "imageUrl": "https://example.com/featured.jpg",
    "rating": 4.5,
    "reviewCount": 1250,
    "categories": ["bbq", "american"],
    "priceRange": "$$",
    "address": "900 E 11th St, Austin, TX 78702",
    "hours": {
      "monday": "11:00 AM - 3:00 PM",
      "tuesday": "11:00 AM - 3:00 PM"
    },
    "photos": ["https://example.com/photo1.jpg"],
    "yelpUrl": "https://yelp.com/biz/franklin-barbecue"
  }
}
```

#### Search Restaurants
- **GET** `/restaurants/search`
- **Description:** Search restaurants using Yelp API
- **Authentication:** None required
- **Query Parameters:**
  - `location` (required): Search location (e.g., "Austin, TX")
  - `cuisine` (optional): Cuisine type filter
  - `price` (optional): Price range filter
  - `limit` (optional): Number of results (default: 20)
  - `sort_by` (optional): Sort order (rating, distance, review_count)
- **Example:** `GET /restaurants/search?location=Austin%2CTX&cuisine=bbq&limit=10`
- **Response:**
```json
{
  "success": true,
  "status": 200,
  "message": "Restaurant search completed successfully",
  "data": {
    "restaurants": [
      {
        "id": "yelp-123",
        "name": "Franklin Barbecue",
        "rating": 4.5,
        "price": "$$",
        "categories": ["bbq"],
        "location": {
          "address1": "900 E 11th St",
          "city": "Austin",
          "state": "TX",
          "zip_code": "78702"
        }
      }
    ],
    "total": 1
  }
}
```

#### Get Restaurant by ID
- **GET** `/restaurants/:id`
- **Description:** Get specific restaurant details
- **Authentication:** None required
- **Path Parameters:**
  - `id`: Restaurant ID
- **Example:** `GET /restaurants/restaurant-123`
- **Response:**
```json
{
  "success": true,
  "status": 200,
  "message": "Restaurant retrieved successfully",
  "data": {
    "id": "restaurant-123",
    "name": "Franklin Barbecue",
    "address": "900 E 11th St, Austin, TX 78702",
    "rating": 4.5,
    "priceRange": "$$",
    "categories": ["bbq", "american"],
    "imageUrl": "https://example.com/image.jpg",
    "yelpId": "franklin-barbecue-austin",
    "photos": ["https://example.com/photo1.jpg"],
    "hours": {
      "monday": "11:00 AM - 3:00 PM"
    }
  }
}
```

#### Get Yelp Restaurant Details
- **GET** `/restaurants/yelp/:id`
- **Description:** Get detailed restaurant information from Yelp
- **Authentication:** None required
- **Path Parameters:**
  - `id`: Yelp business ID
- **Example:** `GET /restaurants/yelp/franklin-barbecue-austin`

#### Get Yelp Restaurant Reviews
- **GET** `/restaurants/yelp/:id/reviews`
- **Description:** Get restaurant reviews from Yelp
- **Authentication:** None required
- **Path Parameters:**
  - `id`: Yelp business ID
- **Example:** `GET /restaurants/yelp/franklin-barbecue-austin/reviews`

#### Sync Restaurant with Yelp
- **POST** `/restaurants/sync`
- **Description:** Sync restaurant data with Yelp
- **Authentication:** None required
- **Request Body:**
```json
{
  "yelpId": "franklin-barbecue-austin"
}
```
- **Response:**
```json
{
  "success": true,
  "status": 200,
  "message": "Restaurant synced successfully",
  "data": {
    "restaurant": {
      "id": "restaurant-123",
      "name": "Franklin Barbecue",
      "yelpId": "franklin-barbecue-austin"
    },
    "synced": true
  }
}
```

#### Austin-Specific Endpoints

##### Get Austin BBQ Restaurants
- **GET** `/restaurants/austin/bbq`
- **Description:** Get BBQ restaurants in Austin
- **Authentication:** None required

##### Get Austin Tex-Mex Restaurants
- **GET** `/restaurants/austin/tex-mex`
- **Description:** Get Tex-Mex restaurants in Austin
- **Authentication:** None required

##### Get Austin Food Trucks
- **GET** `/restaurants/austin/food-trucks`
- **Description:** Get food trucks in Austin
- **Authentication:** None required

### Authentication Endpoints

#### Login
- **POST** `/auth/login`
- **Description:** Authenticate user (mock for development)
- **Authentication:** None required
- **Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```
- **Response:**
```json
{
  "success": true,
  "status": 200,
  "message": "Login successful",
  "data": {
    "user": {
      "id": "user-123",
      "email": "user@example.com",
      "name": "Test User",
      "provider": "email",
      "createdAt": "2024-01-15T10:30:00.000Z"
    },
    "token": "mock-token-1234567890",
    "expiresAt": "2024-01-16T10:30:00.000Z"
  }
}
```

#### Logout
- **POST** `/auth/logout`
- **Description:** Logout user
- **Authentication:** Required
- **Response:**
```json
{
  "success": true,
  "status": 200,
  "message": "Logout successful",
  "data": null
}
```

#### Get Current User
- **GET** `/auth/me`
- **Description:** Get current authenticated user information
- **Authentication:** Required
- **Response:**
```json
{
  "success": true,
  "status": 200,
  "message": "User information retrieved successfully",
  "data": {
    "id": "user-123",
    "email": "user@example.com",
    "name": "Test User",
    "provider": "email",
    "createdAt": "2024-01-15T10:30:00.000Z"
  }
}
```

#### Refresh Token
- **POST** `/auth/refresh`
- **Description:** Refresh authentication token
- **Authentication:** Required
- **Response:**
```json
{
  "success": true,
  "status": 200,
  "message": "Token refreshed successfully",
  "data": {
    "token": "refreshed-token-1234567890",
    "expiresAt": "2024-01-16T10:30:00.000Z"
  }
}
```

#### Check Authentication Status
- **GET** `/auth/status`
- **Description:** Check if user is authenticated
- **Authentication:** Required
- **Response:**
```json
{
  "success": true,
  "status": 200,
  "message": "Authentication status verified",
  "data": {
    "authenticated": true,
    "user": {
      "id": "user-123",
      "email": "user@example.com",
      "name": "Test User"
    },
    "tokenValid": true
  }
}
```

### User Endpoints

#### Get User RSVPs
- **GET** `/users/rsvps`
- **Description:** Get user's RSVPs
- **Authentication:** Required
- **Response:**
```json
{
  "success": true,
  "status": 200,
  "message": "User RSVPs retrieved successfully",
  "data": [
    {
      "id": "rsvp-123",
      "day": "friday",
      "status": "going",
      "createdAt": "2024-01-15T10:30:00.000Z",
      "restaurant": {
        "id": "restaurant-123",
        "name": "Franklin Barbecue",
        "imageUrl": "https://example.com/image.jpg",
        "rating": 4.5,
        "address": "900 E 11th St, Austin, TX 78702"
      }
    }
  ]
}
```

#### Create/Update RSVP
- **POST** `/users/rsvps`
- **Description:** Create or update user RSVP
- **Authentication:** Required
- **Request Body:**
```json
{
  "restaurantId": "restaurant-123",
  "day": "friday",
  "status": "going"
}
```
- **Response:**
```json
{
  "success": true,
  "status": 200,
  "message": "RSVP saved successfully",
  "data": {
    "id": "rsvp-123",
    "userId": "user-123",
    "restaurantId": "restaurant-123",
    "day": "friday",
    "status": "going",
    "createdAt": "2024-01-15T10:30:00.000Z",
    "restaurant": {
      "id": "restaurant-123",
      "name": "Franklin Barbecue",
      "imageUrl": "https://example.com/image.jpg",
      "rating": 4.5,
      "address": "900 E 11th St, Austin, TX 78702"
    }
  }
}
```

#### Get User Wishlist
- **GET** `/users/wishlist`
- **Description:** Get user's wishlist
- **Authentication:** Required
- **Response:**
```json
{
  "success": true,
  "status": 200,
  "message": "User wishlist retrieved successfully",
  "data": [
    {
      "id": "wishlist-123",
      "createdAt": "2024-01-15T10:30:00.000Z",
      "restaurant": {
        "id": "restaurant-123",
        "name": "Franklin Barbecue",
        "imageUrl": "https://example.com/image.jpg",
        "rating": 4.5,
        "address": "900 E 11th St, Austin, TX 78702",
        "priceRange": "$$",
        "categories": ["bbq", "american"]
      }
    }
  ]
}
```

#### Add to Wishlist
- **POST** `/users/wishlist`
- **Description:** Add restaurant to wishlist
- **Authentication:** Required
- **Request Body:**
```json
{
  "restaurantId": "restaurant-123"
}
```
- **Response:**
```json
{
  "success": true,
  "status": 200,
  "message": "Restaurant added to wishlist successfully",
  "data": {
    "id": "wishlist-123",
    "userId": "user-123",
    "restaurantId": "restaurant-123",
    "createdAt": "2024-01-15T10:30:00.000Z",
    "restaurant": {
      "id": "restaurant-123",
      "name": "Franklin Barbecue",
      "imageUrl": "https://example.com/image.jpg",
      "rating": 4.5,
      "address": "900 E 11th St, Austin, TX 78702",
      "priceRange": "$$",
      "categories": ["bbq", "american"]
    }
  }
}
```

#### Remove from Wishlist
- **DELETE** `/users/wishlist/:id`
- **Description:** Remove restaurant from wishlist
- **Authentication:** Required
- **Path Parameters:**
  - `id`: Wishlist item ID
- **Example:** `DELETE /users/wishlist/wishlist-123`
- **Response:**
```json
{
  "success": true,
  "status": 200,
  "message": "Restaurant removed from wishlist successfully",
  "data": null
}
```

#### Get User Profile
- **GET** `/users/profile`
- **Description:** Get user profile information
- **Authentication:** Required
- **Response:**
```json
{
  "success": true,
  "status": 200,
  "message": "User profile retrieved successfully",
  "data": {
    "id": "user-123",
    "email": "user@example.com",
    "name": "Test User",
    "avatar": "https://example.com/avatar.jpg",
    "provider": "email",
    "createdAt": "2024-01-15T10:30:00.000Z",
    "lastLoginAt": "2024-01-15T10:30:00.000Z"
  }
}
```

#### Update User Profile
- **PUT** `/users/profile`
- **Description:** Update user profile information
- **Authentication:** Required
- **Request Body:**
```json
{
  "name": "Updated Name",
  "avatar": "https://example.com/new-avatar.jpg"
}
```
- **Response:**
```json
{
  "success": true,
  "status": 200,
  "message": "User profile updated successfully",
  "data": {
    "id": "user-123",
    "email": "user@example.com",
    "name": "Updated Name",
    "avatar": "https://example.com/new-avatar.jpg",
    "provider": "email",
    "createdAt": "2024-01-15T10:30:00.000Z",
    "lastLoginAt": "2024-01-15T10:30:00.000Z"
  }
}
```

### System Endpoints

#### Get System Status
- **GET** `/system/status`
- **Description:** Get overall system status
- **Authentication:** None required
- **Response:**
```json
{
  "success": true,
  "status": 200,
  "message": "System status retrieved successfully",
  "data": {
    "api": {
      "status": "healthy",
      "version": "1.0.0",
      "uptime": 3600
    },
    "database": {
      "status": "connected"
    },
    "yelp": {
      "status": "configured"
    },
    "cache": {
      "status": "active"
    },
    "cron": {
      "status": "running"
    }
  }
}
```

#### Get System Statistics
- **GET** `/system/stats`
- **Description:** Get system usage statistics
- **Authentication:** None required
- **Response:**
```json
{
  "success": true,
  "status": 200,
  "message": "System statistics retrieved successfully",
  "data": {
    "restaurants": 150,
    "users": 25,
    "rsvps": 300,
    "wishlistItems": 75,
    "timestamp": "2024-01-15T10:30:00.000Z"
  }
}
```

#### Sync All Restaurants
- **POST** `/system/sync/restaurants`
- **Description:** Sync all restaurants with Yelp
- **Authentication:** None required
- **Response:**
```json
{
  "success": true,
  "status": 200,
  "message": "Restaurant sync completed successfully",
  "data": {
    "synced": 50,
    "failed": 0,
    "total": 50
  }
}
```

#### Rotate Featured Restaurant
- **POST** `/system/featured/rotate`
- **Description:** Manually rotate featured restaurant
- **Authentication:** None required
- **Response:**
```json
{
  "success": true,
  "status": 200,
  "message": "Featured restaurant rotated successfully",
  "data": {
    "restaurant": {
      "id": "restaurant-456",
      "name": "New Featured Restaurant"
    },
    "rotated": true
  }
}
```

#### Get Cache Statistics
- **GET** `/system/cache/stats`
- **Description:** Get cache performance statistics
- **Authentication:** None required
- **Response:**
```json
{
  "success": true,
  "status": 200,
  "message": "Cache statistics retrieved successfully",
  "data": {
    "hits": 1250,
    "misses": 150,
    "size": "50MB",
    "keys": 500
  }
}
```

#### Clear All Cache
- **DELETE** `/system/cache`
- **Description:** Clear all cached data
- **Authentication:** None required
- **Response:**
```json
{
  "success": true,
  "status": 200,
  "message": "Cache cleared successfully",
  "data": null
}
```

#### Detailed Health Check
- **GET** `/system/health`
- **Description:** Get detailed system health information
- **Authentication:** None required
- **Response:**
```json
{
  "success": true,
  "status": 200,
  "message": "Health check completed successfully",
  "data": {
    "status": "healthy",
    "timestamp": "2024-01-15T10:30:00.000Z",
    "services": {
      "database": {
        "status": "healthy",
        "responseTime": "< 10ms"
      },
      "yelp": {
        "status": "healthy",
        "responseTime": "150ms"
      },
      "cache": {
        "status": "healthy",
        "responseTime": "< 1ms"
      }
    },
    "uptime": 3600,
    "memory": {
      "rss": 50000000,
      "heapTotal": 20000000,
      "heapUsed": 15000000
    },
    "version": "1.0.0"
  }
}
```

## Error Codes

| Code | Description |
|------|-------------|
| `MISSING_CREDENTIALS` | Email and password are required for login |
| `MISSING_LOCATION` | Location parameter is required for search |
| `MISSING_YELP_ID` | Yelp ID is required for sync operations |
| `MISSING_RSVP_DATA` | Restaurant ID, day, and status are required for RSVP |
| `MISSING_RESTAURANT_ID` | Restaurant ID is required for wishlist operations |
| `RESTAURANT_NOT_FOUND` | Restaurant with specified ID not found |
| `USER_NOT_FOUND` | User with specified ID not found |
| `WISHLIST_ITEM_NOT_FOUND` | Wishlist item with specified ID not found |
| `NO_FEATURED_RESTAURANT` | No featured restaurant currently set |
| `ALREADY_IN_WISHLIST` | Restaurant already exists in user's wishlist |
| `UNAUTHORIZED` | Authentication required |
| `FORBIDDEN` | Access forbidden |

## Rate Limiting

The API implements rate limiting to prevent abuse:
- **Yelp API calls:** 5000 requests per day (free tier)
- **General API calls:** 1000 requests per hour per IP
- **Authentication attempts:** 10 attempts per minute per IP

Rate limit headers are included in responses:
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1642248000
```

## Caching

The API uses intelligent caching to improve performance:
- **Restaurant details:** Cached for 1 hour
- **Search results:** Cached for 24 hours
- **Yelp reviews:** Cached for 6 hours
- **Featured restaurant:** Cached for 1 week

Cache can be bypassed with `?fresh=true` parameter.

## Examples

### Complete Workflow Example

1. **Get API status:**
```bash
curl -X GET http://localhost:3001/api/v1/health
```

2. **Search for BBQ restaurants:**
```bash
curl -X GET "http://localhost:3001/api/v1/restaurants/search?location=Austin%2CTX&cuisine=bbq&limit=5"
```

3. **Get featured restaurant:**
```bash
curl -X GET http://localhost:3001/api/v1/restaurants/featured
```

4. **Login (mock):**
```bash
curl -X POST http://localhost:3001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "password123"}'
```

5. **Create RSVP:**
```bash
curl -X POST http://localhost:3001/api/v1/users/rsvps \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer mock-token-1234567890" \
  -d '{"restaurantId": "restaurant-123", "day": "friday", "status": "going"}'
```

6. **Add to wishlist:**
```bash
curl -X POST http://localhost:3001/api/v1/users/wishlist \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer mock-token-1234567890" \
  -d '{"restaurantId": "restaurant-123"}'
```

## Support

For API support or questions:
- Check the health endpoint: `GET /api/v1/health`
- Review system status: `GET /api/v1/system/status`
- Check API information: `GET /api/v1/info`

All endpoints return consistent JSON responses with appropriate HTTP status codes and error messages.
