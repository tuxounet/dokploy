#!/bin/bash
# Script pour arrêter les services Dokploy sans les supprimer

set -euo pipefail

# Couleurs pour les messages
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m" # No Color

echo -e "${YELLOW}Arrêt des services Dokploy...${NC}"

# Vérifier si on est root
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}Ce script doit être exécuté en tant que root${NC}" >&2
    exit 1
fi

# Arrêter le conteneur Traefik (lancé via docker run)
echo "Arrêt du conteneur dokploy-traefik..."
if docker container inspect dokploy-traefik >/dev/null 2>&1; then
    docker container stop dokploy-traefik
    echo -e "${GREEN}✓ dokploy-traefik arrêté${NC}"
else
    echo -e "${YELLOW}⚠ dokploy-traefik non trouvé ou déjà arrêté${NC}"
fi

# Mettre à l'échelle les services swarm à 0 répliques (les arrête sans supprimer)
echo "Arrêt des services Docker Swarm..."

for service in dokploy dokploy-postgres dokploy-redis; do
    if docker service inspect "$service" >/dev/null 2>&1; then
        echo "Arrêt du service $service..."
        docker service scale "$service=0" --detach=false 2>/dev/null || docker service update --replicas=0 "$service"
        echo -e "${GREEN}✓ $service arrêté${NC}"
    else
        echo -e "${YELLOW}⚠ Service $service non trouvé${NC}"
    fi
done

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Tous les services Dokploy ont été arrêtés.${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Pour redémarrer les services, exécutez:${NC}"
echo "  docker container start dokploy-traefik"
echo "  docker service scale dokploy=1 dokploy-postgres=1 dokploy-redis=1"
echo ""
echo -e "${YELLOW}Pour désinstaller complètement Dokploy, utilisez:${NC}"
echo "  make uninstall"
