#!/usr/bin/env node

/**
 * API Test Runner
 * Run comprehensive tests for the Austin Food Club API
 */

const APITestSuite = require('./src/utils/apiTestSuite');

async function main() {
  const args = process.argv.slice(2);
  const baseUrl = args.find(arg => arg.startsWith('--url='))?.split('=')[1] || 'http://localhost:3001';
  const category = args.find(arg => !arg.startsWith('--'));

  const testSuite = new APITestSuite(baseUrl);

  console.log(`🚀 Austin Food Club API Test Suite`);
  console.log(`📍 Base URL: ${baseUrl}\n`);

  if (category) {
    await testSuite.runCategory(category);
  } else {
    await testSuite.runAllTests();
  }
}

// Handle errors gracefully
process.on('unhandledRejection', (error) => {
  console.error('❌ Unhandled error:', error.message);
  process.exit(1);
});

process.on('uncaughtException', (error) => {
  console.error('❌ Uncaught exception:', error.message);
  process.exit(1);
});

main().catch(console.error);

