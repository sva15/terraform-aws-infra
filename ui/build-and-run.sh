#!/bin/bash

# Build and run script for the UI container with build-time dynamic path

set -e

# Configuration
IMAGE_NAME="ifrs-ui-dynamic"
IMAGE_TAG="latest"
CONTAINER_NAME="ifrs-ui-container"

# Default values (can be overridden)
UI_PATH="${UI_PATH:-ui}"
BASE_URL="${BASE_URL:-/ui/}"
PORT="${PORT:-8080}"

echo "=== Building IFRS UI Container with Build Args ==="
echo "Image: $IMAGE_NAME:$IMAGE_TAG"
echo "UI Path: $UI_PATH"
echo "Base URL: $BASE_URL"
echo ""

# Check if ifrs-ui-build directory exists
if [ ! -d "ifrs-ui-build" ]; then
    echo "❌ Error: ifrs-ui-build directory not found!"
    echo "Please ensure the UI build files are downloaded from S3 to ./ifrs-ui-build/"
    echo ""
    echo "Expected structure:"
    echo "  ./ifrs-ui-build/"
    echo "    ├── index.html"
    echo "    ├── main.js"
    echo "    ├── styles.css"
    echo "    └── assets/"
    exit 1
fi

echo "✅ Found ifrs-ui-build directory"
echo "Contents:"
ls -la ifrs-ui-build/
echo ""

# Build the Docker image with build arguments
echo "Building Docker image with build args..."
docker build \
    --build-arg UI_PATH="$UI_PATH" \
    --build-arg BASE_URL="$BASE_URL" \
    -t "$IMAGE_NAME:$IMAGE_TAG" .

if [ $? -eq 0 ]; then
    echo "✅ Docker image built successfully!"
else
    echo "❌ Docker build failed!"
    exit 1
fi

# Stop and remove existing container if it exists
echo ""
echo "Cleaning up existing container..."
docker stop "$CONTAINER_NAME" 2>/dev/null || true
docker rm "$CONTAINER_NAME" 2>/dev/null || true

# Run the container
echo ""
echo "Starting container..."
echo "Container will be available at: http://localhost:$PORT$BASE_URL"

docker run -d \
    --name "$CONTAINER_NAME" \
    -p "$PORT:80" \
    -e BASE_URL="$BASE_URL" \
    "$IMAGE_NAME:$IMAGE_TAG"

if [ $? -eq 0 ]; then
    echo "✅ Container started successfully!"
    echo ""
    echo "Container Details:"
    echo "  Name: $CONTAINER_NAME"
    echo "  Port: $PORT"
    echo "  UI URL: http://localhost:$PORT$BASE_URL"
    echo "  Health Check: http://localhost:$PORT/health"
    echo ""
    echo "To view logs: docker logs $CONTAINER_NAME"
    echo "To stop: docker stop $CONTAINER_NAME"
    echo ""
    
    # Wait a moment and check if container is still running
    sleep 3
    if docker ps | grep -q "$CONTAINER_NAME"; then
        echo "✅ Container is running successfully!"
        
        # Show initial logs
        echo ""
        echo "=== Initial Container Logs ==="
        docker logs "$CONTAINER_NAME"
    else
        echo "❌ Container failed to start. Check logs:"
        docker logs "$CONTAINER_NAME"
        exit 1
    fi
else
    echo "❌ Failed to start container!"
    exit 1
fi
