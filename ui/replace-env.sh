#!/bin/sh

# Replace environment variables in UI assets at runtime
# This script will be updated during Docker build to use the correct UI_PATH

echo "Starting environment variable replacement..."
echo "UI_PATH: ${UI_PATH}"
echo "BASE_URL: ${BASE_URL}"

# Replace BASE_URL in env.js file
if [ -f "/usr/share/nginx/html/ui/assets/env.js" ]; then
    echo "Replacing BASE_URL in env.js..."
    sed -i "s|\${BASE_URL}|${BASE_URL}|g" /usr/share/nginx/html/ui/assets/env.js
    echo "BASE_URL replacement completed"
else
    echo "Warning: env.js file not found at /usr/share/nginx/html/ui/assets/env.js"
fi

# Replace any other environment variables in index.html if needed
if [ -f "/usr/share/nginx/html/ui/index.html" ]; then
    echo "Replacing environment variables in index.html..."
    sed -i "s|\${BASE_URL}|${BASE_URL}|g" /usr/share/nginx/html/ui/index.html
    sed -i "s|\${UI_PATH}|${UI_PATH}|g" /usr/share/nginx/html/ui/index.html
    echo "index.html replacement completed"
fi

# Replace environment variables in any config.js files
find /usr/share/nginx/html/ui -name "*.js" -type f -exec grep -l "\${BASE_URL}\|\${UI_PATH}" {} \; | while read file; do
    echo "Replacing environment variables in: $file"
    sed -i "s|\${BASE_URL}|${BASE_URL}|g" "$file"
    sed -i "s|\${UI_PATH}|${UI_PATH}|g" "$file"
done

echo "Environment variable replacement completed successfully!"
