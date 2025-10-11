# Authentication Flow (Dev and Prod)

## Overview
The app supports a phone-based verification flow. In development, the server returns a mock code and a dev-friendly auth token so you can test without Twilio or Supabase. In production, only real tokens are returned.

## Endpoints
- POST `/api/verification/send-code` — Sends a verification code (mock in dev). Returns `data.mockCode` in dev for convenience.
- POST `/api/verification/verify-code` — Verifies the code. Returns:
  - `data.sessionToken` (always)
  - `data.authToken` (dev only; value is `mock-token-consistent`)

## Dev Mode Behavior
- The server’s auth middleware accepts tokens beginning with `mock-token` and will sync a mock user.
- The Flutter app persists the token locally and auto-injects it for protected requests (RSVP, verified visits).

## Client Integration
1. Send code:
```bash
curl -X POST https://api.austinfoodclub.com/api/verification/send-code \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'phone=+15555550123'
```
2. Verify code:
```bash
curl -X POST https://api.austinfoodclub.com/api/verification/verify-code \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'phone=+15555550123' \
  -d 'code=123456' \
  -d 'name=Test User'
```
Response (dev):
```json
{
  "success": true,
  "data": {
    "user": { /* ... */ },
    "sessionToken": "...",
    "authToken": "mock-token-consistent"
  }
}
```

## Authorization Header for Protected Endpoints
Include the `Authorization` header:
```
Authorization: Bearer <authToken or sessionToken>
```

Protected routes include:
- POST `/api/rsvp`
- GET `/api/verified-visits`

In dev, you may use `mock-token-consistent` to simulate an authenticated user.


