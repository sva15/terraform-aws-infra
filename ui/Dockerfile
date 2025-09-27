# Multi-stage build for Angular UI application

# Stage 1: Build the Angular application (if needed)
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Build the application (uncomment if you want to build inside Docker)
# RUN npm run build --prod

# Stage 2: Serve with nginx
FROM nginx:alpine

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy built application from dist folder (pre-built with ng build)
COPY dist/ /usr/share/nginx/html/

# Copy custom nginx configuration
COPY default.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
