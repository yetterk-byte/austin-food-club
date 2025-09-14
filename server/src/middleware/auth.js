const { createClient } = require('@supabase/supabase-js');
const { PrismaClient } = require('@prisma/client');

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
        error: 'Authorization header missing or invalid. Expected: Bearer <token>' 
      });
    }

    const token = authHeader.substring(7); // Remove 'Bearer ' prefix

    // Verify token with Supabase
    const { data: { user: supabaseUser }, error: verifyError } = await supabase.auth.getUser(token);

    if (verifyError || !supabaseUser) {
      console.error('Token verification failed:', verifyError);
      return res.status(401).json({ 
        error: 'Invalid or expired token' 
      });
    }

    // Extract user information from Supabase user
    const supabaseId = supabaseUser.id;
    const email = supabaseUser.email;
    const phone = supabaseUser.phone;
    const name = supabaseUser.user_metadata?.name || 
                 supabaseUser.user_metadata?.full_name || 
                 email?.split('@')[0] || 
                 'User';

    // Find or create user in database
    let user;
    try {
      // Try to find existing user by supabaseId
      user = await prisma.user.findUnique({
        where: { supabaseId }
      });

      if (user) {
        // Update existing user with latest info and lastLogin
        user = await prisma.user.update({
          where: { supabaseId },
          data: {
            email: email || user.email,
            phone: phone || user.phone,
            name: name || user.name,
            lastLogin: new Date()
          }
        });
      } else {
        // Create new user
        user = await prisma.user.create({
          data: {
            supabaseId,
            email,
            phone,
            name,
            lastLogin: new Date()
          }
        });
      }
    } catch (dbError) {
      console.error('Database error during user lookup/creation:', dbError);
      
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
    console.log(`User authenticated: ${user.name} (${user.supabaseId})`);
    
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
