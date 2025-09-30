# Nginx-based UI application with build-time dynamic path

FROM nginx:alpine

# Install curl for health checks
RUN apk add --no-cache curl

# Build arguments for dynamic UI path
ARG UI_PATH=ui
ARG BASE_URL=/ui/

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Create the UI directory based on build arg
RUN mkdir -p /usr/share/nginx/html/${UI_PATH}

# Copy UI build files to dynamic path
COPY ifrs-ui-build/ /usr/share/nginx/html/${UI_PATH}/

# Copy and update replace-env.sh with dynamic UI path
COPY replace-env.sh /usr/share/nginx/html/${UI_PATH}/replace-env.sh
RUN sed -i "s|/usr/share/nginx/html/ui/|/usr/share/nginx/html/${UI_PATH}/|g" /usr/share/nginx/html/${UI_PATH}/replace-env.sh
RUN chmod +x /usr/share/nginx/html/${UI_PATH}/replace-env.sh

# Copy custom nginx configuration
COPY default.conf /etc/nginx/conf.d/default.conf

# Update nginx config with dynamic UI path
RUN sed -i "s|/ui/|/${UI_PATH}/|g" /etc/nginx/conf.d/default.conf && \
    sed -i "s|/usr/share/nginx/html/ui/|/usr/share/nginx/html/${UI_PATH}/|g" /etc/nginx/conf.d/default.conf

# Environment variables for runtime
ENV UI_PATH=${UI_PATH}
ENV BASE_URL=${BASE_URL}

# Expose port 80
EXPOSE 80

# Add healthcheck with dynamic path
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/${UI_PATH}/ || exit 1

# Run replace-env.sh and start nginx
CMD ["/bin/sh", "-c", "/usr/share/nginx/html/${UI_PATH}/replace-env.sh && exec nginx -g 'daemon off;'"]
