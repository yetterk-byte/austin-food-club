#!/usr/bin/env node

/**
 * API Consistency Testing Script
 * 
 * This script tests all API endpoints to ensure they follow the standardized response format:
 * - success: boolean
 * - message: string
 * - timestamp: string (ISO 8601)
 * - data: object | array | null
 * - meta: object | null (for pagination)
 * - error: string | null (for errors)
 */

const https = require('https');
const http = require('http');

// Configuration
const BASE_URL = 'http://localhost:3001';
const TIMEOUT = 10000; // 10 seconds

// Test endpoints configuration
const endpoints = [
  {
    name: 'Test Endpoint',
    method: 'GET',
    url: '/api/test',
    expectedStatus: 200
  },
  {
    name: 'Admin Login (Valid)',
    method: 'POST',
    url: '/api/auth/admin-login',
    body: { email: 'admin@austinfoodclub.com', password: 'admin123' },
    expectedStatus: 200
  },
  {
    name: 'Admin Login (Invalid Email)',
    method: 'POST',
    url: '/api/auth/admin-login',
    body: { email: 'invalid', password: 'admin123' },
    expectedStatus: 400,
    expectError: true
  },
  {
    name: 'Admin Login (Missing Password)',
    method: 'POST',
    url: '/api/auth/admin-login',
    body: { email: 'admin@austinfoodclub.com' },
    expectedStatus: 400,
    expectError: true
  },
  {
    name: 'Current Restaurant (Austin)',
    method: 'GET',
    url: '/api/restaurants/current?citySlug=austin',
    expectedStatus: 200
  },
  {
    name: 'Current Restaurant (Invalid City)',
    method: 'GET',
    url: '/api/restaurants/current?citySlug=invalid',
    expectedStatus: 404,
    expectError: true
  },
  {
    name: 'Restaurant Search',
    method: 'GET',
    url: '/api/restaurants/search?term=Franklin&location=Austin,TX&limit=20',
    expectedStatus: 200
  },
  {
    name: 'Friends List',
    method: 'GET',
    url: '/api/friends/user/1',
    expectedStatus: 200
  },
  {
    name: 'Social Feed',
    method: 'GET',
    url: '/api/social-feed/user/1',
    expectedStatus: 200
  },
  {
    name: 'Verified Visits',
    method: 'GET',
    url: '/api/verified-visits/user/1',
    expectedStatus: 200
  },
  {
    name: 'City Activity',
    method: 'GET',
    url: '/api/city-activity/user/1',
    expectedStatus: 200
  },
  {
    name: 'RSVP Counts',
    method: 'GET',
    url: '/api/rsvp/counts?restaurantId=franklin-bbq',
    expectedStatus: 200
  },
  {
    name: 'Non-existent Endpoint',
    method: 'GET',
    url: '/api/non-existent',
    expectedStatus: 404,
    expectError: true
  }
];

// Utility function to make HTTP requests
function makeRequest(options) {
  return new Promise((resolve, reject) => {
    const url = new URL(BASE_URL + options.url);
    const isHttps = url.protocol === 'https:';
    const client = isHttps ? https : http;
    
    const requestOptions = {
      hostname: url.hostname,
      port: url.port || (isHttps ? 443 : 80),
      path: url.pathname + url.search,
      method: options.method,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...options.headers
      },
      timeout: TIMEOUT
    };

    const req = client.request(requestOptions, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        try {
          const jsonData = data ? JSON.parse(data) : {};
          resolve({
            status: res.statusCode,
            headers: res.headers,
            data: jsonData
          });
        } catch (error) {
          resolve({
            status: res.statusCode,
            headers: res.headers,
            data: data,
            parseError: error.message
          });
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.on('timeout', () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });

    if (options.body) {
      req.write(JSON.stringify(options.body));
    }

    req.end();
  });
}

// Validate response format
function validateResponseFormat(response, expectError = false) {
  const { status, data } = response;
  const errors = [];
  const warnings = [];

  // Check if response is JSON
  if (typeof data !== 'object' || data === null) {
    errors.push('Response is not valid JSON');
    return { isValid: false, errors, warnings };
  }

  // Required fields for standardized format
  const requiredFields = ['success', 'message', 'timestamp'];
  const optionalFields = ['data', 'meta', 'error'];

  // Check required fields
  for (const field of requiredFields) {
    if (!(field in data)) {
      errors.push(`Missing required field: ${field}`);
    }
  }

  // Check field types
  if ('success' in data && typeof data.success !== 'boolean') {
    errors.push('Field "success" must be a boolean');
  }

  if ('message' in data && typeof data.message !== 'string') {
    errors.push('Field "message" must be a string');
  }

  if ('timestamp' in data && typeof data.timestamp !== 'string') {
    errors.push('Field "timestamp" must be a string');
  }

  // Validate timestamp format (ISO 8601)
  if ('timestamp' in data && data.timestamp) {
    try {
      const date = new Date(data.timestamp);
      if (isNaN(date.getTime())) {
        errors.push('Field "timestamp" is not a valid ISO 8601 date');
      }
    } catch (error) {
      errors.push('Field "timestamp" is not a valid ISO 8601 date');
    }
  }

  // Check success/error consistency
  if ('success' in data) {
    if (expectError && data.success === true) {
      warnings.push('Expected error response but got success=true');
    } else if (!expectError && data.success === false) {
      warnings.push('Expected success response but got success=false');
    }
  }

  // Check error field presence
  if (expectError && data.success === false && !('error' in data)) {
    warnings.push('Error response should include "error" field');
  }

  // Check data field
  if ('data' in data && data.data !== null && typeof data.data !== 'object' && !Array.isArray(data.data)) {
    errors.push('Field "data" must be an object, array, or null');
  }

  // Check meta field (for pagination)
  if ('meta' in data && data.meta !== null && typeof data.meta !== 'object') {
    errors.push('Field "meta" must be an object or null');
  }

  return {
    isValid: errors.length === 0,
    errors,
    warnings
  };
}

// Test individual endpoint
async function testEndpoint(endpoint) {
  const startTime = Date.now();
  
  try {
    console.log(`🧪 Testing: ${endpoint.name}`);
    console.log(`   ${endpoint.method} ${endpoint.url}`);
    
    const response = await makeRequest({
      method: endpoint.method,
      url: endpoint.url,
      body: endpoint.body,
      headers: endpoint.headers || {}
    });

    const duration = Date.now() - startTime;
    const validation = validateResponseFormat(response, endpoint.expectError);

    // Check status code
    const statusMatch = response.status === endpoint.expectedStatus;
    const statusIcon = statusMatch ? '✅' : '❌';

    console.log(`   ${statusIcon} Status: ${response.status} (expected: ${endpoint.expectedStatus})`);
    console.log(`   ⏱️  Duration: ${duration}ms`);

    // Check response format
    if (validation.isValid) {
      console.log(`   ✅ Response format: Valid`);
    } else {
      console.log(`   ❌ Response format: Invalid`);
      validation.errors.forEach(error => {
        console.log(`      - ${error}`);
      });
    }

    // Show warnings
    if (validation.warnings.length > 0) {
      validation.warnings.forEach(warning => {
        console.log(`      ⚠️  ${warning}`);
      });
    }

    // Show response summary
    if (response.data && typeof response.data === 'object') {
      console.log(`   📊 Response summary:`);
      console.log(`      - Success: ${response.data.success}`);
      console.log(`      - Message: "${response.data.message}"`);
      console.log(`      - Timestamp: ${response.data.timestamp}`);
      if (response.data.data) {
        if (Array.isArray(response.data.data)) {
          console.log(`      - Data: Array with ${response.data.data.length} items`);
        } else {
          console.log(`      - Data: Object with ${Object.keys(response.data.data).length} fields`);
        }
      }
      if (response.data.meta) {
        console.log(`      - Meta: ${Object.keys(response.data.meta).join(', ')}`);
      }
      if (response.data.error) {
        console.log(`      - Error: ${response.data.error}`);
      }
    }

    console.log('');

    return {
      endpoint: endpoint.name,
      url: endpoint.url,
      status: response.status,
      expectedStatus: endpoint.expectedStatus,
      statusMatch,
      duration,
      formatValid: validation.isValid,
      errors: validation.errors,
      warnings: validation.warnings,
      responseSize: JSON.stringify(response.data).length
    };

  } catch (error) {
    const duration = Date.now() - startTime;
    console.log(`   ❌ Error: ${error.message}`);
    console.log(`   ⏱️  Duration: ${duration}ms`);
    console.log('');

    return {
      endpoint: endpoint.name,
      url: endpoint.url,
      status: null,
      expectedStatus: endpoint.expectedStatus,
      statusMatch: false,
      duration,
      formatValid: false,
      errors: [error.message],
      warnings: [],
      responseSize: 0
    };
  }
}

// Main test function
async function runTests() {
  console.log('🚀 Austin Food Club API Consistency Test');
  console.log('==========================================');
  console.log(`📡 Base URL: ${BASE_URL}`);
  console.log(`⏱️  Timeout: ${TIMEOUT}ms`);
  console.log(`📋 Testing ${endpoints.length} endpoints\n`);

  const results = [];
  let successCount = 0;
  let formatValidCount = 0;

  for (const endpoint of endpoints) {
    const result = await testEndpoint(endpoint);
    results.push(result);
    
    if (result.statusMatch) successCount++;
    if (result.formatValid) formatValidCount++;
  }

  // Summary
  console.log('📊 Test Summary');
  console.log('===============');
  console.log(`✅ Status Code Matches: ${successCount}/${endpoints.length} (${Math.round(successCount/endpoints.length*100)}%)`);
  console.log(`✅ Valid Response Format: ${formatValidCount}/${endpoints.length} (${Math.round(formatValidCount/endpoints.length*100)}%)`);
  
  const totalErrors = results.reduce((sum, r) => sum + r.errors.length, 0);
  const totalWarnings = results.reduce((sum, r) => sum + r.warnings.length, 0);
  
  console.log(`❌ Total Errors: ${totalErrors}`);
  console.log(`⚠️  Total Warnings: ${totalWarnings}`);
  
  const avgDuration = Math.round(results.reduce((sum, r) => sum + r.duration, 0) / results.length);
  console.log(`⏱️  Average Response Time: ${avgDuration}ms`);

  // Failed tests
  const failedTests = results.filter(r => !r.statusMatch || !r.formatValid);
  if (failedTests.length > 0) {
    console.log('\n❌ Failed Tests:');
    failedTests.forEach(test => {
      console.log(`   - ${test.endpoint}: ${test.statusMatch ? 'Format' : 'Status'} issue`);
    });
  }

  // Performance analysis
  const slowTests = results.filter(r => r.duration > 2000);
  if (slowTests.length > 0) {
    console.log('\n🐌 Slow Tests (>2s):');
    slowTests.forEach(test => {
      console.log(`   - ${test.endpoint}: ${test.duration}ms`);
    });
  }

  console.log('\n🎯 Overall Assessment:');
  if (successCount === endpoints.length && formatValidCount === endpoints.length) {
    console.log('   🎉 All tests passed! API is fully standardized.');
  } else if (formatValidCount >= endpoints.length * 0.8) {
    console.log('   ✅ Most tests passed. Minor issues to address.');
  } else {
    console.log('   ⚠️  Several issues found. Review and fix endpoints.');
  }

  return results;
}

// Run tests if this script is executed directly
if (require.main === module) {
  runTests().catch(error => {
    console.error('❌ Test runner error:', error.message);
    process.exit(1);
  });
}

module.exports = { runTests, testEndpoint, validateResponseFormat };

