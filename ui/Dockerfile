# Nginx-based UI application with configurable path

FROM nginx:alpine

# Install curl for health checks
RUN apk add --no-cache curl

# Build argument for dynamic UI path (BASE_URL is runtime only)
ARG UI_PATH=ui

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Create the UI directory based on build arg
RUN mkdir -p /usr/share/nginx/html/${UI_PATH}

# Copy UI build files to dynamic path
COPY ifrs-ui-build/ /usr/share/nginx/html/${UI_PATH}/

# Copy and update replace-env.sh with dynamic UI path
COPY replace-env.sh /tmp/replace-env.sh
RUN sed "s|UI_PATH_PLACEHOLDER|${UI_PATH}|g" /tmp/replace-env.sh > /usr/local/bin/replace-env.sh && \
    chmod +x /usr/local/bin/replace-env.sh && \
    rm /tmp/replace-env.sh

# Copy custom nginx configuration template
COPY default.conf /tmp/default.conf.template

# Replace placeholders in nginx config and move to final location
RUN sed "s|UI_PATH_PLACEHOLDER|${UI_PATH}|g" /tmp/default.conf.template > /etc/nginx/conf.d/default.conf && \
    rm /tmp/default.conf.template

# Environment variables for runtime (BASE_URL will be set at runtime)
ENV UI_PATH=${UI_PATH}

# Expose port 80
EXPOSE 80

# Add healthcheck with dynamic path
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/${UI_PATH}/ || exit 1

# Start script that runs replace-env.sh and then nginx
CMD ["/bin/sh", "-c", "/usr/local/bin/replace-env.sh && exec nginx -g 'daemon off;'"]
