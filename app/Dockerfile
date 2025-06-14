# app/Dockerfile
# Multi-stage build for optimized image size
FROM node:18-alpine AS builder

# Create app directory
WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production && npm cache clean --force

# Production stage
FROM node:18-alpine AS production

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodeuser -u 1001 -G nodejs

# Set working directory
WORKDIR /usr/src/app

# Copy dependencies from builder stage
COPY --from=builder /usr/src/app/node_modules ./node_modules

# Copy application code
COPY --chown=nodeuser:nodejs src/ ./src/
COPY --chown=nodeuser:nodejs package*.json ./

# Create logs directory with proper permissions
RUN mkdir -p /usr/src/app/logs && \
    chown -R nodeuser:nodejs /usr/src/app/logs

# Switch to non-root user
USER nodeuser

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (res) => { \
    process.exit(res.statusCode === 200 ? 0 : 1) \
  }).on('error', () => process.exit(1))"

# Use dumb-init as PID 1 for proper signal handling
ENTRYPOINT ["dumb-init", "--"]

# Start the application
CMD ["node", "src/app.js"]

# Metadata
LABEL maintainer="devops@safle.com" \
      version="1.0.0" \
      description="Safle Node.js Application" \
      security.non-root="true"
