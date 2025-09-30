#!/usr/bin/env node

const http = require('http');

// Test the verification system
async function testVerification() {
  console.log('🧪 Testing Austin Food Club Verification System\n');
  
  const baseUrl = 'http://localhost:3001';
  const testPhone = '+1234567890';
  
  // Test 1: Send verification code
  console.log('1️⃣ Testing send verification code...');
  try {
    const sendResponse = await makeRequest('POST', '/api/verification/send-code', {
      phone: testPhone
    });
    
    if (sendResponse.success) {
      console.log('✅ Verification code sent successfully');
      console.log(`   Phone: ${sendResponse.data.phone}`);
      console.log(`   Expires in: ${sendResponse.data.expiresIn} seconds`);
      
      // Test 2: Verify code (using a mock code for testing)
      console.log('\n2️⃣ Testing code verification...');
      const verifyResponse = await makeRequest('POST', '/api/verification/verify-code', {
        phone: testPhone,
        code: '123456', // Mock code - in real system, user would enter this
        name: 'Test User'
      });
      
      if (verifyResponse.success) {
        console.log('✅ Code verification successful');
        console.log(`   User: ${verifyResponse.data.user.name}`);
        console.log(`   Phone: ${verifyResponse.data.user.phone}`);
        console.log(`   Is New User: ${verifyResponse.data.isNewUser}`);
      } else {
        console.log('❌ Code verification failed:', verifyResponse.message);
      }
      
    } else {
      console.log('❌ Failed to send verification code:', sendResponse.message);
    }
    
  } catch (error) {
    console.log('❌ Test failed:', error.message);
  }
  
  // Test 3: Check verification status
  console.log('\n3️⃣ Testing verification status...');
  try {
    const statusResponse = await makeRequest('GET', `/api/verification/status/${encodeURIComponent(testPhone)}`);
    
    if (statusResponse.success) {
      console.log('✅ Status check successful');
      console.log(`   Has Code: ${statusResponse.data.hasCode}`);
      console.log(`   Is Expired: ${statusResponse.data.isExpired}`);
    } else {
      console.log('❌ Status check failed:', statusResponse.message);
    }
  } catch (error) {
    console.log('❌ Status check failed:', error.message);
  }
}

function makeRequest(method, path, data = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 3001,
      path: path,
      method: method,
      headers: {
        'Content-Type': 'application/json',
      }
    };

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => {
        body += chunk;
      });
      
      res.on('end', () => {
        try {
          const parsed = JSON.parse(body);
          resolve(parsed);
        } catch (e) {
          reject(new Error(`Invalid JSON response: ${body}`));
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    if (data) {
      req.write(JSON.stringify(data));
    }
    
    req.end();
  });
}

// Run the test
testVerification().catch(console.error);

