# Multi-stage Dockerfile for React frontend with security best practices
# NOTE: Base images should be regularly updated to address security vulnerabilities
#       Run 'docker scan' before deployment to verify security status

# Build stage
FROM node:20.11.1-alpine3.19 AS build
WORKDIR /app

# Add package files and install dependencies with explicit version pinning
COPY package*.json ./
RUN npm ci --production=false

# Add source code and build the application
COPY . .
RUN npm run build

# Production stage
FROM nginxinc/nginx-unprivileged:1.25-alpine
WORKDIR /usr/share/nginx/html

# Create nginx user if it doesn't exist
RUN if ! id -u nginx > /dev/null 2>&1; then \
      addgroup -g 101 -S nginx && \
      adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx; \
    fi

# Copy nginx configuration
COPY ./nginx/nginx.conf /etc/nginx/conf.d/default.conf

# Remove default nginx static assets
RUN rm -rf ./*

# Copy static assets from builder stage
COPY --from=build --chown=nginx:nginx /app/build .

# Use non-root user
USER nginx

# Expose port
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
