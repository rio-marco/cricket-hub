import swaggerJSDoc from 'swagger-jsdoc';
import config from './env';

const swaggerDefinition: swaggerJSDoc.OAS3Definition = {
  openapi: '3.0.0',
  info: {
    title: 'Cricket Hub API',
    version: '1.0.0',
    description: 'RESTful API for the Cricket Hub Management System. Supports live scoring, tournament management, teams, players, real-time ball-by-ball updates, and auctions.',
    contact: {
      name: 'Cricket Hub API Support',
      email: 'support@crickethub.app',
    },
    license: {
      name: 'ISC',
      url: 'https://opensource.org/licenses/ISC',
    },
  },
  servers: [
    {
      url: `http://localhost:${config.PORT}/api/v1`,
      description: 'Local Development Server (v1)',
    },
    {
      url: '/api/v1',
      description: 'Current Host (Relative URL)',
    },
  ],
  components: {
    securitySchemes: {
      bearerAuth: {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        description: 'Enter your JWT token to access protected endpoints. Example: "Bearer {token}"',
      },
    },
    schemas: {
      ApiResponse: {
        type: 'object',
        properties: {
          success: {
            type: 'boolean',
            example: true,
          },
          message: {
            type: 'string',
            example: 'Operation completed successfully',
          },
          data: {
            type: 'object',
            description: 'Payload data',
          },
        },
      },
      ApiErrorResponse: {
        type: 'object',
        properties: {
          success: {
            type: 'boolean',
            example: false,
          },
          message: {
            type: 'string',
            example: 'An error occurred while processing the request',
          },
          error: {
            type: 'object',
            properties: {
              statusCode: {
                type: 'integer',
                example: 400,
              },
              errors: {
                type: 'array',
                items: {
                  type: 'string',
                },
                example: ['Field validation error message'],
              },
            },
          },
        },
      },
      PaginationMetadata: {
        type: 'object',
        properties: {
          page: {
            type: 'integer',
            example: 1,
          },
          limit: {
            type: 'integer',
            example: 10,
          },
          total: {
            type: 'integer',
            example: 42,
          },
          totalPages: {
            type: 'integer',
            example: 5,
          },
          hasNextPage: {
            type: 'boolean',
            example: true,
          },
          hasPrevPage: {
            type: 'boolean',
            example: false,
          },
        },
      },
      PaginatedResponse: {
        type: 'object',
        properties: {
          success: {
            type: 'boolean',
            example: true,
          },
          message: {
            type: 'string',
            example: 'Records retrieved successfully',
          },
          data: {
            type: 'array',
            items: {},
          },
          pagination: {
            $ref: '#/components/schemas/PaginationMetadata',
          },
        },
      },
      User: {
        type: 'object',
        properties: {
          _id: { type: 'string', example: '60d0fe4f5311236168a109ca' },
          name: { type: 'string', example: 'Virat Kohli' },
          email: { type: 'string', format: 'email', example: 'virat@crickethub.app' },
          phone: { type: 'string', example: '+919876543210' },
          avatar: { type: 'string', example: 'https://example.com/avatars/virat.jpg' },
          role: {
            type: 'string',
            enum: ['NORMAL_USER', 'TEAM_OWNER', 'PLAYER', 'TOURNAMENT_ORGANIZER', 'SCORER', 'ADMIN'],
            example: 'PLAYER',
          },
          isVerified: { type: 'boolean', example: true },
          isBlocked: { type: 'boolean', example: false },
          createdAt: { type: 'string', format: 'date-time' },
          updatedAt: { type: 'string', format: 'date-time' },
        },
      },
      Player: {
        type: 'object',
        properties: {
          _id: { type: 'string', example: '60d0fe4f5311236168a109cb' },
          user: { $ref: '#/components/schemas/User' },
          playingRole: {
            type: 'string',
            enum: ['BATSMAN', 'BOWLER', 'ALL_ROUNDER', 'WICKETKEEPER'],
            example: 'BATSMAN',
          },
          battingStyle: {
            type: 'string',
            enum: ['RIGHT_HAND', 'LEFT_HAND'],
            example: 'RIGHT_HAND',
          },
          bowlingStyle: {
            type: 'string',
            enum: [
              'RIGHT_ARM_FAST', 'RIGHT_ARM_MEDIUM', 'LEFT_ARM_FAST', 'LEFT_ARM_MEDIUM',
              'RIGHT_ARM_OFF_SPIN', 'RIGHT_ARM_LEG_SPIN', 'LEFT_ARM_ORTHODOX', 'LEFT_ARM_CHINAMAN', 'NONE'
            ],
            example: 'RIGHT_ARM_MEDIUM',
          },
          jerseyNumber: { type: 'integer', example: 18 },
          dateOfBirth: { type: 'string', format: 'date', example: '1988-11-05' },
          city: { type: 'string', example: 'Delhi' },
          bio: { type: 'string', example: 'Top-order batsman' },
        },
      },
      Team: {
        type: 'object',
        properties: {
          _id: { type: 'string', example: '60d0fe4f5311236168a109cc' },
          name: { type: 'string', example: 'Royal Challengers' },
          logo: { type: 'string', example: 'https://example.com/rcb.png' },
          description: { type: 'string', example: 'City cricket club' },
          location: { type: 'string', example: 'Bengaluru' },
          owner: { type: 'string', example: '60d0fe4f5311236168a109ca' },
          captain: { type: 'string', example: '60d0fe4f5311236168a109cb' },
          isActive: { type: 'boolean', example: true },
        },
      },
      Tournament: {
        type: 'object',
        properties: {
          _id: { type: 'string', example: '60d0fe4f5311236168a109cd' },
          name: { type: 'string', example: 'Premier T20 Cup 2026' },
          organizer: { type: 'string', example: '60d0fe4f5311236168a109ca' },
          format: { type: 'string', enum: ['LEAGUE', 'KNOCKOUT', 'LEAGUE_KNOCKOUT'], example: 'LEAGUE_KNOCKOUT' },
          ballType: { type: 'string', enum: ['TENNIS', 'RED', 'WHITE'], example: 'WHITE' },
          matchFormat: { type: 'string', enum: ['T10', 'T20', 'ODI', 'CUSTOM'], example: 'T20' },
          maxTeams: { type: 'integer', example: 8 },
          status: {
            type: 'string',
            enum: ['DRAFT', 'REGISTRATION_OPEN', 'REGISTRATION_CLOSED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'],
            example: 'REGISTRATION_OPEN',
          },
        },
      },
      Match: {
        type: 'object',
        properties: {
          _id: { type: 'string', example: '60d0fe4f5311236168a109ce' },
          title: { type: 'string', example: 'Match 1 - Final' },
          tournament: { type: 'string', example: '60d0fe4f5311236168a109cd' },
          teamA: { type: 'string', example: '60d0fe4f5311236168a109cc' },
          teamB: { type: 'string', example: '60d0fe4f5311236168a109cf' },
          format: { type: 'string', enum: ['T10', 'T20', 'ODI', 'CUSTOM'], example: 'T20' },
          totalOvers: { type: 'integer', example: 20 },
          ballType: { type: 'string', enum: ['TENNIS', 'RED', 'WHITE'], example: 'WHITE' },
          status: {
            type: 'string',
            enum: ['UPCOMING', 'TOSS', 'LIVE', 'COMPLETED', 'ABANDONED', 'CANCELLED'],
            example: 'LIVE',
          },
          currentInnings: { type: 'integer', example: 1 },
        },
      },
    },
  },
  security: [
    {
      bearerAuth: [],
    },
  ],
};

const swaggerOptions: swaggerJSDoc.Options = {
  swaggerDefinition,
  apis: [
    './src/routes/*.ts',
    './src/routes/**/*.ts',
    './src/controllers/*.ts',
    './src/controllers/**/*.ts',
    './dist/routes/*.js',
    './dist/routes/**/*.js',
  ],
};

export const swaggerSpec = swaggerJSDoc(swaggerOptions);

export default swaggerSpec;
