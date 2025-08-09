#!/bin/bash
# AI2AIs Production Deployment Script

set -e

echo " Starting AI2AIs deployment..."

# Check environment
if [ ! -f ".env" ]; then
    echo "Error: .env file not found!"
    echo "Copy .env.example to .env and configure your settings"
    exit 1
fi

# Load environment
source .env

# Validate required variables
required_vars=("POSTGRES_PASSWORD" "ANTHROPIC_API_KEY" "OPENAI_API_KEY" "XAI_API_KEY")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Error: $var is not set in .env"
        exit 1
    fi
done

echo " Environment validation passed"

# Create directories
mkdir -p logs/{core,frontend,nginx} temp data/voices ssl config

# Stop existing containers
echo "Stopping existing containers..."
docker compose down --remove-orphans

# Build with profiles
echo " Building AI2AIs with profiles: ${COMPOSE_PROFILES:-none}"
if [ -n "${COMPOSE_PROFILES}" ]; then
    export COMPOSE_PROFILES
    docker compose --profile frontend --profile nginx up -d --build
else
    docker compose up -d --build
fi

echo " Waiting for services..."
sleep 45

# Health checks with network-aware URLs
echo " Health checks..."

# Core service (always required)
for i in {1..12}; do
    if curl -f http://localhost:3002/health >/dev/null 2>&1; then
        echo " AI2AIs Core is healthy"
        break
    else
        echo "⏳ Waiting for AI2AIs Core... ($i/12)"
        sleep 10
    fi
    
    if [ $i -eq 12 ]; then
        echo "AI2AIs Core health check failed"
        docker compose logs ai2ais-core
        exit 1
    fi
done

# Optional services health check
if echo "${COMPOSE_PROFILES}" | grep -q "frontend"; then
    if curl -f http://localhost:3000 >/dev/null 2>&1; then
        echo "AI2AIs Frontend is healthy"
    else
        echo "AI2AIs Frontend health check failed"
    fi
fi

if echo "${COMPOSE_PROFILES}" | grep -q "nginx"; then
    if curl -f http://localhost:80/health >/dev/null 2>&1; then
        echo "Nginx is healthy"
    else
        echo "Nginx health check failed"
    fi
fi

echo ""
echo "AI2AIs deployment completed!"
echo ""
echo "   Service URLs:"
echo "   API:        http://localhost:3002"
echo "   Health:     http://localhost:3002/health"
echo "   Characters: http://localhost:3002/api/characters"
echo "   WebSocket:  ws://localhost:3002/ws/{session_id}"

if echo "${COMPOSE_PROFILES}" | grep -q "frontend"; then
    echo "   Frontend:   http://localhost:3000"
fi

if echo "${COMPOSE_PROFILES}" | grep -q "nginx"; then
    echo "   Nginx:      http://localhost:80"
fi

echo ""
echo "   Database URLs (internal network):"
echo "   PostgreSQL: localhost:5432"
echo "   Qdrant:     http://localhost:6333"
echo "   Redis:      localhost:6379"