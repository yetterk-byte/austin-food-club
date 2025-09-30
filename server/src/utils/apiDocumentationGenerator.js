/**
 * API Documentation Generator
 * Automatically generates comprehensive API documentation from route definitions
 */

const fs = require('fs').promises;
const path = require('path');

class APIDocumentationGenerator {
  constructor() {
    this.routes = [];
    this.baseUrl = process.env.API_BASE_URL || 'http://localhost:3001';
  }

  /**
   * Add a route to the documentation
   */
  addRoute(route) {
    this.routes.push(route);
  }

  /**
   * Generate comprehensive API documentation
   */
  async generateDocumentation() {
    const doc = {
      info: {
        title: 'Austin Food Club API',
        version: '1.0.0',
        description: 'RESTful API for Austin Food Club restaurant discovery and social features',
        baseUrl: this.baseUrl,
        generatedAt: new Date().toISOString()
      },
      authentication: {
        types: ['Bearer Token', 'Phone Verification'],
        bearerToken: {
          description: 'Supabase JWT token for authenticated endpoints',
          header: 'Authorization: Bearer <token>'
        },
        phoneVerification: {
          description: 'Phone number verification for user registration/login',
          endpoints: ['/api/verification/send-code', '/api/verification/verify-code']
        }
      },
      endpoints: this.categorizeRoutes(),
      examples: this.generateExamples(),
      errorCodes: this.getErrorCodes(),
      rateLimiting: {
        description: 'API rate limiting is implemented to prevent abuse',
        limits: {
          'verification/send-code': '5 requests per minute per IP',
          'verification/verify-code': '10 requests per minute per IP',
          'restaurants/search': '100 requests per hour per IP',
          'default': '1000 requests per hour per IP'
        }
      }
    };

    return doc;
  }

  /**
   * Categorize routes by functionality
   */
  categorizeRoutes() {
    const categories = {
      authentication: [],
      restaurants: [],
      social: [],
      admin: [],
      system: []
    };

    this.routes.forEach(route => {
      if (route.path.includes('/verification') || route.path.includes('/auth')) {
        categories.authentication.push(route);
      } else if (route.path.includes('/restaurants')) {
        categories.restaurants.push(route);
      } else if (route.path.includes('/rsvp') || route.path.includes('/wishlist') || route.path.includes('/visits')) {
        categories.social.push(route);
      } else if (route.path.includes('/admin')) {
        categories.admin.push(route);
      } else {
        categories.system.push(route);
      }
    });

    return categories;
  }

  /**
   * Generate example requests and responses
   */
  generateExamples() {
    return {
      'Send Verification Code': {
        request: {
          method: 'POST',
          url: '/api/verification/send-code',
          headers: { 'Content-Type': 'application/json' },
          body: { phone: '+15551234567' }
        },
        response: {
          status: 200,
          body: {
            success: true,
            message: 'Verification code sent successfully.',
            timestamp: '2025-09-29T00:00:00.000Z'
          }
        }
      },
      'Verify Code and Login': {
        request: {
          method: 'POST',
          url: '/api/verification/verify-code',
          headers: { 'Content-Type': 'application/json' },
          body: {
            phone: '+15551234567',
            code: '123456',
            name: 'John Doe'
          }
        },
        response: {
          status: 200,
          body: {
            success: true,
            message: 'User created and logged in successfully.',
            data: {
              user: {
                id: 'user_123',
                name: 'John Doe',
                phone: '+15551234567',
                createdAt: '2025-09-29T00:00:00.000Z'
              },
              isNewUser: true
            },
            timestamp: '2025-09-29T00:00:00.000Z'
          }
        }
      },
      'Get Current Restaurant': {
        request: {
          method: 'GET',
          url: '/api/restaurants/current',
          headers: { 'Content-Type': 'application/json' }
        },
        response: {
          status: 200,
          body: {
            success: true,
            data: {
              id: 'rest_123',
              name: 'Uchi Austin',
              rating: 4.4,
              priceRange: '$$$',
              cuisine: 'Japanese',
              address: '801 S Lamar Blvd, Austin, TX 78704',
              phone: '(512) 916-4808',
              hours: {
                monday: '5:00 PM - 10:00 PM',
                tuesday: '5:00 PM - 10:00 PM',
                wednesday: '5:00 PM - 10:00 PM',
                thursday: '5:00 PM - 10:00 PM',
                friday: '5:00 PM - 11:00 PM',
                saturday: '5:00 PM - 11:00 PM',
                sunday: '5:00 PM - 10:00 PM'
              },
              imageUrl: 'https://s3-media3.fl.yelpcdn.com/bphoto/...',
              yelpUrl: 'https://www.yelp.com/biz/uchi-austin',
              isFeatured: true
            },
            timestamp: '2025-09-29T00:00:00.000Z'
          }
        }
      }
    };
  }

  /**
   * Get standard error codes
   */
  getErrorCodes() {
    return {
      400: {
        description: 'Bad Request - Invalid input data',
        examples: [
          'Invalid phone number format',
          'Missing required fields',
          'Invalid verification code format'
        ]
      },
      401: {
        description: 'Unauthorized - Authentication required',
        examples: [
          'Missing or invalid Bearer token',
          'Expired JWT token',
          'Invalid verification code'
        ]
      },
      403: {
        description: 'Forbidden - Insufficient permissions',
        examples: [
          'Admin access required',
          'User not authorized for this action'
        ]
      },
      404: {
        description: 'Not Found - Resource not found',
        examples: [
          'Restaurant not found',
          'User not found',
          'Endpoint not found'
        ]
      },
      429: {
        description: 'Too Many Requests - Rate limit exceeded',
        examples: [
          'Too many verification code requests',
          'API rate limit exceeded'
        ]
      },
      500: {
        description: 'Internal Server Error - Server error',
        examples: [
          'Database connection error',
          'External service unavailable',
          'Unexpected server error'
        ]
      },
      503: {
        description: 'Service Unavailable - Service temporarily unavailable',
        examples: [
          'SMS service not configured',
          'Yelp API unavailable',
          'Maintenance mode'
        ]
      }
    };
  }

  /**
   * Generate Markdown documentation
   */
  async generateMarkdown() {
    const doc = await this.generateDocumentation();
    
    let markdown = `# ${doc.info.title} Documentation\n\n`;
    markdown += `**Version:** ${doc.info.version}\n`;
    markdown += `**Base URL:** ${doc.baseUrl}\n`;
    markdown += `**Generated:** ${doc.info.generatedAt}\n\n`;
    
    markdown += `## Overview\n\n`;
    markdown += `${doc.info.description}\n\n`;
    
    markdown += `## Authentication\n\n`;
    markdown += `### Bearer Token\n`;
    markdown += `For protected endpoints, include your Supabase JWT token in the Authorization header:\n\n`;
    markdown += `\`\`\`\nAuthorization: Bearer <your-jwt-token>\n\`\`\`\n\n`;
    
    markdown += `### Phone Verification\n`;
    markdown += `For user registration and login:\n\n`;
    markdown += `1. Send verification code: \`POST /api/verification/send-code\`\n`;
    markdown += `2. Verify code and login: \`POST /api/verification/verify-code\`\n\n`;
    
    // Add endpoint documentation
    Object.entries(doc.endpoints).forEach(([category, routes]) => {
      if (routes.length > 0) {
        markdown += `## ${category.charAt(0).toUpperCase() + category.slice(1)} Endpoints\n\n`;
        
        routes.forEach(route => {
          markdown += `### ${route.method} ${route.path}\n\n`;
          markdown += `${route.description}\n\n`;
          
          if (route.auth) {
            markdown += `**Authentication:** ${route.auth}\n\n`;
          }
          
          if (route.parameters && route.parameters.length > 0) {
            markdown += `**Parameters:**\n\n`;
            route.parameters.forEach(param => {
              markdown += `- \`${param.name}\` (${param.type})${param.required ? ' **required**' : ''}: ${param.description}\n`;
            });
            markdown += `\n`;
          }
          
          if (route.example) {
            markdown += `**Example:**\n\n`;
            markdown += `\`\`\`json\n${JSON.stringify(route.example, null, 2)}\n\`\`\`\n\n`;
          }
        });
      }
    });
    
    markdown += `## Error Codes\n\n`;
    Object.entries(doc.errorCodes).forEach(([code, info]) => {
      markdown += `### ${code} - ${info.description}\n\n`;
      if (info.examples) {
        markdown += `Examples:\n`;
        info.examples.forEach(example => {
          markdown += `- ${example}\n`;
        });
        markdown += `\n`;
      }
    });
    
    return markdown;
  }

  /**
   * Save documentation to files
   */
  async saveDocumentation() {
    const docsDir = path.join(__dirname, '../../docs');
    
    try {
      await fs.mkdir(docsDir, { recursive: true });
      
      // Save JSON documentation
      const jsonDoc = await this.generateDocumentation();
      await fs.writeFile(
        path.join(docsDir, 'api-documentation.json'),
        JSON.stringify(jsonDoc, null, 2)
      );
      
      // Save Markdown documentation
      const markdownDoc = await this.generateMarkdown();
      await fs.writeFile(
        path.join(docsDir, 'API_DOCUMENTATION.md'),
        markdownDoc
      );
      
      console.log('✅ API documentation generated successfully');
      console.log(`📁 JSON: ${path.join(docsDir, 'api-documentation.json')}`);
      console.log(`📁 Markdown: ${path.join(docsDir, 'API_DOCUMENTATION.md')}`);
      
    } catch (error) {
      console.error('❌ Failed to save documentation:', error);
    }
  }
}

module.exports = APIDocumentationGenerator;

