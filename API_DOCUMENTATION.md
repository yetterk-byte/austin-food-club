# Austin Food Club API Documentation

## Overview

The Austin Food Club API follows a standardized response format to ensure consistency, reliability, and ease of integration across all endpoints. This documentation provides comprehensive guidelines for API development and usage.

## Table of Contents

1. [Response Format](#response-format)
2. [Authentication](#authentication)
3. [Error Handling](#error-handling)
4. [Validation](#validation)
5. [Endpoint Examples](#endpoint-examples)
6. [Development Guidelines](#development-guidelines)
7. [Testing](#testing)

## Response Format

### Standardized Response Structure

All API responses follow this consistent format:

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

### Success Response

```json
{
  "success": true,
  "message": "Operation completed successfully",
  "timestamp": "2025-09-28T16:09:17.248Z",
  "data": {
    // Response data here
  }
}
```

### Error Response

```json
{
  "success": false,
  "message": "Error description",
  "timestamp": "2025-09-28T16:09:17.248Z",
  "error": "ERROR_CODE",
  "data": {
    "errors": ["Detailed error messages"]
  }
}
```

### Paginated Response

```json
{
  "success": true,
  "message": "Data retrieved successfully",
  "timestamp": "2025-09-28T16:09:17.248Z",
  "data": [
    // Array of items
  ],
  "meta": {
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 100,
      "totalPages": 5
    }
  }
}
```

## Authentication

### Bearer Token Authentication

Most endpoints require authentication using Bearer tokens:

```http
Authorization: Bearer <token>
```

### Admin Authentication

Admin endpoints use demo tokens for development:

```http
Authorization: Bearer demo-admin-token-<timestamp>
```

## Error Handling

### HTTP Status Codes

- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `422` - Validation Error
- `500` - Internal Server Error

### Error Codes

| Code | Description |
|------|-------------|
| `VALIDATION_ERROR` | Input validation failed |
| `UNAUTHORIZED` | Authentication required |
| `FORBIDDEN` | Insufficient permissions |
| `NOT_FOUND` | Resource not found |
| `DUPLICATE_RESOURCE` | Resource already exists |
| `SERVICE_UNAVAILABLE` | External service unavailable |

## Validation

### Input Validation Rules

The API uses centralized validation middleware with predefined rules:

```javascript
// Example validation rules
const rules = {
  email: {
    required: true,
    type: 'email',
    message: 'Valid email address is required'
  },
  password: {
    required: true,
    type: 'string',
    minLength: 6,
    message: 'Password must be at least 6 characters'
  }
};
```

### Validation Error Response

```json
{
  "success": false,
  "message": "Validation failed",
  "timestamp": "2025-09-28T16:09:17.248Z",
  "data": {
    "errors": [
      "Valid email address is required",
      "Password must be at least 6 characters"
    ]
  },
  "error": "VALIDATION_ERROR"
}
```

## Endpoint Examples

### 1. Restaurant Endpoints

#### Get Current Featured Restaurant

```http
GET /api/restaurants/current?citySlug=austin
```

**Response:**
```json
{
  "success": true,
  "message": "Restaurant retrieved successfully",
  "timestamp": "2025-09-28T16:09:17.248Z",
  "data": {
    "id": "cmfwtevih000askx38e0pcgei",
    "name": "Sundance BBQ",
    "address": "8116 Thomas Springs Rd and Cir Dr",
    "cityName": "Austin",
    "state": "TX",
    "phone": "(512) 507-9693",
    "rating": 5,
    "price": "$",
    "categories": [
      {
        "alias": "bbq",
        "title": "Barbeque"
      }
    ],
    "isFeatured": true,
    "city": {
      "id": "austin",
      "name": "Austin",
      "displayName": "Austin Food Club",
      "isActive": true
    }
  }
}
```

#### Search Restaurants

```http
GET /api/restaurants/search?term=Franklin&location=Austin,TX&limit=20
```

**Response:**
```json
{
  "success": true,
  "message": "Restaurant search completed successfully",
  "timestamp": "2025-09-28T16:09:17.248Z",
  "data": {
    "restaurants": [
      {
        "id": "franklin-bbq",
        "name": "Franklin Barbecue",
        "address": "900 E 11th St",
        "rating": 4.5,
        "priceRange": "$$",
        "categories": ["bbq", "american"]
      }
    ],
    "total": 1,
    "region": {
      "center": {
        "latitude": 30.2672,
        "longitude": -97.7431
      }
    },
    "searchParams": {
      "location": "Austin,TX",
      "term": "Franklin",
      "limit": 20
    }
  }
}
```

### 2. Social Endpoints

#### Get Friends List

```http
GET /api/friends/user/1
```

**Response:**
```json
{
  "success": true,
  "message": "Friends retrieved successfully",
  "timestamp": "2025-09-28T16:09:17.248Z",
  "data": {
    "userId": "1",
    "friends": [
      {
        "id": "friend_1",
        "userId": "1",
        "friendId": "3",
        "createdAt": "2024-01-15T00:00:00.000Z",
        "friendUser": {
          "id": "3",
          "email": "sarah.johnson@email.com",
          "name": "Sarah Johnson",
          "isVerified": true,
          "createdAt": "2024-01-10T00:00:00.000Z"
        }
      }
    ]
  }
}
```

#### Get Social Feed

```http
GET /api/social-feed/user/1
```

**Response:**
```json
{
  "success": true,
  "message": "Social feed retrieved successfully",
  "timestamp": "2025-09-28T16:09:17.248Z",
  "data": {
    "userId": "1",
    "activities": [
      {
        "id": "activity_1",
        "userId": "3",
        "type": "verified_visit",
        "createdAt": "2025-09-27T16:01:23.823Z",
        "user": {
          "id": "3",
          "name": "Sarah Johnson",
          "email": "sarah.johnson@email.com",
          "isVerified": true
        },
        "restaurant": {
          "id": "rest_1",
          "name": "Franklin Barbecue",
          "address": "900 E 11th St"
        },
        "rating": 5,
        "photoUrl": "https://example.com/photo.jpg"
      }
    ]
  }
}
```

#### Get City Activity

```http
GET /api/city-activity/user/1
```

**Response:**
```json
{
  "success": true,
  "message": "City activity retrieved successfully",
  "timestamp": "2025-09-28T16:09:17.248Z",
  "data": {
    "userId": "1",
    "activities": [
      {
        "id": "city_1",
        "userId": "8",
        "type": "verified_visit",
        "createdAt": "2025-09-27T16:01:23.823Z",
        "user": {
          "id": "8",
          "name": "Jessica Taylor",
          "email": "jessica.taylor@email.com",
          "isVerified": true
        },
        "restaurant": {
          "id": "rest_6",
          "name": "Salt Traders Coastal Cooking",
          "address": "1101 S Lamar Blvd"
        },
        "rating": 4.4,
        "photoUrl": "https://images.unsplash.com/photo-1551218808-94e220e084d2?w=800&h=600&fit=crop"
      }
    ]
  }
}
```

### 3. Verified Visits

#### Get User Verified Visits

```http
GET /api/verified-visits/user/1
```

**Response:**
```json
{
  "success": true,
  "message": "Verified visits retrieved successfully",
  "timestamp": "2025-09-28T16:09:17.248Z",
  "data": {
    "userId": "1",
    "visits": [
      {
        "id": 1,
        "userId": "1",
        "restaurantId": "sundance-bbq-1",
        "restaurantName": "Sundance BBQ",
        "restaurantAddress": "8116 Thomas Springs Rd and Cir Dr",
        "rating": 5,
        "imageUrl": "https://example.com/photo1.jpg",
        "verifiedAt": "2024-01-15T18:30:00Z",
        "citySlug": "austin"
      }
    ],
    "total": 1
  }
}
```

#### Create Verified Visit

```http
POST /api/verified-visits
Content-Type: application/json

{
  "userId": "1",
  "restaurantId": "franklin-bbq",
  "restaurantName": "Franklin Barbecue",
  "restaurantAddress": "900 E 11th St",
  "rating": 5,
  "imageUrl": "https://example.com/photo.jpg",
  "citySlug": "austin"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Visit verified successfully",
  "timestamp": "2025-09-28T16:09:17.248Z",
  "data": {
    "id": 2,
    "userId": "1",
    "restaurantId": "franklin-bbq",
    "restaurantName": "Franklin Barbecue",
    "restaurantAddress": "900 E 11th St",
    "rating": 5,
    "imageUrl": "https://example.com/photo.jpg",
    "verifiedAt": "2025-09-28T16:09:17.248Z",
    "citySlug": "austin"
  }
}
```

### 4. Authentication

#### Admin Login

```http
POST /api/auth/admin-login
Content-Type: application/json

{
  "email": "admin@austinfoodclub.com",
  "password": "admin123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "timestamp": "2025-09-28T16:09:17.248Z",
  "data": {
    "token": "demo-admin-token-1759075097488",
    "admin": {
      "id": "admin-user",
      "email": "admin@austinfoodclub.com",
      "name": "Austin Food Club Admin",
      "isAdmin": true
    }
  }
}
```

### 5. RSVP Endpoints

#### Create RSVP

```http
POST /api/rsvp
Authorization: Bearer <token>
Content-Type: application/json

{
  "day": "friday",
  "status": "going",
  "restaurantId": "franklin-bbq"
}
```

**Response:**
```json
{
  "success": true,
  "message": "RSVP saved successfully",
  "timestamp": "2025-09-28T16:09:17.248Z",
  "data": {
    "id": "rsvp_123",
    "userId": "user_1",
    "restaurantId": "franklin-bbq",
    "day": "friday",
    "status": "going",
    "createdAt": "2025-09-28T16:09:17.248Z"
  }
}
```

#### Get RSVP Counts

```http
GET /api/rsvp/counts?restaurantId=franklin-bbq
```

**Response:**
```json
{
  "success": true,
  "message": "RSVP counts retrieved successfully",
  "timestamp": "2025-09-28T16:09:17.248Z",
  "data": {
    "restaurantId": "franklin-bbq",
    "dayCounts": {
      "friday": 15,
      "saturday": 8,
      "sunday": 3
    },
    "totalGoing": 26
  }
}
```

## Development Guidelines

### 1. Creating New Endpoints

When creating new endpoints, follow this pattern:

```javascript
// Import required middleware
const { asyncHandler, NotFoundError, AppError } = require('../middleware/errorHandler');
const { validate, validateQuery, validateId } = require('../middleware/validation');

// Define endpoint with proper middleware
app.get('/api/example/:id', 
  validateId('id'),
  validateQuery({
    limit: { required: false, type: 'number', min: 1, max: 100 }
  }),
  asyncHandler(async (req, res) => {
    const { id } = req.params;
    const { limit = 20 } = req.query;
    
    // Your business logic here
    const data = await getExampleData(id, limit);
    
    if (!data) {
      throw new NotFoundError('Example not found');
    }
    
    res.api.success.ok(res, 'Example retrieved successfully', data);
  })
);
```

### 2. Error Handling

Always use the standardized error classes:

```javascript
// For validation errors
throw new ValidationError('Invalid input data');

// For not found errors
throw new NotFoundError('Resource not found');

// For authorization errors
throw new UnauthorizedError('Access denied');

// For custom errors
throw new AppError('Custom error message', 400, 'CUSTOM_ERROR');
```

### 3. Response Helpers

Use the response helper methods:

```javascript
// Success responses
res.api.success.ok(res, 'Data retrieved successfully', data);
res.api.success.created(res, 'Resource created successfully', data);
res.api.success.accepted(res, 'Request accepted', data);

// Error responses
res.api.error.badRequest(res, 'Invalid request', 'BAD_REQUEST');
res.api.error.notFound(res, 'Resource not found', 'NOT_FOUND');
res.api.error.unauthorized(res, 'Authentication required', 'UNAUTHORIZED');

// Paginated responses
res.api.paginated(res, data, page, limit, total, 'Data retrieved successfully');
```

### 4. Validation Rules

Define validation rules in the centralized rules object:

```javascript
const rules = {
  example: {
    name: {
      required: true,
      type: 'string',
      minLength: 2,
      maxLength: 100,
      message: 'Name must be between 2 and 100 characters'
    },
    email: {
      required: true,
      type: 'email',
      message: 'Valid email address is required'
    },
    age: {
      required: false,
      type: 'number',
      min: 0,
      max: 120,
      message: 'Age must be between 0 and 120'
    }
  }
};
```

## Testing

### API Testing Script

Use this Node.js script to test API endpoints:

```javascript
const endpoints = [
  { method: 'GET', url: 'http://localhost:3001/api/test' },
  { method: 'POST', url: 'http://localhost:3001/api/auth/admin-login', 
    body: { email: 'admin@austinfoodclub.com', password: 'admin123' } },
  { method: 'GET', url: 'http://localhost:3001/api/restaurants/current' },
  { method: 'GET', url: 'http://localhost:3001/api/friends/user/1' },
  { method: 'GET', url: 'http://localhost:3001/api/social-feed/user/1' },
  { method: 'GET', url: 'http://localhost:3001/api/verified-visits/user/1' },
  { method: 'GET', url: 'http://localhost:3001/api/city-activity/user/1' }
];

async function testEndpoint(endpoint) {
  const response = await fetch(endpoint.url, {
    method: endpoint.method,
    headers: { 'Content-Type': 'application/json' },
    body: endpoint.body ? JSON.stringify(endpoint.body) : undefined
  });
  
  const data = await response.json();
  
  return {
    endpoint: endpoint.url,
    status: response.status,
    success: data.success !== undefined && data.message && data.timestamp,
    hasTimestamp: !!data.timestamp,
    hasMessage: !!data.message,
    hasSuccess: data.success !== undefined
  };
}

// Run tests
async function runTests() {
  console.log('🧪 Testing API Response Standardization...\n');
  
  const results = [];
  for (const endpoint of endpoints) {
    const result = await testEndpoint(endpoint);
    results.push(result);
    
    const status = result.success ? '✅' : '❌';
    console.log(`${status} ${endpoint.method} ${endpoint.url}`);
    console.log(`   Status: ${result.status}`);
    if (result.success) {
      console.log(`   ✓ Has success field: ${result.hasSuccess}`);
      console.log(`   ✓ Has message field: ${result.hasMessage}`);
      console.log(`   ✓ Has timestamp field: ${result.hasTimestamp}`);
    }
    console.log('');
  }
  
  const successCount = results.filter(r => r.success).length;
  const totalCount = results.length;
  const successRate = Math.round((successCount / totalCount) * 100);
  
  console.log(`📊 Results: ${successCount}/${totalCount} endpoints (${successRate}%) using standardized format`);
}

runTests().catch(console.error);
```

### cURL Examples

```bash
# Test basic endpoint
curl -X GET http://localhost:3001/api/test | jq .

# Test admin login
curl -X POST http://localhost:3001/api/auth/admin-login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@austinfoodclub.com","password":"admin123"}' | jq .

# Test restaurant endpoint
curl -X GET "http://localhost:3001/api/restaurants/current?citySlug=austin" | jq .

# Test social endpoints
curl -X GET http://localhost:3001/api/friends/user/1 | jq .
curl -X GET http://localhost:3001/api/social-feed/user/1 | jq .
curl -X GET http://localhost:3001/api/city-activity/user/1 | jq .

# Test validation
curl -X POST http://localhost:3001/api/auth/admin-login \
  -H "Content-Type: application/json" \
  -d '{"email":"invalid","password":"admin123"}' | jq .
```

## Frontend Integration

### Flutter Service Pattern

When integrating with Flutter, follow this pattern for handling standardized responses:

```dart
static Future<List<Map<String, dynamic>>> getData(String userId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/data/user/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      
      // Handle standardized API response format
      if (responseData['success'] == true && responseData['data'] != null) {
        final Map<String, dynamic> data = responseData['data'] as Map<String, dynamic>;
        if (data['items'] != null) {
          final List<dynamic> items = data['items'] as List<dynamic>;
          return items.cast<Map<String, dynamic>>();
        }
      }
      
      // Fallback to old format for backward compatibility
      if (responseData is List) {
        return (responseData as List<dynamic>).cast<Map<String, dynamic>>();
      }
      
      print('❌ Unexpected response format');
      return [];
    } else {
      print('❌ Failed to get data: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    print('❌ Error getting data: $e');
    return [];
  }
}
```

## Best Practices

1. **Always use the standardized response format**
2. **Include proper error handling with try-catch blocks**
3. **Use validation middleware for input validation**
4. **Include meaningful error messages**
5. **Add proper HTTP status codes**
6. **Include timestamps for all responses**
7. **Use pagination for large datasets**
8. **Implement proper authentication checks**
9. **Add comprehensive logging**
10. **Write tests for all endpoints**

## Conclusion

This standardized API format ensures:

- **Consistency** across all endpoints
- **Reliability** with proper error handling
- **Maintainability** with centralized middleware
- **Developer Experience** with predictable response formats
- **Scalability** for future API development

Follow these guidelines when creating new endpoints to maintain the high quality and consistency of the Austin Food Club API.

