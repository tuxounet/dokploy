#!/bin/bash
# Script pour démarrer les services Dokploy

set -euo pipefail

# Couleurs pour les messages
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m" # No Color

echo -e "${YELLOW}Démarrage des services Dokploy...${NC}"

# Vérifier si on est root
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}Ce script doit être exécuté en tant que root${NC}" >&2
    exit 1
fi

# Démarrer les services Docker Swarm (scale à 1 réplique)
echo "Démarrage des services Docker Swarm..."

for service in dokploy-postgres dokploy-redis dokploy; do
    if docker service inspect "$service" >/dev/null 2>&1; then
        echo "Démarrage du service $service..."
        docker service scale "$service=1" --detach=false 2>/dev/null || docker service update --replicas=1 "$service"
        echo -e "${GREEN}✓ $service démarré${NC}"
    else
        echo -e "${RED}✗ Service $service non trouvé. Exécutez 'make install' d'abord.${NC}"
        exit 1
    fi
done

# Démarrer le conteneur Traefik
echo "Démarrage du conteneur dokploy-traefik..."
if docker container inspect dokploy-traefik >/dev/null 2>&1; then
    docker container start dokploy-traefik 2>/dev/null || true
    echo -e "${GREEN}✓ dokploy-traefik démarré${NC}"
else
    echo -e "${RED}✗ Conteneur dokploy-traefik non trouvé. Exécutez 'make install' d'abord.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Tous les services Dokploy ont été démarrés.${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Accédez à Dokploy sur: http://localhost:3000${NC}"
