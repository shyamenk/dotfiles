#!/bin/bash

# Check if project name is provided
if [ -z "$1" ]; then
  echo "Usage: ./create-typescript-express-project.sh <project-name>"
  exit 1
fi

PROJECT_NAME="$1"

echo "Creating TypeScript Express project: $PROJECT_NAME"

# Create project directory
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Initialize git repository
git init

# Create directory structure
mkdir -p src/app
mkdir -p src/configs
mkdir -p src/controllers
mkdir -p src/models
mkdir -p src/routes
mkdir -p src/middlewares
mkdir -p src/services
mkdir -p src/utils
mkdir -p src/types
mkdir -p src/tests
mkdir -p logs

# Create package.json
cat > package.json << 'EOF'
{
  "name": "express-typescript-app",
  "version": "1.0.0",
  "description": "TypeScript Express Server with Best Practices",
  "main": "dist/index.js",
  "scripts": {
    "start": "node dist/index.js",
    "dev": "nodemon --exec ts-node src/index.ts",
    "build": "tsc",
    "lint": "eslint . --ext .ts",
    "lint:fix": "eslint . --ext .ts --fix",
    "format": "prettier --write \"src/**/*.ts\"",
    "test": "jest"
  },
  "keywords": [
    "typescript",
    "express",
    "nodejs",
    "docker"
  ],
  "author": "",
  "license": "ISC",
  "dependencies": {
    "compression": "^1.7.4",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1",
    "express": "^4.18.2",
    "express-validator": "^7.0.1",
    "helmet": "^7.0.0",
    "morgan": "^1.10.0",
    "pg": "^8.11.3",
    "typeorm": "^0.3.17",
    "winston": "^3.10.0"
  },
  "devDependencies": {
    "@types/compression": "^1.7.3",
    "@types/cors": "^2.8.14",
    "@types/express": "^4.17.17",
    "@types/morgan": "^1.9.5",
    "@types/node": "^20.6.0",
    "@types/pg": "^8.10.0",
    "@typescript-eslint/eslint-plugin": "^6.7.0",
    "@typescript-eslint/parser": "^6.7.0",
    "eslint": "^8.49.0",
    "eslint-config-prettier": "^9.0.0",
    "eslint-plugin-prettier": "^5.0.0",
    "jest": "^29.7.0",
    "nodemon": "^3.0.1",
    "prettier": "^3.0.3",
    "ts-jest": "^29.1.1",
    "ts-node": "^10.9.1",
    "typescript": "^5.2.2"
  }
}
EOF

# Create tsconfig.json
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "baseUrl": "./src",
    "outDir": "./dist",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "removeComments": true,
    "typeRoots": ["./node_modules/@types", "./src/types"],
    "sourceMap": true,
    "paths": {
      "@app/*": ["app/*"],
      "@configs/*": ["configs/*"],
      "@controllers/*": ["controllers/*"],
      "@middlewares/*": ["middlewares/*"],
      "@models/*": ["models/*"],
      "@routes/*": ["routes/*"],
      "@services/*": ["services/*"],
      "@utils/*": ["utils/*"]
    }
  },
  "include": ["src/**/*.ts"],
  "exclude": ["node_modules", "dist"]
}
EOF

# Create eslint.config.js
cat > eslint.config.js << 'EOF'
module.exports = {
  root: true,
  env: {
    node: true,
    es2022: true,
  },
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 2022,
    sourceType: 'module',
    project: './tsconfig.json',
  },
  plugins: ['@typescript-eslint', 'prettier'],
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:@typescript-eslint/recommended-requiring-type-checking',
    'plugin:prettier/recommended',
  ],
  rules: {
    'prettier/prettier': 'error',
    '@typescript-eslint/explicit-function-return-type': 'error',
    '@typescript-eslint/no-explicit-any': 'warn',
    '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
    'no-console': 'warn',
    'no-return-await': 'error',
    'no-throw-literal': 'error',
    'prefer-const': 'error',
    'no-duplicate-imports': 'error',
    'eqeqeq': ['error', 'always'],
    'no-var': 'error',
  },
  overrides: [
    {
      files: ['*.test.ts', '*.spec.ts'],
      env: {
        jest: true,
      },
      rules: {
        '@typescript-eslint/no-explicit-any': 'off',
      },
    },
  ],
};
EOF

# Create .prettierrc
cat > .prettierrc << 'EOF'
{
  "semi": true,
  "trailingComma": "all",
  "singleQuote": true,
  "printWidth": 100,
  "tabWidth": 2,
  "endOfLine": "auto",
  "arrowParens": "avoid",
  "bracketSpacing": true
}
EOF

# Create .gitignore
cat > .gitignore << 'EOF'
# dependencies
/node_modules
/.pnp
.pnp.js

# testing
/coverage

# production build
/dist
/build

# env files
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# logs
npm-debug.log*
yarn-debug.log*
yarn-error.log*
logs
*.log

# IDE
.idea
.vscode
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Docker
docker-volumes/
EOF

# Create .env.example
cat > .env.example << 'EOF'
# Server Configuration
NODE_ENV=development
PORT=3000
API_PREFIX=/api/v1
CORS_ORIGIN=*

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=mydatabase
DB_USER=username
DB_PASSWORD=password

# JWT Configuration
JWT_SECRET=your_jwt_secret_key
JWT_EXPIRATION=1d

# Logging
LOG_LEVEL=info
LOG_FORMAT=combined

# Rate Limiting
RATE_LIMIT_WINDOW=15
RATE_LIMIT_MAX_REQUESTS=100
EOF

# Create Dockerfile
cat > Dockerfile << 'EOF'
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm ci

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Production stage
FROM node:18-alpine AS production

WORKDIR /app

# Set NODE_ENV to production
ENV NODE_ENV production

# Copy package files and install production dependencies only
COPY package*.json ./
RUN npm ci --omit=dev

# Copy built application from builder stage
COPY --from=builder /app/dist ./dist

# Copy .env file if it exists (will be overridden by environment variables if provided)
COPY .env* ./

# Expose the port the app runs on
EXPOSE 3000

# Start the application
CMD ["node", "dist/index.js"]
EOF

# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  app:
    container_name: express-app
    build:
      context: .
      dockerfile: Dockerfile
      target: production
    restart: always
    ports:
      - "${PORT:-3000}:3000"
    environment:
      - NODE_ENV=${NODE_ENV:-production}
      - PORT=3000
      - DB_HOST=postgres
      - DB_PORT=5432
      - DB_NAME=${DB_NAME:-mydatabase}
      - DB_USER=${DB_USER:-username}
      - DB_PASSWORD=${DB_PASSWORD:-password}
    depends_on:
      - postgres
    volumes:
      - ./logs:/app/logs
    networks:
      - app-network

  postgres:
    container_name: postgres
    image: postgres:latest
    restart: always
    ports:
      - "${POSTGRES_PORT:-5432}:5432"
    environment:
      POSTGRES_USER: ${DB_USER:-username}
      POSTGRES_PASSWORD: ${DB_PASSWORD:-password}
      POSTGRES_DB: ${DB_NAME:-mydatabase}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - app-network

networks:
  app-network:
    driver: bridge

volumes:
  postgres_data:
EOF

# Create src/index.ts
cat > src/index.ts << 'EOF'
import dotenv from 'dotenv';
dotenv.config();

import { createServer } from './app/server';

const PORT = process.env.PORT || 3000;

async function startServer(): Promise<void> {
  const app = createServer();
  
  app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
  });

  // Handle termination signals
  process.on('SIGTERM', () => {
    console.log('SIGTERM received, shutting down gracefully');
    process.exit(0);
  });

  process.on('SIGINT', () => {
    console.log('SIGINT received, shutting down gracefully');
    process.exit(0);
  });
}

startServer().catch(error => {
  console.error('Failed to start server:', error);
  process.exit(1);
});
EOF

# Create src/app/server.ts
cat > src/app/server.ts << 'EOF'
import express, { Express } from 'express';
import helmet from 'helmet';
import cors from 'cors';
import morgan from 'morgan';
import compression from 'compression';
import { appConfig } from '../configs/app.config';
import { errorMiddleware } from '../middlewares/error.middleware';
import { routes } from '../routes';

export function createServer(): Express {
  const app = express();

  // Set security HTTP headers
  app.use(helmet());

  // Enable CORS
  app.use(cors({
    origin: appConfig.corsOrigin,
    credentials: true,
  }));

  // Request logging
  app.use(morgan(appConfig.logFormat));

  // Parse JSON body
  app.use(express.json());

  // Parse URL-encoded bodies
  app.use(express.urlencoded({ extended: true }));

  // Compress responses
  app.use(compression());

  // API routes
  app.use(appConfig.apiPrefix, routes);

  // Health check route
  app.get('/health', (req, res) => {
    res.status(200).json({ status: 'ok' });
  });

  // Error handling middleware
  app.use(errorMiddleware);

  return app;
}
EOF

# Create src/configs/app.config.ts
cat > src/configs/app.config.ts << 'EOF'
interface AppConfig {
  nodeEnv: string;
  port: number;
  apiPrefix: string;
  corsOrigin: string | string[];
  logFormat: string;
  logLevel: string;
}

export const appConfig: AppConfig = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '3000', 10),
  apiPrefix: process.env.API_PREFIX || '/api/v1',
  corsOrigin: process.env.CORS_ORIGIN || '*',
  logFormat: process.env.LOG_FORMAT || 'combined',
  logLevel: process.env.LOG_LEVEL || 'info',
};
EOF

# Create src/configs/database.config.ts
cat > src/configs/database.config.ts << 'EOF'
interface DatabaseConfig {
  host: string;
  port: number;
  name: string;
  user: string;
  password: string;
  connectionString: string;
}

export const dbConfig: DatabaseConfig = {
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432', 10),
  name: process.env.DB_NAME || 'mydatabase',
  user: process.env.DB_USER || 'username',
  password: process.env.DB_PASSWORD || 'password',
  get connectionString(): string {
    return `postgresql://${this.user}:${this.password}@${this.host}:${this.port}/${this.name}`;
  }
};
EOF

# Create src/configs/logger.config.ts
cat > src/configs/logger.config.ts << 'EOF'
import winston from 'winston';
import { appConfig } from './app.config';

export const logger = winston.createLogger({
  level: appConfig.logLevel,
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      ),
    }),
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: 'logs/combined.log' }),
  ],
});

// Don't log during tests
if (process.env.NODE_ENV === 'test') {
  logger.transports.forEach(transport => {
    transport.silent = true;
  });
}
EOF

# Create src/middlewares/error.middleware.ts
cat > src/middlewares/error.middleware.ts << 'EOF'
import { Request, Response, NextFunction } from 'express';
import { logger } from '../configs/logger.config';
import { AppError } from '../utils/error.util';

export function errorMiddleware(
  error: Error | AppError,
  req: Request,
  res: Response,
  next: NextFunction
): void {
  if (error instanceof AppError) {
    logger.error(`Error: ${error.message}`, {
      statusCode: error.statusCode,
      stack: error.stack,
    });

    res.status(error.statusCode).json({
      success: false,
      message: error.message,
      ...(process.env.NODE_ENV === 'development' && { stack: error.stack }),
    });
  } else {
    logger.error(`Unexpected Error: ${error.message}`, {
      stack: error.stack,
    });

    res.status(500).json({
      success: false,
      message: 'Internal Server Error',
      ...(process.env.NODE_ENV === 'development' && { stack: error.stack }),
    });
  }
}
EOF

# Create src/utils/error.util.ts
cat > src/utils/error.util.ts << 'EOF'
export class AppError extends Error {
  constructor(
    public message: string,
    public statusCode: number = 500,
    public isOperational: boolean = true,
    public stack: string = ''
  ) {
    super(message);
    if (stack) {
      this.stack = stack;
    } else {
      Error.captureStackTrace(this, this.constructor);
    }
  }
}
EOF

# Create src/routes/index.ts
cat > src/routes/index.ts << 'EOF'
import { Router } from 'express';
import { healthCheckRouter } from './health-check.route';

const router = Router();

router.use('/health-check', healthCheckRouter);

export { router as routes };
EOF

# Create src/routes/health-check.route.ts
cat > src/routes/health-check.route.ts << 'EOF'
import { Router } from 'express';

const router = Router();

router.get('/', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

export { router as healthCheckRouter };
EOF

# Create src/models/index.ts
cat > src/models/index.ts << 'EOF'
// Placeholder for models
EOF

# Create src/controllers/index.ts
cat > src/controllers/index.ts << 'EOF'
// Placeholder for controllers
EOF

# Create src/services/index.ts
cat > src/services/index.ts << 'EOF'
// Placeholder for services
EOF

# Create src/utils/index.ts
cat > src/utils/index.ts << 'EOF'
// Placeholder for utility functions
EOF

# Create src/middlewares/index.ts
cat > src/middlewares/index.ts << 'EOF'
// Placeholder for middlewares
EOF

# Create src/types/index.ts
cat > src/types/index.ts << 'EOF'
// Placeholder for custom types
EOF

# Create src/tests/index.test.ts
cat > src/tests/index.test.ts << 'EOF'
import request from 'supertest';
import { createServer } from '../app/server';

describe('Health Check', () => {
  it('should return 200 OK', async () => {
    const app = createServer();
    const response = await request(app).get('/health');
    expect(response.status).toBe(200);
  });
});
EOF

# Create nodemon.json
cat > nodemon.json << 'EOF'
{
  "watch": ["src"],
  "ext": "ts",
  "ignore": ["src/**/*.test.ts", "src/**/*.spec.ts"],
  "exec": "ts-node src/index.ts"
}
EOF

# Install dependencies
npm install --legacy-peer-deps

# Initialize TypeORM
npx typeorm init --database postgres

# Format the code
npm run format

# Initialize ESLint
npx eslint --init

echo "Project setup completed successfully!"
