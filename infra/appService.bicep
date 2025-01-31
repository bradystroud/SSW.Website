param projectName string = 'sswwebsite'
param location string = resourceGroup().location
param tags object
param dockerRegistryServerURL string
param appInsightConnectionString string
param keyVaultName string

@allowed([
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1'
  'P2'
  'P3'
  'P1V2'
  'P2V2'
  'P3V2'
  'P1V3'
  'P2V3'
  'P3V3'
])
param skuName string = 'P1V2'

@minValue(1)
param skuCapacity int = 1

param acrName string

@description('The docker image')
param dockerImage string = 'sswwebsite'

var entropy = substring(guid(subscription().subscriptionId, resourceGroup().id), 0, 4)

resource acr 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: acrName
}

resource plan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'plan-${projectName}'
  location: location
  tags: tags
  kind: 'linux'
  sku: {
    name: skuName
    capacity: skuCapacity
  }
  properties: {
    reserved: true //required as this is a linux plan
  }
}

var appSettings = [
  {
    name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
    value: 'false'
  }
  {
    name: 'WEBSITES_PORT'
    value: '3000'
  }
  {
    name: 'DOCKER_REGISTRY_SERVER_URL'
    value: 'https://${dockerRegistryServerURL}'
  }
  {
    name: 'CREATE_LEAD_ENDPOINT'
    value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/Create-Lead-Endpoint-PROD)'
  }
  {
    name: 'GOOGLE_RECAPTCHA_KEY_V2'
    value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/GOOGLE-RECAPTCHA-KEY)'
  }
  {
    name: 'GOOGLE_RECAPTCHA_SITE_KEY'
    value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/Google-Recaptcha-Site-KEY)'
  }
  {
    name: 'NEXT_PUBLIC_APP_INSIGHT_CONNECTION_STRING'
    value: appInsightConnectionString
  }
  {
    name: 'NEWSLETTERS_ENDPOINT'
    value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/Newsletters-Endpoint-PROD)'
  }
]

resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: 'app-${projectName}-${entropy}'
  location: location
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  tags: union(tags, {
    'hidden-related:${plan.id}': 'empty'
  })
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      appSettings: appSettings
      acrUseManagedIdentityCreds: true
      alwaysOn: true
      http20Enabled: true
      minTlsVersion: '1.2'
      linuxFxVersion: 'DOCKER|${acr.properties.loginServer}/${dockerImage}:production'
    }
  }
}

// Add AcrPull role so that the app service can pull images using managed identity

// This is the ACR Pull Role Definition Id: https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#acrpull
var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource appServiceAcrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: acr
  name: guid(acr.id, appService.id, acrPullRoleDefinitionId)
  properties: {
    principalId: appService.identity.principalId
    roleDefinitionId: acrPullRoleDefinitionId
    principalType: 'ServicePrincipal'
  }
}

output appServiceHostName string = appService.properties.defaultHostName
output AppPrincipalId string = appService.identity.principalId
