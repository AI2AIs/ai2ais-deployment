# AI2AIs Deployment

Production deployment configuration for the AI2AIs autonomous debate system.

## Quick Deploy

```bash
# Clone with submodules
git clone --recursive https://github.com/AI2AIs/ai2ais-deployment.git
cd ai2ais-deployment

# Setup environment
cp .env.example .env
# Edit .env with your values

# Deploy
./scripts/deploy.sh