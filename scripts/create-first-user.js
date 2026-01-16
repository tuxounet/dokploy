const puppeteer = require("puppeteer");
const fs = require("fs");
const path = require("path");

(async () => {
  const url = process.env.DOKPLOY_URL || "http://localhost:3000";
  const email = process.env.ADMIN_EMAIL;
  const password = process.env.ADMIN_PASSWORD;
  const name = process.env.ADMIN_NAME;
  const apiKeyFile = process.env.API_KEY_FILE || "/etc/dokploy/admin_api_key.txt";
  
  const browser = await puppeteer.launch({ args: ["--no-sandbox"] });
  const page = await browser.newPage();
  
  // Intercept API responses to capture the token
  let capturedApiKey = null;
  page.on("response", async (response) => {
    const reqUrl = response.url();
    if (reqUrl.includes("/api/user.createApiToken") || reqUrl.includes("/api/user.createApiKey")) {
      try {
        const json = await response.json();
        if (json?.key) {
          capturedApiKey = json.key;
        } else if (json?.data?.key) {
          capturedApiKey = json.data.key;
        }
      } catch (e) {
        // Response might not be JSON
      }
    }
  });

  // Step 1: Register the user
  await page.goto(`${url}/register`, { waitUntil: "networkidle2" });
  await page.type('input[name="email"]', email);
  await page.type('input[name="password"]', password);
  await page.type('input[name="name"]', name);
  await Promise.all([
    page.click('button[type="submit"]'),
    page
      .waitForNavigation({ waitUntil: "networkidle2", timeout: 15000 })
      .catch(() => {}),
  ]);
  console.log("REGISTER_DONE");

  // Step 2: Navigate to profile/tokens page to create an API token
  await page.goto(`${url}/dashboard/settings/profile`, { waitUntil: "networkidle2" });
 
  // Try to find and click on API tokens tab/section
  const tokensTab = await page.$('button:has-text("API"), a:has-text("API"), [data-testid="api-tokens"]');
  if (tokensTab) {
    await tokensTab.click();
    await page.waitForTimeout(1000);
  }

  // Look for "Create Token" or "Generate" button
  const createTokenBtn = await page.$(
    'button:has-text("Create"), button:has-text("Generate"), button:has-text("Add"), button:has-text("Créer")'
  );
  if (createTokenBtn) {
    await createTokenBtn.click();
    await page.waitForTimeout(1000);

    // Fill token name if there's an input
    const tokenNameInput = await page.$('input[name="name"], input[placeholder*="name"], input[placeholder*="token"]');
    if (tokenNameInput) {
      await tokenNameInput.type("automation-key");
    }

    // Submit/confirm token creation
    const confirmBtn = await page.$(
      'button[type="submit"], button:has-text("Create"), button:has-text("Generate"), button:has-text("Save")'
    );
    if (confirmBtn) {
      await confirmBtn.click();
      await page.waitForTimeout(3000);
    }
  }

  // Step 3: Save the API key to file
  if (capturedApiKey) {
    // Ensure directory exists
    const dir = path.dirname(apiKeyFile);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    fs.writeFileSync(apiKeyFile, capturedApiKey, { mode: 0o600 });
    console.log(`API_KEY_SAVED:${apiKeyFile}`);
  } else {
    console.log("API_KEY_NOT_CAPTURED");
  }

  await browser.close();
})();
