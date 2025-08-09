#!/bin/bash
# AI2AIs Health Check Script

echo "AI2AIs System Health Check"
echo "=============================="

# Check if containers are running
echo "Container Status:"
docker compose ps

echo ""
echo "🔍 Service Health Checks:"

# PostgreSQL
if docker compose exec postgres pg_isready -U ai2ais_user -d ai2ais_db >/dev/null 2>&1; then
    echo " PostgreSQL: Healthy"
else
    echo " PostgreSQL: Unhealthy"
fi

# Qdrant
if curl -f http://localhost:6333/health >/dev/null 2>&1; then
    echo "Qdrant: Healthy"
else
    echo "Qdrant: Unhealthy"
fi

# Redis
if docker compose exec redis redis-cli ping >/dev/null 2>&1; then
    echo "Redis: Healthy"
else
    echo "Redis: Unhealthy"
fi

# AI2AIs Core
if curl -f http://localhost:3002/health >/dev/null 2>&1; then
    echo " AI2AIs Core: Healthy"
    
    # Get detailed health info
    echo ""
    echo "AI2AIs Core Details:"
    curl -s http://localhost:3002/health | jq '.' 2>/dev/null || curl -s http://localhost:3002/health
else
    echo " AI2AIs Core: Unhealthy"
fi

echo ""
echo " Resource Usage:"
docker stats --no-stream

echo ""
echo " Recent Logs (last 10 lines):"
echo "--- AI2AIs Core ---"
docker compose logs --tail=10 ai2ais-core

echo ""
echo "--- PostgreSQL ---"
docker compose logs --tail=5 postgres

echo ""
echo "🔗 Service URLs:"
echo "   API:        http://localhost:3002"
echo "   Health:     http://localhost:3002/health"
echo "   Characters: http://localhost:3002/api/characters"
echo "   WebSocket:  ws://localhost:3002/ws/{session_id}"
echo "   Qdrant:     http://localhost:6333"