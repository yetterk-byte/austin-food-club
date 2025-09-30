# Austin Food Club Developer Guide

## Quick Start

This guide provides step-by-step instructions for implementing new API endpoints that follow our standardized response format.

## Prerequisites

- Node.js server running on port 3001
- Understanding of Express.js
- Familiarity with our middleware system

## Step-by-Step Implementation

### 1. Choose Your Endpoint Location

Decide where to implement your endpoint:

- **`server.js`** - For simple, standalone endpoints
- **`routes/` directory** - For grouped endpoints (recommended)
- **Existing route files** - For related functionality

### 2. Import Required Middleware

```javascript
const { asyncHandler, NotFoundError, AppError, ValidationError } = require('../middleware/errorHandler');
const { validate, validateQuery, validateId } = require('../middleware/validation');
```

### 3. Define Validation Rules (if needed)

```javascript
const rules = {
  createUser: {
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

### 4. Implement Your Endpoint

#### GET Endpoint Example

```javascript
app.get('/api/users/:id', 
  validateId('id'),
  validateQuery({
    include: { required: false, type: 'string', enum: ['profile', 'posts'] },
    limit: { required: false, type: 'number', min: 1, max: 100 }
  }),
  asyncHandler(async (req, res) => {
    const { id } = req.params;
    const { include, limit = 20 } = req.query;
    
    console.log(`🔍 Getting user ${id} with include: ${include}`);
    
    // Your business logic here
    const user = await getUserById(id, { include, limit });
    
    if (!user) {
      throw new NotFoundError('User not found');
    }
    
    res.api.success.ok(res, 'User retrieved successfully', user);
  })
);
```

#### POST Endpoint Example

```javascript
app.post('/api/users', 
  validate(rules.createUser),
  asyncHandler(async (req, res) => {
    const { name, email, age } = req.body;
    
    console.log(`🔍 Creating user: ${name} (${email})`);
    
    // Check if user already exists
    const existingUser = await getUserByEmail(email);
    if (existingUser) {
      throw new AppError('User with this email already exists', 400, 'DUPLICATE_USER');
    }
    
    // Create new user
    const newUser = await createUser({ name, email, age });
    
    console.log(`✅ Created user: ${newUser.id}`);
    
    res.api.success.created(res, 'User created successfully', newUser);
  })
);
```

#### PUT/PATCH Endpoint Example

```javascript
app.put('/api/users/:id', 
  validateId('id'),
  validate({
    name: { required: false, type: 'string', minLength: 2, maxLength: 100 },
    email: { required: false, type: 'email' },
    age: { required: false, type: 'number', min: 0, max: 120 }
  }),
  asyncHandler(async (req, res) => {
    const { id } = req.params;
    const updates = req.body;
    
    console.log(`🔍 Updating user ${id}`);
    
    // Check if user exists
    const existingUser = await getUserById(id);
    if (!existingUser) {
      throw new NotFoundError('User not found');
    }
    
    // Update user
    const updatedUser = await updateUser(id, updates);
    
    console.log(`✅ Updated user: ${id}`);
    
    res.api.success.ok(res, 'User updated successfully', updatedUser);
  })
);
```

#### DELETE Endpoint Example

```javascript
app.delete('/api/users/:id', 
  validateId('id'),
  asyncHandler(async (req, res) => {
    const { id } = req.params;
    
    console.log(`🔍 Deleting user ${id}`);
    
    // Check if user exists
    const existingUser = await getUserById(id);
    if (!existingUser) {
      throw new NotFoundError('User not found');
    }
    
    // Delete user
    await deleteUser(id);
    
    console.log(`✅ Deleted user: ${id}`);
    
    res.api.success.ok(res, 'User deleted successfully', {
      id,
      deletedAt: new Date().toISOString()
    });
  })
);
```

### 5. Add Authentication (if needed)

```javascript
const { authenticateToken } = require('../middleware/auth');
const { requireAdmin } = require('../middleware/adminAuth');

// For user authentication
app.get('/api/protected-endpoint', 
  authenticateToken,
  asyncHandler(async (req, res) => {
    // req.user is available here
    res.api.success.ok(res, 'Protected data retrieved', req.user);
  })
);

// For admin authentication
app.get('/api/admin-endpoint', 
  requireAdmin,
  asyncHandler(async (req, res) => {
    // req.admin is available here
    res.api.success.ok(res, 'Admin data retrieved', req.admin);
  })
);
```

### 6. Implement Pagination (for list endpoints)

```javascript
app.get('/api/users', 
  validateQuery({
    page: { required: false, type: 'number', min: 1 },
    limit: { required: false, type: 'number', min: 1, max: 100 },
    search: { required: false, type: 'string', maxLength: 100 }
  }),
  asyncHandler(async (req, res) => {
    const { page = 1, limit = 20, search } = req.query;
    
    console.log(`🔍 Getting users - page: ${page}, limit: ${limit}, search: ${search}`);
    
    const { users, total } = await getUsers({ page, limit, search });
    
    res.api.paginated(res, users, page, limit, total, 'Users retrieved successfully');
  })
);
```

### 7. Add Error Handling

```javascript
app.get('/api/users/:id', 
  validateId('id'),
  asyncHandler(async (req, res) => {
    const { id } = req.params;
    
    try {
      const user = await getUserById(id);
      
      if (!user) {
        throw new NotFoundError('User not found');
      }
      
      res.api.success.ok(res, 'User retrieved successfully', user);
    } catch (error) {
      // Handle specific database errors
      if (error.code === 'DATABASE_CONNECTION_ERROR') {
        throw new AppError('Database temporarily unavailable', 503, 'SERVICE_UNAVAILABLE');
      }
      
      // Re-throw other errors to be handled by global error handler
      throw error;
    }
  })
);
```

## Response Helper Methods

Use these helper methods for consistent responses:

### Success Responses

```javascript
// 200 OK
res.api.success.ok(res, 'Data retrieved successfully', data);

// 201 Created
res.api.success.created(res, 'Resource created successfully', data);

// 202 Accepted
res.api.success.accepted(res, 'Request accepted', data);

// 204 No Content
res.api.success.noContent(res, 'Operation completed successfully');
```

### Error Responses

```javascript
// 400 Bad Request
res.api.error.badRequest(res, 'Invalid request data', 'BAD_REQUEST');

// 401 Unauthorized
res.api.error.unauthorized(res, 'Authentication required', 'UNAUTHORIZED');

// 403 Forbidden
res.api.error.forbidden(res, 'Insufficient permissions', 'FORBIDDEN');

// 404 Not Found
res.api.error.notFound(res, 'Resource not found', 'NOT_FOUND');

// 422 Validation Error
res.api.error.validationError(res, 'Validation failed', 'VALIDATION_ERROR', validationErrors);

// 500 Internal Server Error
res.api.error.internalError(res, 'Internal server error', 'INTERNAL_ERROR');
```

### Paginated Responses

```javascript
res.api.paginated(res, data, page, limit, total, 'Data retrieved successfully');
```

## Validation Rules Reference

### Available Types

- `string` - String validation
- `number` - Number validation
- `boolean` - Boolean validation
- `email` - Email format validation
- `phone` - Phone number validation
- `url` - URL format validation
- `enum` - Enumeration validation
- `array` - Array validation
- `object` - Object validation

### Common Rule Properties

```javascript
{
  required: true,                    // Field is required
  type: 'string',                   // Data type
  minLength: 2,                     // Minimum length (strings)
  maxLength: 100,                   // Maximum length (strings)
  min: 0,                          // Minimum value (numbers)
  max: 120,                        // Maximum value (numbers)
  pattern: /^[A-Za-z]+$/,          // Regex pattern
  enum: ['active', 'inactive'],     // Allowed values
  message: 'Custom error message'  // Custom validation message
}
```

## Testing Your Endpoint

### 1. Manual Testing with cURL

```bash
# Test GET endpoint
curl -X GET "http://localhost:3001/api/users/1" | jq .

# Test POST endpoint
curl -X POST http://localhost:3001/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com","age":30}' | jq .

# Test validation
curl -X POST http://localhost:3001/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"","email":"invalid"}' | jq .
```

### 2. Add to Test Script

Add your endpoint to `test-api-consistency.js`:

```javascript
{
  name: 'Get User',
  method: 'GET',
  url: '/api/users/1',
  expectedStatus: 200
},
{
  name: 'Create User',
  method: 'POST',
  url: '/api/users',
  body: { name: 'Test User', email: 'test@example.com', age: 25 },
  expectedStatus: 201
}
```

### 3. Run Tests

```bash
node test-api-consistency.js
```

## Common Patterns

### 1. Resource with Relationships

```javascript
app.get('/api/users/:id/posts', 
  validateId('id'),
  validateQuery({
    limit: { required: false, type: 'number', min: 1, max: 50 }
  }),
  asyncHandler(async (req, res) => {
    const { id } = req.params;
    const { limit = 20 } = req.query;
    
    const posts = await getUserPosts(id, { limit });
    
    res.api.success.ok(res, 'User posts retrieved successfully', {
      userId: id,
      posts,
      total: posts.length
    });
  })
);
```

### 2. Search Endpoint

```javascript
app.get('/api/search', 
  validateQuery({
    q: { required: true, type: 'string', minLength: 2 },
    type: { required: false, type: 'string', enum: ['users', 'posts', 'all'] },
    limit: { required: false, type: 'number', min: 1, max: 100 }
  }),
  asyncHandler(async (req, res) => {
    const { q, type = 'all', limit = 20 } = req.query;
    
    const results = await searchContent(q, { type, limit });
    
    res.api.success.ok(res, 'Search completed successfully', {
      query: q,
      type,
      results,
      total: results.length
    });
  })
);
```

### 3. Bulk Operations

```javascript
app.post('/api/users/bulk', 
  validate({
    users: {
      required: true,
      type: 'array',
      minLength: 1,
      maxLength: 100,
      items: {
        name: { required: true, type: 'string', minLength: 2 },
        email: { required: true, type: 'email' }
      }
    }
  }),
  asyncHandler(async (req, res) => {
    const { users } = req.body;
    
    const results = await createUsersBulk(users);
    
    res.api.success.created(res, 'Users created successfully', {
      created: results.successful,
      failed: results.failed,
      total: users.length
    });
  })
);
```

## Best Practices

### 1. Logging

Always include meaningful console logs:

```javascript
console.log(`🔍 Getting user ${id}`);
console.log(`✅ User retrieved: ${user.name}`);
console.log(`❌ User not found: ${id}`);
```

### 2. Error Messages

Use descriptive error messages:

```javascript
// Good
throw new NotFoundError('User with ID 123 not found');

// Bad
throw new NotFoundError('Not found');
```

### 3. Response Messages

Use consistent, descriptive messages:

```javascript
// Good
res.api.success.ok(res, 'User retrieved successfully', user);

// Bad
res.api.success.ok(res, 'OK', user);
```

### 4. Input Validation

Always validate input:

```javascript
// Good - validates all inputs
validate({
  name: { required: true, type: 'string', minLength: 2 },
  email: { required: true, type: 'email' }
})

// Bad - no validation
// Direct access to req.body without validation
```

### 5. Error Handling

Handle errors appropriately:

```javascript
// Good - specific error handling
if (!user) {
  throw new NotFoundError('User not found');
}

// Bad - generic error handling
if (!user) {
  throw new Error('Something went wrong');
}
```

## Troubleshooting

### Common Issues

1. **Validation not working**
   - Check that `validate` middleware is imported and used
   - Verify validation rules are correctly defined
   - Ensure `Content-Type: application/json` header is set

2. **Response format not standardized**
   - Use `res.api.success.*` helper methods
   - Don't use `res.json()` directly
   - Check that `responseMiddleware` is applied

3. **Authentication not working**
   - Verify `authenticateToken` or `requireAdmin` middleware is used
   - Check that `Authorization` header is included
   - Ensure token is valid

4. **Errors not handled properly**
   - Use `asyncHandler` wrapper
   - Throw appropriate error classes
   - Don't catch errors unless you can handle them

### Debug Tips

1. **Check server logs** for detailed error information
2. **Use console.log** to debug request/response flow
3. **Test with cURL** to isolate frontend issues
4. **Run consistency tests** to verify format compliance

## Next Steps

1. Implement your endpoint following this guide
2. Test thoroughly with the provided tools
3. Add your endpoint to the test script
4. Update API documentation
5. Consider adding unit tests for complex logic

For more examples, see the existing endpoints in `server.js` and the `routes/` directory.

