# Supabase Setup for Austin Food Club

## Environment Variables Required

Create a `.env` file in the `client` directory with the following variables:

```env
REACT_APP_SUPABASE_URL=your_supabase_project_url_here
REACT_APP_SUPABASE_ANON_KEY=your_supabase_anon_key_here
```

## Getting Your Supabase Credentials

1. Go to [supabase.com](https://supabase.com) and create a new project
2. In your project dashboard, go to Settings > API
3. Copy the "Project URL" and "anon public" key
4. Add them to your `.env` file

## Example .env file:

```env
REACT_APP_SUPABASE_URL=https://your-project-id.supabase.co
REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## Usage

The Supabase client is now available in your React components:

```javascript
import { auth } from '../services/supabase';

// Sign in with phone
const { data, error } = await auth.signInWithPhone('+1234567890');

// Verify OTP
const { data, error } = await auth.verifyOTP('+1234567890', '123456');

// Get current user
const { data: user, error } = await auth.getCurrentUser();

// Sign out
await auth.signOut();
```
