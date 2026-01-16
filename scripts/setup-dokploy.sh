#!/usr/bin/env bash
set -euo pipefail

# Configuration
         # dossier contenant docker-compose.yml
DOKPLOY_URL="http://127.0.0.1:3000"   # adapter si vous utilisez un domaine
ADMIN_EMAIL="admin@example.com"
ADMIN_PASSWORD="ChangeMeStrong!123"
ADMIN_NAME="Admin"
API_KEY_FILE="/etc/dokploy/admin_api_key.txt"
WAIT_TIMEOUT=30


 
# echo "2) Attente que l'API soit disponible... (${DOKPLOY_URL}/api)"
# end=$((SECONDS + WAIT_TIMEOUT))
# until curl -sSf "${DOKPLOY_URL}/api" >/dev/null 2>&1 || [ $SECONDS -ge $end ]; do
#   echo "L'API n'est pas encore disponible, attente..."
#   sleep 2
# done
# if ! curl -sSf "${DOKPLOY_URL}/api" >/dev/null 2>&1; then
#   echo "Erreur : l'API Dokploy n'est pas disponible après ${WAIT_TIMEOUT}s" >&2
#   exit 1
# fi

echo "2) Création du premier utilisateur admin..."
if [ ! -f "$API_KEY_FILE" ]; then
    

  SIGNUP_RESPONSE=$(curl -sS 'http://localhost:3000/api/auth/sign-up/email' \
    -H 'Accept: */*' \
    -H 'Accept-Language: fr,fr-FR;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6' \
    -H 'Connection: keep-alive' \
    -H 'Origin: http://localhost:3000' \
    -H 'Referer: http://localhost:3000/register' \
    -H 'Sec-Fetch-Dest: empty' \
    -H 'Sec-Fetch-Mode: cors' \
    -H 'Sec-Fetch-Site: same-origin' \
    -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36 Edg/143.0.0.0' \
    -H 'content-type: application/json' \
    -H 'sec-ch-ua: "Microsoft Edge";v="143", "Chromium";v="143", "Not A(Brand";v="24"' \
    -H 'sec-ch-ua-mobile: ?0' \
    -H 'sec-ch-ua-platform: "Windows"' \
    --data-raw "{\"email\":\"${ADMIN_EMAIL}\",\"password\":\"${ADMIN_PASSWORD}\",\"name\":\"${ADMIN_NAME}\",\"lastName\":\"Admin\"}")

  # Extraction du token depuis la réponse JSON
  API_TOKEN=$(echo "$SIGNUP_RESPONSE" | jq -r '.token // empty')

  if [ -z "$API_TOKEN" ]; then
    echo "Erreur : impossible d'extraire le token de la réponse d'inscription." >&2
    echo "Réponse reçue : $SIGNUP_RESPONSE" >&2
    exit 1
  fi

    # Sauvegarde du token dans le fichier
  sudo mkdir -p "$(dirname "$API_KEY_FILE")"
  echo "$API_TOKEN" | sudo tee "$API_KEY_FILE" >/dev/null
  sudo chmod 600 "$API_KEY_FILE"
  echo "Token API sauvegardé dans $API_KEY_FILE"


els

fi

# Sauvegarde de la clé API Dokploy
DOKPLOY_API_KEY_FILE="$(dirname "$API_KEY_FILE")/dokploy_api_key.txt"
echo "$DOKPLOY_API_KEY" | sudo tee "$DOKPLOY_API_KEY_FILE" >/dev/null
sudo chmod 600 "$DOKPLOY_API_KEY_FILE"
echo "Clé API Dokploy sauvegardée dans $DOKPLOY_API_KEY_FILE"

echo "Setup terminé avec succès !"
