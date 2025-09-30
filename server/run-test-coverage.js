#!/usr/bin/env node

/**
 * Comprehensive Test Coverage Runner
 * Runs all tests and generates coverage reports
 */

const { execSync } = require('child_process');
const fs = require('fs').promises;
const path = require('path');

class TestCoverageRunner {
  constructor() {
    this.testResults = [];
    this.coverageData = {};
    this.startTime = Date.now();
  }

  /**
   * Run all tests
   */
  async runAllTests() {
    console.log('🧪 Starting Comprehensive Test Coverage...\n');
    
    const tests = [
      { name: 'API Tests', command: 'node test-api.js', category: 'api' },
      { name: 'Health Check Tests', command: 'node test-api.js health', category: 'health' },
      { name: 'Authentication Tests', command: 'node test-api.js auth', category: 'auth' },
      { name: 'Restaurant Tests', command: 'node test-api.js restaurants', category: 'restaurants' },
      { name: 'Social Tests', command: 'node test-api.js social', category: 'social' },
      { name: 'Error Handling Tests', command: 'node test-api.js errors', category: 'errors' },
      { name: 'Performance Tests', command: 'node test-api.js performance', category: 'performance' }
    ];

    for (const test of tests) {
      await this.runTest(test);
    }

    await this.generateCoverageReport();
  }

  /**
   * Run a single test
   */
  async runTest(test) {
    console.log(`📋 Running ${test.name}...`);
    
    try {
      const startTime = Date.now();
      const output = execSync(test.command, { 
        cwd: process.cwd(),
        encoding: 'utf8',
        timeout: 30000 // 30 second timeout
      });
      
      const duration = Date.now() - startTime;
      
      this.testResults.push({
        name: test.name,
        category: test.category,
        status: 'PASS',
        duration,
        output: output.trim()
      });
      
      console.log(`  ✅ ${test.name} passed (${duration}ms)`);
      
    } catch (error) {
      const duration = Date.now() - Date.now();
      
      this.testResults.push({
        name: test.name,
        category: test.category,
        status: 'FAIL',
        duration,
        error: error.message,
        output: error.stdout || error.stderr || ''
      });
      
      console.log(`  ❌ ${test.name} failed: ${error.message}`);
    }
  }

  /**
   * Generate coverage report
   */
  async generateCoverageReport() {
    const totalDuration = Date.now() - this.startTime;
    const passedTests = this.testResults.filter(r => r.status === 'PASS');
    const failedTests = this.testResults.filter(r => r.status === 'FAIL');
    
    const coverageReport = {
      summary: {
        totalTests: this.testResults.length,
        passedTests: passedTests.length,
        failedTests: failedTests.length,
        successRate: ((passedTests.length / this.testResults.length) * 100).toFixed(1),
        totalDuration: totalDuration
      },
      byCategory: this.getCategoryBreakdown(),
      testResults: this.testResults,
      recommendations: this.generateRecommendations(),
      timestamp: new Date().toISOString()
    };

    // Save coverage report
    await this.saveCoverageReport(coverageReport);
    
    // Display summary
    this.displaySummary(coverageReport);
  }

  /**
   * Get category breakdown
   */
  getCategoryBreakdown() {
    const categories = {};
    
    this.testResults.forEach(result => {
      if (!categories[result.category]) {
        categories[result.category] = {
          total: 0,
          passed: 0,
          failed: 0,
          duration: 0
        };
      }
      
      categories[result.category].total++;
      if (result.status === 'PASS') {
        categories[result.category].passed++;
      } else {
        categories[result.category].failed++;
      }
      categories[result.category].duration += result.duration;
    });

    return categories;
  }

  /**
   * Generate recommendations
   */
  generateRecommendations() {
    const recommendations = [];
    
    const failedTests = this.testResults.filter(r => r.status === 'FAIL');
    if (failedTests.length > 0) {
      recommendations.push({
        type: 'critical',
        message: `${failedTests.length} tests are failing and need immediate attention`,
        tests: failedTests.map(t => t.name)
      });
    }

    const slowTests = this.testResults.filter(r => r.duration > 5000);
    if (slowTests.length > 0) {
      recommendations.push({
        type: 'performance',
        message: `${slowTests.length} tests are running slowly (>5s)`,
        tests: slowTests.map(t => t.name)
      });
    }

    const categories = this.getCategoryBreakdown();
    Object.entries(categories).forEach(([category, stats]) => {
      if (stats.failed > 0) {
        recommendations.push({
          type: 'category',
          message: `${category} category has ${stats.failed} failing tests`,
          category,
          failedCount: stats.failed
        });
      }
    });

    if (recommendations.length === 0) {
      recommendations.push({
        type: 'success',
        message: 'All tests are passing! Consider adding more test cases for better coverage.'
      });
    }

    return recommendations;
  }

  /**
   * Save coverage report
   */
  async saveCoverageReport(report) {
    try {
      const reportsDir = path.join(process.cwd(), 'test-reports');
      await fs.mkdir(reportsDir, { recursive: true });
      
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const filename = `coverage-report-${timestamp}.json`;
      const filepath = path.join(reportsDir, filename);
      
      await fs.writeFile(filepath, JSON.stringify(report, null, 2));
      
      console.log(`\n📊 Coverage report saved: ${filepath}`);
    } catch (error) {
      console.error('❌ Failed to save coverage report:', error.message);
    }
  }

  /**
   * Display summary
   */
  displaySummary(report) {
    console.log('\n📊 Test Coverage Summary');
    console.log('========================');
    console.log(`Total Tests: ${report.summary.totalTests}`);
    console.log(`✅ Passed: ${report.summary.passedTests}`);
    console.log(`❌ Failed: ${report.summary.failedTests}`);
    console.log(`📈 Success Rate: ${report.summary.successRate}%`);
    console.log(`⏱️ Total Duration: ${report.summary.totalDuration}ms`);
    
    console.log('\n📋 Category Breakdown:');
    Object.entries(report.byCategory).forEach(([category, stats]) => {
      const successRate = ((stats.passed / stats.total) * 100).toFixed(1);
      console.log(`  ${category}: ${stats.passed}/${stats.total} (${successRate}%) - ${stats.duration}ms`);
    });

    if (report.recommendations.length > 0) {
      console.log('\n💡 Recommendations:');
      report.recommendations.forEach(rec => {
        const icon = rec.type === 'critical' ? '🚨' : rec.type === 'performance' ? '🐌' : rec.type === 'success' ? '🎉' : '📝';
        console.log(`  ${icon} ${rec.message}`);
      });
    }

    console.log('\n🎯 Test Coverage Complete!');
  }

  /**
   * Run specific test category
   */
  async runCategory(category) {
    console.log(`🧪 Running ${category} tests...\n`);
    
    const test = {
      name: `${category} Tests`,
      command: `node test-api.js ${category}`,
      category: category
    };
    
    await this.runTest(test);
    await this.generateCoverageReport();
  }
}

// Main execution
async function main() {
  const args = process.argv.slice(2);
  const category = args[0];
  
  const runner = new TestCoverageRunner();
  
  if (category) {
    await runner.runCategory(category);
  } else {
    await runner.runAllTests();
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

