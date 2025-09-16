const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

/**
 * User synchronization utility for syncing Supabase users with Prisma
 * Handles both email and OAuth users
 */

/**
 * Extract provider type from Supabase user
 * @param {Object} supabaseUser - Supabase user object
 * @returns {string} Provider type (email, google, apple, etc.)
 */
function getProviderType(supabaseUser) {
  // Check if user has OAuth providers
  if (supabaseUser.app_metadata?.providers) {
    const providers = supabaseUser.app_metadata.providers;
    // Return the first provider (usually the primary one)
    return providers[0] || 'email';
  }
  
  // Check if user has phone authentication
  if (supabaseUser.phone) {
    return 'phone';
  }
  
  // Default to email if no other provider is detected
  return 'email';
}

/**
 * Extract avatar URL from Supabase user
 * @param {Object} supabaseUser - Supabase user object
 * @returns {string|null} Avatar URL or null
 */
function getAvatarUrl(supabaseUser) {
  // Check for avatar in user metadata
  if (supabaseUser.user_metadata?.avatar_url) {
    return supabaseUser.user_metadata.avatar_url;
  }
  
  // Check for picture in user metadata (Google OAuth)
  if (supabaseUser.user_metadata?.picture) {
    return supabaseUser.user_metadata.picture;
  }
  
  // Check for photo URL in user metadata
  if (supabaseUser.user_metadata?.photo_url) {
    return supabaseUser.user_metadata.photo_url;
  }
  
  return null;
}

/**
 * Extract user name from Supabase user
 * @param {Object} supabaseUser - Supabase user object
 * @returns {string} User's display name
 */
function getUserName(supabaseUser) {
  // Check for full name in user metadata
  if (supabaseUser.user_metadata?.full_name) {
    return supabaseUser.user_metadata.full_name;
  }
  
  // Check for name in user metadata
  if (supabaseUser.user_metadata?.name) {
    return supabaseUser.user_metadata.name;
  }
  
  // Check for display name
  if (supabaseUser.user_metadata?.display_name) {
    return supabaseUser.user_metadata.display_name;
  }
  
  // Fallback to email prefix if no name is provided
  if (supabaseUser.email) {
    return supabaseUser.email.split('@')[0];
  }
  
  // Fallback to phone if no email
  if (supabaseUser.phone) {
    return `User ${supabaseUser.phone.slice(-4)}`;
  }
  
  // Last resort fallback
  return 'Unknown User';
}

/**
 * Check if email is verified
 * @param {Object} supabaseUser - Supabase user object
 * @returns {boolean} Whether email is verified
 */
function isEmailVerified(supabaseUser) {
  // Check if email is confirmed
  if (supabaseUser.email_confirmed_at) {
    return true;
  }
  
  // Check if user has confirmed email
  if (supabaseUser.confirmed_at) {
    return true;
  }
  
  // For OAuth users, email is usually pre-verified
  if (supabaseUser.app_metadata?.providers?.includes('google') || 
      supabaseUser.app_metadata?.providers?.includes('apple')) {
    return true;
  }
  
  return false;
}

/**
 * Sync Supabase user with Prisma User record
 * @param {Object} supabaseUser - Supabase user object
 * @returns {Promise<Object>} Prisma User record
 */
async function syncUser(supabaseUser) {
  try {
    if (!supabaseUser || !supabaseUser.id) {
      throw new Error('Invalid Supabase user object');
    }

    const provider = getProviderType(supabaseUser);
    const avatar = getAvatarUrl(supabaseUser);
    const name = getUserName(supabaseUser);
    const emailVerified = isEmailVerified(supabaseUser);

    // Prepare user data
    const userData = {
      supabaseId: supabaseUser.id,
      email: supabaseUser.email || null,
      phone: supabaseUser.phone || null,
      name: name,
      avatar: avatar,
      provider: provider,
      emailVerified: emailVerified,
      lastLogin: new Date()
    };

    // Try to find existing user by Supabase ID first
    let user = await prisma.user.findUnique({
      where: { supabaseId: supabaseUser.id }
    });

    if (user) {
      // Update existing user
      user = await prisma.user.update({
        where: { id: user.id },
        data: {
          email: userData.email,
          phone: userData.phone,
          name: userData.name,
          avatar: userData.avatar,
          provider: userData.provider,
          emailVerified: userData.emailVerified,
          lastLogin: userData.lastLogin
        }
      });
    } else {
      // Check if user exists by email (for migration cases)
      if (supabaseUser.email) {
        const existingUserByEmail = await prisma.user.findUnique({
          where: { email: supabaseUser.email }
        });

        if (existingUserByEmail) {
          // Update existing user with Supabase ID
          user = await prisma.user.update({
            where: { id: existingUserByEmail.id },
            data: {
              supabaseId: supabaseUser.id,
              phone: userData.phone,
              name: userData.name,
              avatar: userData.avatar,
              provider: userData.provider,
              emailVerified: userData.emailVerified,
              lastLogin: userData.lastLogin
            }
          });
        }
      }

      // Check if user exists by phone (for phone auth users)
      if (!user && supabaseUser.phone) {
        const existingUserByPhone = await prisma.user.findUnique({
          where: { phone: supabaseUser.phone }
        });

        if (existingUserByPhone) {
          // Update existing user with Supabase ID
          user = await prisma.user.update({
            where: { id: existingUserByPhone.id },
            data: {
              supabaseId: supabaseUser.id,
              email: userData.email,
              name: userData.name,
              avatar: userData.avatar,
              provider: userData.provider,
              emailVerified: userData.emailVerified,
              lastLogin: userData.lastLogin
            }
          });
        }
      }

      // Create new user if none found
      if (!user) {
        user = await prisma.user.create({
          data: userData
        });
      }
    }

    console.log(`User synced: ${user.name} (${user.id}) - Provider: ${user.provider}`);
    return user;

  } catch (error) {
    console.error('Error syncing user:', error);
    throw error;
  }
}

/**
 * Sync user for mock authentication (development)
 * @param {Object} mockUser - Mock user object
 * @returns {Promise<Object>} Prisma User record
 */
async function syncMockUser(mockUser) {
  try {
    // Use consistent data for consistent mock users, random for others
    const isConsistent = mockUser.id === 'mock-user-consistent';
    const timestamp = Date.now();
    const randomSuffix = Math.random().toString(36).substring(2, 8);
    
    const userData = {
      supabaseId: mockUser.id,
      email: mockUser.email || (isConsistent ? 'test-consistent@example.com' : `mock-${timestamp}-${randomSuffix}@example.com`),
      phone: mockUser.phone || (isConsistent ? '+1234567891' : `+1234567${randomSuffix}`),
      name: mockUser.user_metadata?.name || (isConsistent ? 'Test User' : `Mock User ${randomSuffix}`),
      avatar: mockUser.user_metadata?.avatar_url || null,
      provider: 'mock',
      emailVerified: true, // Mock users are always "verified"
      lastLogin: new Date()
    };

    // Try to find existing user by Supabase ID
    let user = await prisma.user.findUnique({
      where: { supabaseId: mockUser.id }
    });

    if (user) {
      // Update existing user
      user = await prisma.user.update({
        where: { id: user.id },
        data: {
          email: userData.email,
          phone: userData.phone,
          name: userData.name,
          avatar: userData.avatar,
          provider: userData.provider,
          emailVerified: userData.emailVerified,
          lastLogin: userData.lastLogin
        }
      });
    } else {
      // Create new user
      user = await prisma.user.create({
        data: userData
      });
    }

    console.log(`Mock user synced: ${user.name} (${user.id})`);
    return user;

  } catch (error) {
    console.error('Error syncing mock user:', error);
    throw error;
  }
}

module.exports = {
  syncUser,
  syncMockUser,
  getProviderType,
  getAvatarUrl,
  getUserName,
  isEmailVerified
};
