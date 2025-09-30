const { PrismaClient } = require('@prisma/client');
const { verifySupabaseToken } = require('./auth');

const prisma = new PrismaClient();

/**
 * Middleware to verify admin access
 * Requires valid authentication + admin privileges
 */
const requireAdmin = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ 
        success: false,
        message: 'Authentication required',
        error: 'AUTH_REQUIRED',
        timestamp: new Date().toISOString()
      });
    }

    const token = authHeader.substring(7);

    // Handle demo token (for development)
    if (token.startsWith('demo-admin-token-')) {
      req.admin = {
        id: 'demo-admin',
        name: 'Austin Food Club Admin',
        email: 'admin@austinfoodclub.com',
        isAdmin: true
      };
      next();
      return;
    }

    // For production, verify with Supabase
    const authResult = await verifySupabaseToken(req, res, () => {});
    
    if (!req.user) {
      return res.status(401).json({ 
        success: false,
        message: 'Authentication required',
        error: 'AUTH_REQUIRED',
        timestamp: new Date().toISOString()
      });
    }

    // Check if user has admin privileges
    const user = await prisma.user.findUnique({
      where: { supabaseId: req.user.id },
      select: { id: true, isAdmin: true, name: true, email: true }
    });

    if (!user) {
      return res.status(404).json({ 
        success: false,
        message: 'User not found',
        error: 'USER_NOT_FOUND',
        timestamp: new Date().toISOString()
      });
    }

    if (!user.isAdmin) {
      // Log unauthorized admin access attempt
      await logAdminAction(user.id, 'unauthorized_access_attempt', null, 'admin_panel', {
        endpoint: req.path,
        method: req.method,
        userAgent: req.get('User-Agent'),
        ip: req.ip
      });

      return res.status(403).json({ 
        success: false,
        message: 'Admin privileges required',
        error: 'ADMIN_REQUIRED',
        timestamp: new Date().toISOString()
      });
    }

    // Add admin user info to request
    req.admin = user;
    next();
  } catch (error) {
    console.error('Admin auth error:', error);
    res.status(500).json({ 
      success: false,
      message: 'Authentication error',
      error: 'AUTH_ERROR',
      timestamp: new Date().toISOString()
    });
  }
};

/**
 * Optional admin middleware - adds admin info if user is admin, but doesn't block
 */
const optionalAdmin = async (req, res, next) => {
  try {
    if (req.user) {
      const user = await prisma.user.findUnique({
        where: { supabaseId: req.user.id },
        select: { id: true, isAdmin: true, name: true, email: true }
      });

      if (user && user.isAdmin) {
        req.admin = user;
      }
    }
    next();
  } catch (error) {
    console.error('Optional admin auth error:', error);
    next(); // Continue even if admin check fails
  }
};

/**
 * Log admin actions for audit trail
 */
const logAdminAction = async (adminId, action, targetId = null, targetType = null, details = null, req = null) => {
  try {
    // Skip logging for demo admin to avoid foreign key issues
    if (adminId === 'demo-admin') {
      console.log(`📝 Admin action (demo): ${action} - ${targetType || 'system'}`);
      return;
    }

    await prisma.adminLog.create({
      data: {
        adminId,
        action,
        targetId,
        targetType,
        details: details ? JSON.stringify(details) : null,
        ipAddress: req?.ip || null,
        userAgent: req?.get('User-Agent') || null
      }
    });
  } catch (error) {
    console.error('Error logging admin action:', error);
    // Don't throw - logging failures shouldn't break admin operations
  }
};

/**
 * Middleware to log admin actions automatically
 */
const logAdminActionMiddleware = (action, targetType = null) => {
  return async (req, res, next) => {
    // Store original json method
    const originalJson = res.json;
    
    // Override json method to log successful actions
    res.json = function(data) {
      // Only log if the action was successful (no error in response)
      if (!data.error && req.admin) {
        const targetId = req.params.id || req.body.id || req.body.restaurantId || null;
        const details = {
          method: req.method,
          endpoint: req.path,
          body: req.method !== 'GET' ? req.body : undefined,
          params: req.params,
          query: req.query
        };
        
        // Log asynchronously (don't wait)
        logAdminAction(req.admin.id, action, targetId, targetType, details, req);
      }
      
      // Call original json method
      return originalJson.call(this, data);
    };
    
    next();
  };
};

/**
 * Check if user is admin (utility function)
 */
const isUserAdmin = async (supabaseId) => {
  try {
    const user = await prisma.user.findUnique({
      where: { supabaseId },
      select: { isAdmin: true }
    });
    return user?.isAdmin || false;
  } catch (error) {
    console.error('Error checking admin status:', error);
    return false;
  }
};

/**
 * Make user an admin (utility function)
 */
const makeUserAdmin = async (userId, adminId) => {
  try {
    const user = await prisma.user.update({
      where: { id: userId },
      data: { isAdmin: true }
    });

    // Log the action
    await logAdminAction(adminId, 'make_user_admin', userId, 'user', {
      targetUserName: user.name,
      targetUserEmail: user.email
    });

    return user;
  } catch (error) {
    console.error('Error making user admin:', error);
    throw error;
  }
};

module.exports = {
  requireAdmin,
  optionalAdmin,
  logAdminAction,
  logAdminActionMiddleware,
  isUserAdmin,
  makeUserAdmin
};
