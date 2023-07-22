param name string
param tags object = {}

param keyVaultName string
param communicationServiceName string


resource communicationServiceExisting 'Microsoft.Communication/communicationServices@2023-03-31' existing = {
  name: communicationServiceName
}

module communicationServiceSecret '../core/security/keyvault-secret.bicep' = {
  name: name
  params: {
    name: name
    tags: tags
    keyVaultName: keyVaultName
    secretValue: communicationServiceExisting.listKeys().primaryConnectionString
  }
}
