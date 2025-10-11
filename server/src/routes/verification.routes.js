const express = require('express');
const { asyncHandler } = require('../middleware/errorHandler');
const { validate } = require('../middleware/validation');
const twilioService = require('../services/twilioService');
const { prisma } = require('../config/database');

const router = express.Router();

// Store verification codes temporarily (in production, use Redis)
const verificationCodes = new Map();

/**
 * Send verification code to phone number
 * POST /api/verification/send-code
 */
router.post('/send-code', 
  validate({
    phone: { type: 'string', required: true, pattern: /^\+1\d{10}$/ }
  }),
  asyncHandler(async (req, res) => {
    // Respect allowed origins for CORS (support prod + localhost during dev)
    const origin = req.headers.origin;
    const allowedOrigins = [
      'https://austinfoodclub.com',
      'https://www.austinfoodclub.com',
      'https://admin.austinfoodclub.com',
      'http://localhost:8080',
      'http://localhost:8081',
      'http://localhost:8082',
      'http://localhost:3000'
    ];
    if (origin && allowedOrigins.includes(origin)) {
      res.header('Access-Control-Allow-Origin', origin);
      res.header('Access-Control-Allow-Credentials', 'true');
    }
    
    const { phone } = req.body;
    
    // Generate 6-digit verification code
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Store code with expiration (10 minutes)
    verificationCodes.set(phone, {
      code,
      expiresAt: new Date(Date.now() + 10 * 60 * 1000), // 10 minutes
      attempts: 0
    });
    
    // Mock SMS sending for testing (Twilio disabled)
    console.log(`📱 [MOCK SMS] Verification code for ${phone}: ${code}`);
    console.log(`📱 [MOCK SMS] Message: "Your Austin Food Club verification code is: ${code}. This code expires in 10 minutes."`);
    
    // Always succeed in mock mode
    res.json({
      success: true,
      message: 'Verification code sent successfully (mock mode)',
      data: {
        phone: phone,
        expiresIn: 600, // 10 minutes in seconds
        mockCode: code, // Include code in response for testing
        note: 'This is a mock SMS - no actual SMS was sent'
      },
      timestamp: new Date().toISOString()
    });
  })
);

/**
 * Verify code and create/login user
 * POST /api/verification/verify-code
 */
router.post('/verify-code',
  validate({
    phone: { type: 'string', required: true, pattern: /^\+1\d{10}$/ },
    code: { type: 'string', required: true, pattern: /^\d{6}$/ },
    name: { type: 'string', required: false }
  }),
  asyncHandler(async (req, res) => {
    // Respect allowed origins for CORS (support prod + localhost during dev)
    const origin = req.headers.origin;
    const allowedOrigins = [
      'https://austinfoodclub.com',
      'https://www.austinfoodclub.com',
      'https://admin.austinfoodclub.com',
      'http://localhost:8080',
      'http://localhost:8081',
      'http://localhost:8082',
      'http://localhost:3000'
    ];
    if (origin && allowedOrigins.includes(origin)) {
      res.header('Access-Control-Allow-Origin', origin);
      res.header('Access-Control-Allow-Credentials', 'true');
    }
    
    const { phone, code, name } = req.body;
    
    // Get stored verification data
    const verificationData = verificationCodes.get(phone);
    
    if (!verificationData) {
      return res.status(400).json({
        success: false,
        message: 'No verification code found for this phone number',
        error: 'CODE_NOT_FOUND',
        timestamp: new Date().toISOString()
      });
    }
    
    // Check if code has expired
    if (new Date() > verificationData.expiresAt) {
      verificationCodes.delete(phone);
      return res.status(400).json({
        success: false,
        message: 'Verification code has expired',
        error: 'CODE_EXPIRED',
        timestamp: new Date().toISOString()
      });
    }
    
    // Check attempt limit (max 3 attempts)
    if (verificationData.attempts >= 3) {
      verificationCodes.delete(phone);
      return res.status(400).json({
        success: false,
        message: 'Too many verification attempts',
        error: 'TOO_MANY_ATTEMPTS',
        timestamp: new Date().toISOString()
      });
    }
    
    // Verify the code
    if (verificationData.code !== code) {
      verificationData.attempts += 1;
      return res.status(400).json({
        success: false,
        message: 'Invalid verification code',
        error: 'INVALID_CODE',
        attemptsRemaining: 3 - verificationData.attempts,
        timestamp: new Date().toISOString()
      });
    }
    
    // Code is valid! Create or find user
    try {
      let user = await prisma.user.findUnique({
        where: { phone: phone }
      });
      
      if (!user) {
        // Create new user
        const userName = name || `User ${phone.slice(-4)}`;
        user = await prisma.user.create({
          data: {
            supabaseId: `phone_${phone}_${Date.now()}`, // Generate unique ID
            phone: phone,
            name: userName,
            provider: 'phone',
            emailVerified: false,
            lastLogin: new Date()
          }
        });
        
        console.log(`✅ New user created: ${user.name} (${user.id})`);
      } else {
        // Update existing user's last login
        user = await prisma.user.update({
          where: { id: user.id },
          data: {
            lastLogin: new Date(),
            name: name || user.name // Update name if provided
          }
        });
        
        console.log(`✅ Existing user logged in: ${user.name} (${user.id})`);
      }
      
      // Clean up verification code
      verificationCodes.delete(phone);
      
      // Generate a simple session token (in production, use JWT)
      const sessionToken = Buffer.from(`${user.id}:${Date.now()}`).toString('base64');
      
      const isDev = process.env.NODE_ENV !== 'production';

      res.json({
        success: true,
        message: 'Verification successful',
        data: {
          user: {
            id: user.id,
            name: user.name,
            phone: user.phone,
            email: user.email,
            avatar: user.avatar,
            provider: user.provider,
            emailVerified: user.emailVerified,
            createdAt: user.createdAt
          },
          sessionToken: sessionToken,
          authToken: isDev ? 'mock-token-consistent' : sessionToken,
          isNewUser: !user.lastLogin || (new Date() - user.lastLogin) < 60000 // New if created within last minute
        },
        timestamp: new Date().toISOString()
      });
      
    } catch (error) {
      console.error('❌ Error creating/finding user:', error);
      
      res.status(500).json({
        success: false,
        message: 'Failed to create user account',
        error: error.message,
        timestamp: new Date().toISOString()
      });
    }
  })
);

/**
 * Check verification code status (for debugging)
 * GET /api/verification/status/:phone
 */
router.get('/status/:phone', asyncHandler(async (req, res) => {
  const { phone } = req.params;
  const verificationData = verificationCodes.get(phone);
  
  if (!verificationData) {
    return res.json({
      success: true,
      data: {
        phone,
        hasCode: false,
        message: 'No verification code found'
      }
    });
  }
  
  const isExpired = new Date() > verificationData.expiresAt;
  
  res.json({
    success: true,
    data: {
      phone,
      hasCode: true,
      isExpired,
      attempts: verificationData.attempts,
      expiresAt: verificationData.expiresAt,
      mockCode: verificationData.code // Include code for testing
    }
  });
}));

/**
 * Quick login for testing (bypasses SMS verification)
 * POST /api/verification/quick-login
 */
router.post('/quick-login',
  validate({
    phone: { type: 'string', required: true, pattern: /^\+1\d{10}$/ },
    name: { type: 'string', required: false }
  }),
  asyncHandler(async (req, res) => {
    const { phone, name } = req.body;
    
    try {
      let user = await prisma.user.findUnique({
        where: { phone: phone }
      });
      
      if (!user) {
        // Create new user
        const userName = name || `Test User ${phone.slice(-4)}`;
        user = await prisma.user.create({
          data: {
            supabaseId: `test_${phone}_${Date.now()}`,
            phone: phone,
            name: userName,
            provider: 'test',
            emailVerified: true, // Mark as verified for testing
            lastLogin: new Date()
          }
        });
        
        console.log(`✅ [TEST MODE] New user created: ${user.name} (${user.id})`);
      } else {
        // Update existing user's last login
        user = await prisma.user.update({
          where: { id: user.id },
          data: {
            lastLogin: new Date(),
            name: name || user.name
          }
        });
        
        console.log(`✅ [TEST MODE] Existing user logged in: ${user.name} (${user.id})`);
      }
      
      // Generate a simple session token
      const sessionToken = Buffer.from(`${user.id}:${Date.now()}`).toString('base64');
      
      res.json({
        success: true,
        message: 'Quick login successful (test mode)',
        data: {
          user: {
            id: user.id,
            name: user.name,
            phone: user.phone,
            email: user.email,
            avatar: user.avatar,
            provider: user.provider,
            emailVerified: user.emailVerified,
            createdAt: user.createdAt
          },
          sessionToken: sessionToken,
          isNewUser: !user.lastLogin || (new Date() - user.lastLogin) < 60000,
          testMode: true
        },
        timestamp: new Date().toISOString()
      });
      
    } catch (error) {
      console.error('❌ Error in quick login:', error);
      
      res.status(500).json({
        success: false,
        message: 'Failed to login',
        error: error.message,
        timestamp: new Date().toISOString()
      });
    }
  })
);

module.exports = router;
