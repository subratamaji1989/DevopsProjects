<h1 align="center">🛡️ Azure API Deployment and Security Configuration Guide (Beginner-friendly) 🛡️</h1>

**Goal:** Deploy a sample API to Azure App Service, protect it with **Microsoft Entra ID** using App Registrations and App Service Authentication (Easy Auth), front it with Azure API Management (APIM), and use APIM's Managed Identity to acquire backend tokens. The architecture enforces both client-side and backend-side token validation so only authorized clients can reach your API.

> **Note:** This entire guide can be run as a single script. It is designed to be idempotent, meaning you can run it multiple times without causing errors.

---


## Overview (What you'll build)

-   Resource Group, App Service Plan, App Service (Python Flask app).
-   An App Registration in **Microsoft Entra ID** representing the API, which becomes the token audience (`aud`).
-   Enable App Service Easy Auth to accept only tokens issued for that audience.
-   Deploy the Flask app to App Service.
-   Create an APIM instance, enable its system-assigned Managed Identity, and import the App Service as an API.
-   Apply an APIM policy that:
    -   Validates the incoming client JWT (client protection).
    -   Uses APIM Managed Identity to get a new token for the API audience and sends it to the backend (backend protection).

## Prerequisites

-   Azure CLI installed and logged in (`az login`).
-   `jq` (optional but recommended for parsing JSON).
-   `openssl` (for generating a unique prefix).
-   Basic knowledge of shell/Bash.
-   Your Flask app files: `app.py` and `requirements.txt`.

## Important variables

This script uses `openssl` to generate a unique prefix for resources to avoid naming conflicts.

```bash
RG_NAME="rg-apim-security-demo"
LOCATION="southindia"
PREFIX="ovr-apim-demo" # Must be globally unique and lowercase
APIM_NAME="${PREFIX}-apim"
APP_PLAN_NAME="${PREFIX}-app-plan"
APP_SERVICE_NAME="${PREFIX}-app-service"
```

---

## Step 1 — Deploy core Azure infrastructure (App Service & Plan)

**What this does:** Creates a resource group, App Service Plan, and App Service (Python runtime).

```bash
echo "Step 1: Deploying core infrastructure..."

# Variables (edit above or here)
az group create --name $RG_NAME --location $LOCATION

# Create App Service Plan (F1 is free tier suitable for tests)
az appservice plan create \
  --name $APP_PLAN_NAME \
  --resource-group $RG_NAME \
  --location $LOCATION \
  --sku F1

# Create App Service (Python runtime)
az webapp create \
  --name $APP_SERVICE_NAME \
  --resource-group $RG_NAME \
  --plan $APP_PLAN_NAME \
  --runtime "PYTHON|3.11"
```

### Validation:

```bash
az webapp show --name $APP_SERVICE_NAME --resource-group $RG_NAME --query defaultHostName -o tsv
```

Open the returned URL in a browser (it may show an empty site until you deploy code).

---

## Step 2 — Create Microsoft Entra ID App Registration (API / Resource Server)

**Why:** This App Registration becomes the audience (`aud`) for tokens. Clients will request tokens for this API identity.

```bash
echo "Step 2: Creating Microsoft Entra ID App Registration..."

APP_REG_NAME="${PREFIX}-api-app"

# Create app registration; returns appId (client ID) and objectId
APP_REG_OUTPUT=$(az ad app create --display-name $APP_REG_NAME --query "{appId: appId, objectId: id}" --output json)
APP_CLIENT_ID=$(echo $APP_REG_OUTPUT | jq -r '.appId')

# Define Application ID URI (audience)
APP_ID_URI="api://${APP_CLIENT_ID}"

# Update the app to set identifier URI
az ad app update --id $APP_CLIENT_ID --identifier-uris $APP_ID_URI

# Tenant ID
TENANT_ID=$(az account show --query tenantId --output tsv)

echo "--- SECURITY DETAILS (SAVE THESE) ---"
echo "Tenant ID: ${TENANT_ID}"
echo "API Client ID (aud): ${APP_CLIENT_ID}"
echo "Application ID URI (Resource/Scope): ${APP_ID_URI}"
echo "-------------------------------------"
```

### Notes for beginners:

-   `APP_CLIENT_ID` is the App Registration's Application (client) ID.
-   `APP_ID_URI` commonly uses the pattern `api://{clientId}` or `api://your-domain/your-api`.
-   Keep these values — you'll use them in Easy Auth, APIM, and policies.

---

## Step 3 — Secure App Service using Easy Auth (App Service Authentication)

**Purpose:** Configure App Service's built-in authentication (Easy Auth) so it only accepts requests with tokens intended for the API (`APP_ID_URI`).

```bash
echo "Step 3: Securing the App Service with Easy Auth..."

az webapp auth update \
  --resource-group $RG_NAME \
  --name $APP_SERVICE_NAME \
  --enabled true \
  --action UnauthenticatedClient:Return401 \
  --aad-allowed-token-audiences "${APP_ID_URI}" \
  --aad-client-id "${APP_CLIENT_ID}" \
  --aad-tenant-id "${TENANT_ID}"
```

echo "✅ App Service is protected — direct calls without a valid token will return 401."

### Validation (quick test):

Curl the App Service URL without token; expect 401:

```bash
APP_URL="https://$(az webapp show --name $APP_SERVICE_NAME --resource-group $RG_NAME --query 'defaultHostName' -o tsv)"
curl -i $APP_URL
```

---

## Step 4 — Deploy your Flask app to App Service

Place `app.py` and `requirements.txt` in a folder, then run:

```bash
echo "Step 4: Deploying application code..."

# Package files
zip deployment.zip app.py requirements.txt

# Deploy
az webapp deployment source config-zip \
  --resource-group $RG_NAME \
  --name $APP_SERVICE_NAME \
  --src deployment.zip

# Configure startup with Gunicorn for Flask
az webapp config set \
  --resource-group $RG_NAME \
  --name $APP_SERVICE_NAME \
  --startup-file "gunicorn --bind 0.0.0.0 --timeout 60 --workers 2 app:app"
```

### Validation:

After deployment, open `https://<your-app>.azurewebsites.net/` — App Service will now require a valid token, so a browser may show 401 unless a token is provided. (This is expected — APIM will call with a valid token later.)

---

## Step 5 — Deploy APIM and import the App Service as an API

**What you'll do:** Create APIM instance, enable its Managed Identity, and import the App Service as an API.

```bash
echo "Step 5: Deploying APIM and importing the API..."

# 1) Create APIM (Developer SKU for testing)
az apim create \
  --name $APIM_NAME \
  --resource-group $RG_NAME \
  --publisher-name "Contoso" \
  --publisher-email "admin@contoso.com" \
  --sku-name Developer \
  --location $LOCATION

# 2) Assign system-managed identity to APIM
APIM_MI_ID=$(az apim identity assign --name $APIM_NAME --resource-group $RG_NAME --query 'systemAssignedIdentity' -o tsv)
echo "APIM Managed Identity ID: ${APIM_MI_ID}"

# 3) Import the App Service as an API in APIM
APP_SERVICE_URL="https://$(az webapp show --name $APP_SERVICE_NAME --resource-group $RG_NAME --query 'defaultHostName' -o tsv)"
az apim api create \
  --service-name $APIM_NAME \
  --resource-group $RG_NAME \
  --api-id "sample-status-api" \
  --display-name "Sample Status API" \
  --path "status" \
  --protocols "https" \
  --service-url "$APP_SERVICE_URL"

# 4) Add a basic GET operation
az apim api operation create \
  --service-name $APIM_NAME \
  --resource-group $RG_NAME \
  --api-id "sample-status-api" \
  --url-template "/" \
  --method "GET" \
  --display-name "Get Status"
```

### Notes:

-   APIM's system-assigned Managed Identity will be used to request tokens to call the App Service.
-   After creation, you can also use the Azure Portal > APIM > APIs > your API to view or modify operations.

---

## Step 6 — Grant APIM Managed Identity permission to request tokens (if needed)

**Important:** For APIM Managed Identity to request an access token for `api://{clientId}`, it generally doesn't need additional app role consent if the API accepts any token with that audience. However, if your API requires specific app roles or scopes you defined on the App Registration, you must grant those to the Managed Identity:

-   In the App Registration (`$APP_REG_NAME`) expose an API scope or app role if required.
-   In Entra ID, grant the APIM Managed Identity permission to access the API (Enterprise Applications > your APIM MI as service principal > Assign the required API permissions or add consent).
-   If you used `api://{clientId}` with no scopes, APIM can request a client-credential token using its Managed Identity by calling the Azure AD token endpoint with `resource/audience = APP_ID_URI`.

---

## Step 7 — Create and apply the APIM policy (inbound + backend protection)

**Goal:** Ensure APIM:

-   Validates incoming client tokens (`<validate-jwt>`).
-   Uses `authentication-managed-identity` to get a managed identity token for the backend audience (`APP_ID_URI`).

**Important:** Replace `{{TENANT_ID}}` and `{{APP_ID_URI}}` with actual values from Step 2 before saving the file.
The script handles this automatically.

```xml
<!-- policy.xml -->
<policies>
    <inbound>
        <base />
        <validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Unauthorized. Access token is missing or invalid.">
            <openid-config url="https://login.microsoftonline.com/{{TENANT_ID}}/v2.0/.well-known/openid-configuration" />
            <audiences>
                <audience>{{APP_ID_URI}}</audience>
            </audiences>
        </validate-jwt>

        <authentication-managed-identity resource="{{APP_ID_URI}}" output-token-variable-name="msi-access-token" ignore-error="false" />

        <set-header name="Authorization" exists-action="override">
            <value>@("Bearer " + (string)context.Variables["msi-access-token"])</value>
        </set-header>
    </inbound>
    <backend>
        <base />
    </backend>
</policies>
```

### Apply via CLI:

Replace `{{TENANT_ID}}` and `{{APP_ID_URI}}` in `policy.xml`.

Run:

```bash
echo "Step 6: Applying security policy to APIM..."
az apim api policy import \
  --service-name $APIM_NAME \
  --resource-group $RG_NAME \
  --api-id "sample-status-api" \
  --path "policy.xml"
```

### Notes:

-   `<validate-jwt>` verifies the incoming token is from your tenant and intended for your API (`aud` matches).
-   `<authentication-managed-identity>` uses APIM’s Managed Identity to request an access token for `APP_ID_URI`. APIM then sends that token to the App Service.
-   Easy Auth on App Service checks that token and accepts the request if valid.

---

## Step 8 — End-to-end flow (summary)

-   Client authenticates with **Microsoft Entra ID** and requests a token for `APP_ID_URI` (the API).
-   Client sends request to APIM with `Authorization: Bearer <client-token>`.
-   APIM inbound policy:
    -   Validates `<client-token>` using `validate-jwt`.
    -   Calls `authentication-managed-identity` to fetch a new token for the backend (audience = `APP_ID_URI`).
    -   Replaces the `Authorization` header with `Bearer <msi-token>`.
-   APIM calls App Service with the Managed Identity token.
-   App Service Easy Auth validates the token is for `APP_ID_URI` and allows the request through to the app code.
-   Response flows back to client via APIM.

---

## Troubleshooting & validation tips

-   **401 from App Service when calling directly:** expected if you call without a valid token. App Service is locked to tokens for `APP_ID_URI`.
-   **APIM returns 401 on inbound:** Check the client token audience and issuer. The token must be for `APP_ID_URI` and from your tenant.
-   **APIM fails to acquire MSI token:** verify the APIM Managed Identity is enabled and the `authentication-managed-identity` resource value matches `APP_ID_URI`. Also check AAD settings and that APIM has network access to Azure AD.
-   **Token audience mismatch errors:** Confirm the `aud` of tokens using `jwt.ms` or `jwt.io`. The token's `aud` must equal the `APP_ID_URI`.
-   **APIM policy issues:** Use APIM trace (Azure Portal > APIM > APIs > Select API > Trace) to inspect policies and headers.
