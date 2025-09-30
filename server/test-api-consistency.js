/**
 * API Consistency Test Script
 * Tests all endpoints for standardized response format
 */

const axios = require('axios');

const BASE_URL = 'http://localhost:3001/api';
const TEST_TOKEN = 'demo-admin-token-' + Date.now();

// Test cases
const testCases = [
  // Public endpoints
  {
    name: 'Test endpoint',
    method: 'GET',
    url: '/test',
    expectedStatus: 200,
    expectedFormat: 'success'
  },
  {
    name: 'Current restaurant (Austin)',
    method: 'GET',
    url: '/restaurants/current?citySlug=austin',
    expectedStatus: 200,
    expectedFormat: 'success'
  },
  {
    name: 'Current restaurant (Invalid city)',
    method: 'GET',
    url: '/restaurants/current?citySlug=invalid',
    expectedStatus: 404,
    expectedFormat: 'error'
  },
  {
    name: 'Restaurant search',
    method: 'GET',
    url: '/restaurants/search?term=bbq&location=Austin,TX',
    expectedStatus: 200,
    expectedFormat: 'success'
  },
  
  // Protected endpoints (should return 401)
  {
    name: 'RSVP without auth',
    method: 'POST',
    url: '/rsvp',
    data: { day: 'monday', status: 'going' },
    expectedStatus: 401,
    expectedFormat: 'error'
  },
  {
    name: 'RSVP with invalid data',
    method: 'POST',
    url: '/rsvp',
    headers: { 'Authorization': 'Bearer invalid-token' },
    data: { day: 'invalid', status: 'going' },
    expectedStatus: 401,
    expectedFormat: 'error'
  },
  
  // Admin endpoints
  {
    name: 'Admin dashboard without auth',
    method: 'GET',
    url: '/admin/dashboard?cityId=austin',
    expectedStatus: 401,
    expectedFormat: 'error'
  },
  {
    name: 'Admin login',
    method: 'POST',
    url: '/auth/admin-login',
    data: { email: 'admin@austinfoodclub.com', password: 'admin123' },
    expectedStatus: 200,
    expectedFormat: 'success'
  }
];

// Response format validators
const validators = {
  success: (response) => {
    const data = response.data;
    return data.hasOwnProperty('success') && 
           data.hasOwnProperty('message') && 
           data.hasOwnProperty('timestamp') &&
           data.success === true;
  },
  
  error: (response) => {
    const data = response.data;
    return data.hasOwnProperty('success') && 
           data.hasOwnProperty('message') && 
           data.hasOwnProperty('timestamp') &&
           data.hasOwnProperty('error') &&
           data.success === false;
  }
};

// Run a single test
async function runTest(testCase) {
  try {
    console.log(`\n🧪 Testing: ${testCase.name}`);
    console.log(`   ${testCase.method} ${testCase.url}`);
    
    const config = {
      method: testCase.method,
      url: `${BASE_URL}${testCase.url}`,
      headers: {
        'Content-Type': 'application/json',
        ...testCase.headers
      },
      data: testCase.data,
      validateStatus: () => true // Don't throw on non-2xx status codes
    };
    
    const response = await axios(config);
    
    // Check status code
    const statusMatch = response.status === testCase.expectedStatus;
    console.log(`   Status: ${response.status} ${statusMatch ? '✅' : '❌'} (expected ${testCase.expectedStatus})`);
    
    // Check response format
    const formatValid = validators[testCase.expectedFormat](response);
    console.log(`   Format: ${formatValid ? '✅' : '❌'} (expected ${testCase.expectedFormat})`);
    
    // Show response structure
    console.log(`   Response keys: ${Object.keys(response.data).join(', ')}`);
    
    return {
      name: testCase.name,
      statusMatch,
      formatValid,
      status: response.status,
      response: response.data
    };
    
  } catch (error) {
    console.log(`   Error: ${error.message} ❌`);
    return {
      name: testCase.name,
      statusMatch: false,
      formatValid: false,
      error: error.message
    };
  }
}

// Run all tests
async function runAllTests() {
  console.log('🚀 Starting API Consistency Tests');
  console.log('=====================================');
  
  const results = [];
  
  for (const testCase of testCases) {
    const result = await runTest(testCase);
    results.push(result);
  }
  
  // Summary
  console.log('\n📊 Test Summary');
  console.log('================');
  
  const passed = results.filter(r => r.statusMatch && r.formatValid).length;
  const total = results.length;
  
  console.log(`Total tests: ${total}`);
  console.log(`Passed: ${passed} ✅`);
  console.log(`Failed: ${total - passed} ❌`);
  console.log(`Success rate: ${((passed / total) * 100).toFixed(1)}%`);
  
  // Failed tests
  const failed = results.filter(r => !r.statusMatch || !r.formatValid);
  if (failed.length > 0) {
    console.log('\n❌ Failed Tests:');
    failed.forEach(test => {
      console.log(`   - ${test.name}: Status=${test.statusMatch ? '✅' : '❌'}, Format=${test.formatValid ? '✅' : '❌'}`);
    });
  }
  
  // Response format examples
  console.log('\n📋 Response Format Examples:');
  console.log('============================');
  
  const successExample = results.find(r => r.formatValid && r.response.success);
  if (successExample) {
    console.log('Success Response:');
    console.log(JSON.stringify(successExample.response, null, 2));
  }
  
  const errorExample = results.find(r => r.formatValid && !r.response.success);
  if (errorExample) {
    console.log('\nError Response:');
    console.log(JSON.stringify(errorExample.response, null, 2));
  }
}

// Run the tests
if (require.main === module) {
  runAllTests().catch(console.error);
}

module.exports = { runAllTests, runTest };

