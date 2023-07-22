targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

// Optional parameters to override the default azd resource naming conventions. Update the main.parameters.json file to provide values. e.g.,:
// "resourceGroupName": {
//      "value": "myGroupName"
// }
param functionName string = ''
param applicationInsightsDashboardName string = ''
param applicationInsightsName string = ''
param appServicePlanName string = ''
param keyVaultName string = ''
param logAnalyticsName string = ''
param resourceGroupName string = ''
param storageAccountName string = ''
param dataLocation string = 'Europe'
param commSecretName string = 'COMMSERVC-CONNECTION-STRING'

@description('Id of the user or app to assign application roles')
param principalId string = ''

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// Create an App Service Plan to group applications under the same payment plan and SKU
module appServicePlan './core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  scope: rg
  params: {
    name: !empty(appServicePlanName) ? appServicePlanName : '${abbrs.webServerFarms}${resourceToken}'
    location: location
    tags: tags
    sku: {
      name: 'Y1'
      tier: 'Dynamic'
    }
  }
}

// Backing storage for Azure Functions
module storage './core/storage/storage-account.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    name: !empty(storageAccountName) ? storageAccountName : '${abbrs.storageStorageAccounts}${resourceToken}'
    location: location
    tags: tags
  }
}

// Store secrets in a keyvault
module keyVault './core/security/keyvault.bicep' = {
  name: 'keyvault'
  scope: rg
  params: {
    name: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${resourceToken}'
    location: location
    tags: tags
    principalId: principalId
  }
}

// Give the API access to KeyVault
module apiKeyVaultAccess './core/security/keyvault-access.bicep' = {
  name: 'api-keyvault-access'
  scope: rg
  params: {
    keyVaultName: keyVault.outputs.name
    principalId: function.outputs.FUNCTION_IDENTITY_PRINCIPAL_ID
  }
}

// The function app
module function './api/function.bicep' = {
  name: 'function'
  scope: rg
  params: {
    name: !empty(functionName) ? functionName : '${abbrs.webSitesFunctions}api-${resourceToken}'
    location: location
    tags: tags
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    appServicePlanId: appServicePlan.outputs.id
    keyVaultName: keyVault.outputs.name
    storageAccountName: storage.outputs.name
    appSettings: {
      //Needed for preview of new programming model of node
      AzureWebJobsFeatureFlags: 'EnableWorkerIndexing'
      COMM_CONNECTION_STRING: '@Microsoft.KeyVault(SecretUri=${keyVault.outputs.endpoint}secrets/${commSecretName})'
    }
  }
}

// Monitor application with Azure Monitor
module monitoring './core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    tags: tags
    logAnalyticsName: !empty(logAnalyticsName) ? logAnalyticsName : '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${resourceToken}'
    applicationInsightsDashboardName: !empty(applicationInsightsDashboardName) ? applicationInsightsDashboardName : '${abbrs.portalDashboards}${resourceToken}'
  }
}

// Setup communication services for sending emails
module emailservice './corelocal/communication/email-service.bicep' = {
  name: 'azd-communication-email'
  scope: rg
  params: {
    name: 'email-service'
    tags: tags
    dataLocation: dataLocation
  }
}

//Store Secret Communication Service Secret in KeyVault
module emailserviceKeyVaultSecret './api/communicationServiceConnectionSecret.bicep' = {
  name: 'emailservice-keyvault-secret'
  scope: rg
  params: {
    name: commSecretName
    keyVaultName: keyVault.outputs.name
    communicationServiceName: emailservice.outputs.COMMUNICATION_SERVICE_NAME
  }
}

output AZD_FUNC_BLOB_KEY_VAULT_ENDPOINT string = keyVault.outputs.endpoint
output AZD_FUNC_BLOB_APPINSIGHTS_CONNECTION_STRING string = monitoring.outputs.applicationInsightsConnectionString
output AZD_FUNC_BLOB_FUNCTION_URL string = function.outputs.FUNCTION_URI
output AZD_FUNC_BLOB_AZURE_LOCATION string = location
output AZD_FUNC_BLOB_AZURE_TENANT_ID string = tenant().tenantId
