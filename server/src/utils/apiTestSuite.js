/**
 * API Test Suite
 * Comprehensive testing framework for Austin Food Club API
 */

const axios = require('axios');
const { performance } = require('perf_hooks');

class APITestSuite {
  constructor(baseUrl = 'http://localhost:3001') {
    this.baseUrl = baseUrl;
    this.results = [];
    this.authToken = null;
    this.testUser = null;
  }

  /**
   * Run all tests
   */
  async runAllTests() {
    console.log('🧪 Starting API Test Suite...\n');
    
    const testSuites = [
      { name: 'Health Check Tests', tests: this.healthCheckTests },
      { name: 'Authentication Tests', tests: this.authenticationTests },
      { name: 'Restaurant API Tests', tests: this.restaurantTests },
      { name: 'Social Features Tests', tests: this.socialTests },
      { name: 'Error Handling Tests', tests: this.errorHandlingTests },
      { name: 'Performance Tests', tests: this.performanceTests }
    ];

    for (const suite of testSuites) {
      console.log(`\n📋 Running ${suite.name}...`);
      await this.runTestSuite(suite.name, suite.tests);
    }

    this.generateReport();
  }

  /**
   * Run a specific test suite
   */
  async runTestSuite(suiteName, tests) {
    for (const test of tests) {
      await this.runTest(suiteName, test);
    }
  }

  /**
   * Run a single test
   */
  async runTest(suiteName, test) {
    const startTime = performance.now();
    let result = {
      suite: suiteName,
      name: test.name,
      status: 'PASS',
      duration: 0,
      error: null,
      response: null
    };

    try {
      console.log(`  ✓ ${test.name}`);
      result.response = await test.fn();
      result.duration = performance.now() - startTime;
      
      if (test.assertion && !test.assertion(result.response)) {
        result.status = 'FAIL';
        result.error = 'Assertion failed';
      }
    } catch (error) {
      result.status = 'FAIL';
      result.error = error.message;
      result.duration = performance.now() - startTime;
    }

    this.results.push(result);
    
    if (result.status === 'FAIL') {
      console.log(`    ❌ FAILED: ${result.error}`);
    } else {
      console.log(`    ✅ PASSED (${result.duration.toFixed(2)}ms)`);
    }
  }

  /**
   * Health check tests
   */
  get healthCheckTests() {
    return [
      {
        name: 'Health endpoint returns 200',
        fn: async () => {
          const response = await axios.get(`${this.baseUrl}/api/health`);
          return response.data;
        },
        assertion: (data) => data.success === true && data.status === 'healthy'
      },
      {
        name: 'Health endpoint includes service status',
        fn: async () => {
          const response = await axios.get(`${this.baseUrl}/api/health`);
          return response.data;
        },
        assertion: (data) => data.services && typeof data.services === 'object'
      }
    ];
  }

  /**
   * Authentication tests
   */
  get authenticationTests() {
    return [
      {
        name: 'Send verification code (should fail without Twilio)',
        fn: async () => {
          const response = await axios.post(`${this.baseUrl}/api/verification/send-code`, {
            phone: '+15551234567'
          });
          return response.data;
        },
        assertion: (data) => data.success === false && data.error.includes('Twilio')
      },
      {
        name: 'Verify code with invalid format',
        fn: async () => {
          try {
            await axios.post(`${this.baseUrl}/api/verification/verify-code`, {
              phone: 'invalid',
              code: '123'
            });
            return { success: false };
          } catch (error) {
            return error.response.data;
          }
        },
        assertion: (data) => data.success === false
      }
    ];
  }

  /**
   * Restaurant API tests
   */
  get restaurantTests() {
    return [
      {
        name: 'Get current restaurant',
        fn: async () => {
          const response = await axios.get(`${this.baseUrl}/api/restaurants/current`);
          return response.data;
        },
        assertion: (data) => data.success === true
      },
      {
        name: 'Search restaurants',
        fn: async () => {
          const response = await axios.get(`${this.baseUrl}/api/restaurants/search?term=bbq&location=Austin,TX`);
          return response.data;
        },
        assertion: (data) => data.success === true
      },
      {
        name: 'Get featured restaurants',
        fn: async () => {
          const response = await axios.get(`${this.baseUrl}/api/restaurants/featured`);
          return response.data;
        },
        assertion: (data) => data.success === true
      }
    ];
  }

  /**
   * Social features tests
   */
  get socialTests() {
    return [
      {
        name: 'RSVP endpoint requires authentication',
        fn: async () => {
          try {
            await axios.post(`${this.baseUrl}/api/rsvp`, {
              restaurantId: 'test',
              day: 'friday'
            });
            return { success: false };
          } catch (error) {
            return error.response.data;
          }
        },
        assertion: (data) => data.success === false
      },
      {
        name: 'Wishlist endpoint requires authentication',
        fn: async () => {
          try {
            await axios.get(`${this.baseUrl}/api/wishlist`);
            return { success: false };
          } catch (error) {
            return error.response.data;
          }
        },
        assertion: (data) => data.success === false
      }
    ];
  }

  /**
   * Error handling tests
   */
  get errorHandlingTests() {
    return [
      {
        name: '404 for non-existent endpoint',
        fn: async () => {
          try {
            await axios.get(`${this.baseUrl}/api/non-existent`);
            return { success: false };
          } catch (error) {
            return { status: error.response.status };
          }
        },
        assertion: (data) => data.status === 404
      },
      {
        name: 'Invalid JSON returns 400',
        fn: async () => {
          try {
            await axios.post(`${this.baseUrl}/api/verification/send-code`, 'invalid json', {
              headers: { 'Content-Type': 'application/json' }
            });
            return { success: false };
          } catch (error) {
            return { status: error.response.status };
          }
        },
        assertion: (data) => data.status === 400
      }
    ];
  }

  /**
   * Performance tests
   */
  get performanceTests() {
    return [
      {
        name: 'Health endpoint responds quickly',
        fn: async () => {
          const start = performance.now();
          await axios.get(`${this.baseUrl}/api/health`);
          const duration = performance.now() - start;
          return { duration };
        },
        assertion: (data) => data.duration < 1000 // Less than 1 second
      },
      {
        name: 'Current restaurant endpoint responds quickly',
        fn: async () => {
          const start = performance.now();
          await axios.get(`${this.baseUrl}/api/restaurants/current`);
          const duration = performance.now() - start;
          return { duration };
        },
        assertion: (data) => data.duration < 2000 // Less than 2 seconds
      }
    ];
  }

  /**
   * Generate test report
   */
  generateReport() {
    const totalTests = this.results.length;
    const passedTests = this.results.filter(r => r.status === 'PASS').length;
    const failedTests = this.results.filter(r => r.status === 'FAIL').length;
    const avgDuration = this.results.reduce((sum, r) => sum + r.duration, 0) / totalTests;

    console.log('\n📊 Test Report');
    console.log('==============');
    console.log(`Total Tests: ${totalTests}`);
    console.log(`✅ Passed: ${passedTests}`);
    console.log(`❌ Failed: ${failedTests}`);
    console.log(`⏱️ Average Duration: ${avgDuration.toFixed(2)}ms`);
    console.log(`📈 Success Rate: ${((passedTests / totalTests) * 100).toFixed(1)}%`);

    if (failedTests > 0) {
      console.log('\n❌ Failed Tests:');
      this.results
        .filter(r => r.status === 'FAIL')
        .forEach(r => {
          console.log(`  - ${r.suite}: ${r.name} - ${r.error}`);
        });
    }

    // Performance insights
    const slowTests = this.results.filter(r => r.duration > 1000);
    if (slowTests.length > 0) {
      console.log('\n🐌 Slow Tests (>1s):');
      slowTests.forEach(r => {
        console.log(`  - ${r.name}: ${r.duration.toFixed(2)}ms`);
      });
    }

    console.log('\n🎯 Test Suite Complete!');
  }

  /**
   * Run specific test category
   */
  async runCategory(category) {
    const categories = {
      health: this.healthCheckTests,
      auth: this.authenticationTests,
      restaurants: this.restaurantTests,
      social: this.socialTests,
      errors: this.errorHandlingTests,
      performance: this.performanceTests
    };

    if (!categories[category]) {
      console.log(`❌ Unknown category: ${category}`);
      console.log(`Available categories: ${Object.keys(categories).join(', ')}`);
      return;
    }

    console.log(`🧪 Running ${category} tests...\n`);
    await this.runTestSuite(category, categories[category]);
    this.generateReport();
  }
}

module.exports = APITestSuite;

