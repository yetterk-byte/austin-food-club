#!/usr/bin/env node

/**
 * Database Optimization Runner
 * Run database optimizations for the Austin Food Club API
 */

const DatabaseOptimizer = require('./src/utils/databaseOptimizer');

async function main() {
  const optimizer = new DatabaseOptimizer();

  try {
    await optimizer.optimize();
  } catch (error) {
    console.error('❌ Database optimization failed:', error.message);
    process.exit(1);
  } finally {
    await optimizer.close();
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

