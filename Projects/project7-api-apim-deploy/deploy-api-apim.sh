#!/bin/bash

# This script automates the deployment of a secure API on Azure,
# fronted by API Management (APIM), as detailed in the README.md.
# It handles infrastructure creation, security configuration, and code deployment.

set -e # Exit immediately if a command exits with a non-zero status.

echo "🚀 Starting Azure API and APIM deployment..."

# --- Step 0: Define variables ---
echo "Step 0: Defining initial variables..."
RG_NAME="rg-apim-security-demo"
LOCATION="southindia"
PREFIX="ovr-apim-demo" # Must be globally unique and lowercase

APIM_NAME="${PREFIX}-apim"
APP_PLAN_NAME="${PREFIX}-app-plan"
APP_SERVICE_NAME="${PREFIX}-app-service"

echo "Resource Group: $RG_NAME"
echo "App Plan Name: $APP_PLAN_NAME"
echo "App Service Name: $APP_SERVICE_NAME"
echo "APIM Name: $APIM_NAME"

# --- Step 1: Deploy core Azure infrastructure (App Service & Plan) ---
echo "Step 1: Deploying core infrastructure..."
az group create --name $RG_NAME --location $LOCATION

az appservice plan create \
  --name $APP_PLAN_NAME \
  --resource-group $RG_NAME \
  --location $LOCATION \
  --sku F1 \

az webapp create \
  --name $APP_SERVICE_NAME \
  --resource-group $RG_NAME \
  --plan $APP_PLAN_NAME \
  --runtime "PYTHON|3.11"

echo "✅ Core infrastructure deployed."

# --- Step 2: Create Microsoft Entra ID App Registration (API / Resource Server) ---
echo "Step 2: Creating Microsoft Entra ID App Registration..."
APP_REG_NAME="${PREFIX}-api-app"

APP_REG_OUTPUT=$(az ad app create --display-name $APP_REG_NAME --query "{appId: appId, objectId: id}" --output json)
APP_CLIENT_ID=$(echo $APP_REG_OUTPUT | jq -r '.appId')
APP_ID_URI="api://${APP_CLIENT_ID}"

az ad app update --id $APP_CLIENT_ID --identifier-uris $APP_ID_URI

TENANT_ID=$(az account show --query tenantId --output tsv)

echo "--- SECURITY DETAILS (SAVE THESE) ---"
echo "Tenant ID: ${TENANT_ID}"
echo "API Client ID (aud): ${APP_CLIENT_ID}"
echo "Application ID URI (Resource/Scope): ${APP_ID_URI}"
echo "-------------------------------------"

# --- Step 3: Secure App Service using Easy Auth ---
echo "Step 3: Securing the App Service with Easy Auth..."

# Define the v2 auth settings in a JSON object.
AUTH_SETTINGS_JSON=$(cat <<EOF
{
    "platform": { "enabled": true },
    "globalValidation": {
        "unauthenticatedClientAction": "Return401",
        "redirectToProvider": "azureactivedirectory"
    },
    "identityProviders": {
        "azureActiveDirectory": {
            "enabled": true,
            "registration": {
                "openIdIssuer": "https://sts.windows.net/${TENANT_ID}/v2.0",
                "clientId": "${APP_CLIENT_ID}"
            },
            "validation": {
                "allowedAudiences": ["${APP_ID_URI}"]
            }
        }
    }
}
EOF
)

# Use 'az resource update' to set the entire siteAuthSettingsV2 object at once.
# This creates the object if it doesn't exist, avoiding the "Couldn't find 'siteAuthSettingsV2'" error.
az resource update \
  --resource-group $RG_NAME \
  --name $APP_SERVICE_NAME \
  --resource-type "Microsoft.Web/sites" \
  --set "properties.siteAuthSettingsV2=${AUTH_SETTINGS_JSON}"

echo "✅ App Service is protected. Direct calls without a valid token will now return 401."

# --- Step 4: Deploy your Flask app to App Service ---
echo "Step 4: Deploying application code..."
# zip app.zip app.py requirements.txt api-data.yaml


az webapp deployment source config-zip \
  --resource-group $RG_NAME \
  --name $APP_SERVICE_NAME \
  --src app.zip

az webapp config set \
  --resource-group $RG_NAME \
  --name $APP_SERVICE_NAME \
  --startup-file "gunicorn --bind 0.0.0.0 --timeout 60 --workers 2 app:app"

echo "✅ Application code deployed."

# --- Step 5: Deploy APIM and import the App Service as an API ---
echo "Step 5: Deploying APIM and importing the API..."
az apim create \
  --name $APIM_NAME \
  --resource-group $RG_NAME \
  --publisher-name "Contoso" \
  --publisher-email "admin@contoso.com" \
  --sku-name Developer \
  --location $LOCATION

APIM_MI_ID=$(az apim identity assign --name $APIM_NAME --resource-group $RG_NAME --query 'systemAssignedIdentity' -o tsv)
echo "APIM Managed Identity ID: ${APIM_MI_ID}"

APP_SERVICE_URL="https://$(az webapp show --name $APP_SERVICE_NAME --resource-group $RG_NAME --query 'defaultHostName' -o tsv)"
az apim api create \
  --service-name $APIM_NAME \
  --resource-group $RG_NAME \
  --api-id "sample-status-api" \
  --display-name "Sample Status API" \
  --path "" \
  --protocols "https" \
  --service-url "$APP_SERVICE_URL"

az apim api operation create \
  --service-name $APIM_NAME \
  --resource-group $RG_NAME \
  --api-id "sample-status-api" \
  --url-template "/" \
  --operation-id "get-api-index" \
  --method "GET" \
  --display-name "Get API Index"

echo "✅ APIM API created. Adding operations based on app.py..."
# Add all other API operations from app.py
az apim api operation create \
  --service-name $APIM_NAME --resource-group $RG_NAME --api-id "sample-status-api" \
  --url-template "/api/health" --method "GET" --display-name "Get Health" \
  --operation-id "get-health"

az apim api operation create \
  --service-name $APIM_NAME --resource-group $RG_NAME --api-id "sample-status-api" \
  --url-template "/api/echo" --method "GET" --display-name "Get Echo" \
  --operation-id "get-echo"

az apim api operation create \
  --service-name $APIM_NAME --resource-group $RG_NAME --api-id "sample-status-api" \
  --url-template "/api/echo" --method "POST" --display-name "Post Echo" \
  --operation-id "post-echo"

az apim api operation create \
  --service-name $APIM_NAME --resource-group $RG_NAME --api-id "sample-status-api" \
  --url-template "/api/products" --method "GET" --display-name "Get Products" \
  --operation-id "get-products"

echo "✅ All API operations have been created."

# --- Step 6: Create and apply the APIM policy ---
echo "Step 6: Creating and applying security policy to APIM..."

# Note: The policy below applies to the entire API. If you need different
# security for different operations, you would apply policies at the operation level.
# For this guide, a single API-level policy is sufficient.

# Create policy.xml from the template in the README
POLICY_FILE="policy.xml"

# Create the policy file locally instead of downloading it to avoid "Not Found" errors.
cat <<EOF > $POLICY_FILE
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
EOF

# Replace placeholders with actual values
sed -i.bak "s/{{TENANT_ID}}/$TENANT_ID/g" $POLICY_FILE
sed -i.bak "s#{{APP_ID_URI}}#$APP_ID_URI#g" $POLICY_FILE

# Use 'az resource update' to apply the policy. This is a more robust method that avoids potential issues with older CLI versions or missing subcommands.
az resource update \
  --resource-group $RG_NAME \
  --name "${APIM_NAME}/sample-status-api/policy" \
  --resource-type "Microsoft.ApiManagement/service/apis/policies" \
  --set "properties.value=$(cat $POLICY_FILE)" \
  --set "properties.format=xml"

echo "✅ APIM policy applied."

# --- Cleanup ---
echo "Cleaning up temporary files..."
# rm deployment.zip
rm $POLICY_FILE
rm ${POLICY_FILE}.bak

echo "🎉 Deployment complete!"
APIM_GW_URL=$(az apim show --name $APIM_NAME --resource-group $RG_NAME --query "gatewayUrl" -o tsv)
echo "Your API is available at: ${APIM_GW_URL}"