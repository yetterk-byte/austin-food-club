const express = require('express');

const router = express.Router();

/**
 * POST /api/auth/admin-login
 * Admin login endpoint
 */
router.post('/admin-login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // For demo purposes, accept any email/password combination
    // In production, this would verify against a proper admin database
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    // Generate demo admin token
    const adminToken = `demo-admin-token-${Date.now()}`;

    res.json({
      success: true,
      token: adminToken,
      admin: {
        id: 'demo-admin',
        name: 'Austin Food Club Admin',
        email: email,
        isAdmin: true
      },
      message: 'Login successful'
    });

  } catch (error) {
    console.error('❌ Admin login error:', error);
    res.status(500).json({ error: 'Login failed: ' + error.message });
  }
});

module.exports = router;
