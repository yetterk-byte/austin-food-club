const { createClient } = require('@supabase/supabase-js');
const { PrismaClient } = require('@prisma/client');
const { syncUser, syncMockUser } = require('../utils/userSync');

// Initialize Supabase client
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY; // Use service role key for server-side verification

let supabase;
if (supabaseUrl && supabaseServiceKey) {
  supabase = createClient(supabaseUrl, supabaseServiceKey);
} else {
  console.warn('Supabase environment variables not configured. Auth middleware will use mock verification.');
  // Mock Supabase client for development
  supabase = {
    auth: {
      getUser: async (token) => {
        // Mock user for development - replace with actual Supabase verification
        return {
          data: {
            user: {
              id: 'mock-user-id',
              email: 'test@example.com',
              phone: '+1234567890',
              user_metadata: {
                name: 'Test User'
              }
            }
          },
          error: null
        };
      }
    }
  };
}

const prisma = new PrismaClient();

/**
 * Middleware to verify Supabase JWT token and create/update user in database
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {Function} next - Express next function
 */
const verifySupabaseToken = async (req, res, next) => {
  try {
    // Extract token from Authorization header
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ 
        success: false,
        message: 'Authorization header missing or invalid. Expected: Bearer <token>',
        error: 'UNAUTHORIZED',
        timestamp: new Date().toISOString()
      });
    }

    const token = authHeader.substring(7); // Remove 'Bearer ' prefix

    // Verify token with Supabase
    let supabaseUser;
    if (token.startsWith('mock-token')) {
      // Handle mock token for development
      const isOAuth = token.includes('google') || token.includes('apple');
      const isConsistent = token.includes('consistent');
      
      // Use consistent ID for consistent tokens, timestamp for others
      const userId = isConsistent ? 'mock-user-consistent' : 'mock-user-' + Date.now();
      const email = isConsistent ? 'test-consistent@example.com' : `test-${Date.now()}@example.com`;
      const phone = isConsistent ? '+1234567891' : `+1234567${Date.now().toString().slice(-4)}`;
      
      supabaseUser = {
        id: userId,
        email: email,
        phone: phone,
        user_metadata: {
          name: isOAuth ? 'John Doe' : 'Test User',
          full_name: isOAuth ? 'John Doe' : 'Test User',
          avatar_url: isOAuth ? 'https://lh3.googleusercontent.com/a/default-user' : null,
          picture: isOAuth ? 'https://lh3.googleusercontent.com/a/default-user' : null
        },
        app_metadata: isOAuth ? {
          providers: ['google']
        } : {
          providers: ['email']
        },
        email_confirmed_at: isOAuth ? new Date().toISOString() : null
      };
    } else {
      const { data: { user }, error: verifyError } = await supabase.auth.getUser(token);
      
      if (verifyError || !user) {
        console.error('Token verification failed:', verifyError);
        return res.status(401).json({ 
          success: false,
          message: 'Invalid or expired token',
          error: 'UNAUTHORIZED',
          timestamp: new Date().toISOString()
        });
      }
      supabaseUser = user;
    }

    // Sync user with database using userSync utility
    let user;
    try {
      if (token.startsWith('mock-token')) {
        // Use mock user sync for development
        user = await syncMockUser(supabaseUser);
      } else {
        // Use regular user sync for real Supabase users
        user = await syncUser(supabaseUser);
      }
    } catch (dbError) {
      console.error('Database error during user sync:', dbError);
      
      // Handle unique constraint violations
      if (dbError.code === 'P2002') {
        const field = dbError.meta?.target?.[0];
        return res.status(409).json({ 
          error: `User with this ${field} already exists` 
        });
      }
      
      return res.status(500).json({ 
        error: 'Database error during user authentication' 
      });
    }

    // Attach user to request object
    req.user = user;
    
    // Log successful authentication
    console.log(`User authenticated: ${user.name} (${user.id}) - Provider: ${user.provider} - Email: ${user.email || 'N/A'}`);
    
    next();
  } catch (error) {
    console.error('Auth middleware error:', error);
    return res.status(500).json({ 
      error: 'Internal server error during authentication' 
    });
  }
};

/**
 * Optional middleware to require authentication (returns 401 if no user)
 * Use this on routes that require authentication
 */
const requireAuth = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ 
      error: 'Authentication required' 
    });
  }
  next();
};

/**
 * Optional middleware to get user if authenticated (doesn't fail if no user)
 * Use this on routes that are optional for authenticated users
 */
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (authHeader && authHeader.startsWith('Bearer ')) {
      // Try to authenticate but don't fail if it doesn't work
      await verifySupabaseToken(req, res, () => {
        // Don't call next() here, just continue
      });
    }
    
    next();
  } catch (error) {
    // Continue without authentication if there's an error
    next();
  }
};

module.exports = {
  verifySupabaseToken,
  requireAuth,
  optionalAuth
};
