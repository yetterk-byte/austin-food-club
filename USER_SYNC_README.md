# User Synchronization System

This document describes the user synchronization system that keeps Supabase users in sync with the Prisma database.

## Overview

The user sync system automatically creates and updates user records in the Prisma database whenever a user authenticates through Supabase. It handles both email/password users and OAuth users (Google, Apple, etc.).

## Components

### 1. Database Schema

The `User` model includes the following fields for comprehensive user data:

```prisma
model User {
  id            String    @id @default(cuid())
  supabaseId    String    @unique
  email         String?   @unique
  phone         String?   @unique
  name          String
  avatar        String?   // URL for user avatar (from OAuth providers)
  provider      String?   // "email", "google", "apple", etc.
  emailVerified Boolean   @default(false)
  lastLogin     DateTime?
  createdAt     DateTime  @default(now())
  // ... relations
}
```

### 2. User Sync Utility (`server/src/utils/userSync.js`)

The utility provides functions to sync Supabase users with Prisma:

#### `syncUser(supabaseUser)`
- Syncs real Supabase users (email, OAuth)
- Extracts provider type, avatar, name, and email verification status
- Creates or updates user records
- Handles unique constraint violations gracefully

#### `syncMockUser(mockUser)`
- Syncs mock users for development/testing
- Similar functionality to `syncUser` but for test data

#### Helper Functions
- `getProviderType(supabaseUser)` - Extracts provider from user metadata
- `getAvatarUrl(supabaseUser)` - Extracts avatar URL from various OAuth sources
- `getUserName(supabaseUser)` - Extracts display name with fallbacks
- `isEmailVerified(supabaseUser)` - Determines email verification status

### 3. Auth Middleware Integration

The auth middleware (`server/src/middleware/auth.js`) automatically calls the user sync utility:

1. Verifies Supabase JWT token
2. Calls `syncUser()` or `syncMockUser()` based on token type
3. Attaches the synced user object to `req.user`
4. Provides detailed logging of user authentication

## Supported Providers

### Email/Password Users
- **Provider**: `"email"`
- **Name**: From `user_metadata.name` or email prefix
- **Avatar**: `null`
- **Email Verified**: Based on `email_confirmed_at`

### Google OAuth Users
- **Provider**: `"google"`
- **Name**: From `user_metadata.full_name` or `user_metadata.name`
- **Avatar**: From `user_metadata.avatar_url` or `user_metadata.picture`
- **Email Verified**: `true` (pre-verified by Google)

### Apple OAuth Users
- **Provider**: `"apple"`
- **Name**: From `user_metadata.full_name` or `user_metadata.name`
- **Avatar**: From `user_metadata.avatar_url` or `user_metadata.picture`
- **Email Verified**: `true` (pre-verified by Apple)

### Phone Authentication Users
- **Provider**: `"phone"`
- **Name**: Generated from phone number
- **Avatar**: `null`
- **Email Verified**: `false`

## Usage

The user sync system works automatically when users authenticate. No manual intervention is required.

### Testing

You can test the user sync system using the test endpoint:

```bash
# Test with mock OAuth user
curl -H "Authorization: Bearer mock-token-google-oauth" http://localhost:3001/api/test/user

# Test with mock email user
curl -H "Authorization: Bearer mock-token-email-user" http://localhost:3001/api/test/user
```

### Example Response

```json
{
  "message": "User data retrieved successfully",
  "user": {
    "id": "cmfkgixra000054wtrd3y1rsa",
    "supabaseId": "mock-user-1757900426077",
    "email": "test-1757900426077@example.com",
    "phone": "+12345676077",
    "name": "John Doe",
    "avatar": "https://lh3.googleusercontent.com/a/default-user",
    "provider": "google",
    "emailVerified": true,
    "lastLogin": "2025-09-15T01:40:26.077Z",
    "createdAt": "2025-09-15T01:40:26.087Z"
  }
}
```

## Error Handling

The system handles various error scenarios:

- **Unique constraint violations**: Returns 409 with specific field information
- **Database errors**: Returns 500 with error details
- **Invalid user data**: Throws descriptive errors
- **Missing fields**: Uses sensible fallbacks

## Migration

The system includes a database migration that adds the new user fields:

```sql
-- Migration: 20250915013906_add_user_sync_fields
ALTER TABLE "users" ADD COLUMN "avatar" TEXT;
ALTER TABLE "users" ADD COLUMN "provider" TEXT;
ALTER TABLE "users" ADD COLUMN "emailVerified" BOOLEAN NOT NULL DEFAULT false;
```

## Benefits

1. **Automatic Sync**: Users are automatically synced on every authentication
2. **Provider Support**: Handles multiple authentication providers
3. **Data Consistency**: Ensures user data is always up-to-date
4. **OAuth Integration**: Properly extracts OAuth-specific data (avatars, names)
5. **Development Friendly**: Includes mock user support for testing
6. **Error Resilient**: Handles edge cases and errors gracefully
