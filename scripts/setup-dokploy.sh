#!/usr/bin/env bash
set -euo pipefail

# Configuration
         # dossier contenant docker-compose.yml
DOKPLOY_URL="http://localhost:3000"   # adapter si vous utilisez un domaine
ADMIN_EMAIL="admin@example.com"
ADMIN_PASSWORD="ChangeMeStrong!123"
ADMIN_NAME="Admin"
API_KEY_FILE="/etc/dokploy/admin_api_key.txt"
WAIT_TIMEOUT=30


 
echo "2) Attente que l'API soit disponible... (${DOKPLOY_URL}/api)"
end=$((SECONDS + WAIT_TIMEOUT))
until curl -sSf "${DOKPLOY_URL}/api" >/dev/null 2>&1 || [ $SECONDS -ge $end ]; do
  sleep 2
done
if ! curl -sSf "${DOKPLOY_URL}/api" >/dev/null 2>&1; then
  echo "Erreur : l'API Dokploy n'est pas disponible après ${WAIT_TIMEOUT}s" >&2
  exit 1
fi

echo "3) Vérification s'il existe déjà des utilisateurs..."
USERS_COUNT=$(curl -sS "${DOKPLOY_URL}/api/user.all" -H "x-api-key: " 2>/dev/null || true)
# Si l'API requiert une clé pour user.all, on tente sans clé et on parse la réponse
if echo "$USERS_COUNT" | jq -e '.data | length > 0' >/dev/null 2>&1; then
  echo "Des utilisateurs existent déjà. Rien à faire."
  exit 0
fi

echo "4) Création du premier utilisateur via un script headless (Puppeteer)..."
# Crée et exécute un script Node.js temporaire qui soumet le formulaire d'inscription
TMP_JS="$(mktemp --suffix=.js)"
cat > "$TMP_JS" <<'NODE'
const puppeteer = require('puppeteer');
(async () => {
  const url = process.env.DOKPLOY_URL || 'http://localhost:3000';
  const email = process.env.ADMIN_EMAIL;
  const password = process.env.ADMIN_PASSWORD;
  const name = process.env.ADMIN_NAME;
  const browser = await puppeteer.launch({ args: ['--no-sandbox'] });
  const page = await browser.newPage();
  await page.goto(`${url}/register`, { waitUntil: 'networkidle2' });
  // Ajuster les sélecteurs si nécessaire
  await page.type('input[name="email"]', email);
  await page.type('input[name="password"]', password);
  await page.type('input[name="name"]', name);
  await Promise.all([
    page.click('button[type="submit"]'),
    page.waitForNavigation({ waitUntil: 'networkidle2', timeout: 15000 }).catch(()=>{})
  ]);
  console.log('REGISTER_DONE');
  await browser.close();
})();
NODE

# Exécuter le script (installe puppeteer si nécessaire)
NODE_ENV=production ADMIN_EMAIL="$ADMIN_EMAIL" ADMIN_PASSWORD="$ADMIN_PASSWORD" ADMIN_NAME="$ADMIN_NAME" DOKPLOY_URL="$DOKPLOY_URL" \
  bash -lc "npm install puppeteer@latest --no-audit --no-fund >/dev/null && node $TMP_JS"

rm -f "$TMP_JS"

echo "5) Récupération de la clé admin : création d'une API key pour l'utilisateur créé..."
# Ici on suppose que l'utilisateur peut créer une API key via /api/user.createApiKey en s'authentifiant.
# On simule une connexion pour obtenir une clé admin temporaire via le formulaire de login (si nécessaire).
# Pour simplifier, on tente d'appeler directement createApiKey sans x-api-key (adapter si votre instance exige auth)
CREATE_RESP=$(curl -sS -X POST "${DOKPLOY_URL}/api/user.createApiKey" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"automation-key\",\"metadata\":{\"purpose\":\"bootstrap\"}}")

API_KEY=$(echo "$CREATE_RESP" | jq -r '.data?.key // empty')

if [ -z "$API_KEY" ]; then
  echo "Échec : impossible de créer la clé API automatiquement. Vérifiez les logs et la configuration d'authentification." >&2
  exit 1
fi

echo "$API_KEY" | sudo tee "$API_KEY_FILE" >/dev/null
sudo chmod 600 "$API_KEY_FILE"
echo "Clé admin sauvegardée dans $API_KEY_FILE"
