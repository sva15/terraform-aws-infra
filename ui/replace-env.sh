#!/bin/sh

# Replace BASE_URL environment variable in UI assets at runtime
# UI_PATH is handled at build time, only BASE_URL is replaced at runtime

echo "Starting BASE_URL replacement..."
echo "BASE_URL: ${BASE_URL}"

# Replace BASE_URL in env.js file (UI_PATH_PLACEHOLDER will be replaced during build)
if [ -f "/usr/share/nginx/html/UI_PATH_PLACEHOLDER/assets/env.js" ]; then
    echo "Replacing BASE_URL in env.js..."
    sed -i "s|\${BASE_URL}|${BASE_URL}|g" /usr/share/nginx/html/UI_PATH_PLACEHOLDER/assets/env.js
    echo "BASE_URL replacement completed"
else
    echo "Warning: env.js file not found at /usr/share/nginx/html/UI_PATH_PLACEHOLDER/assets/env.js"
fi

echo "BASE_URL replacement completed successfully!"
