param name string
param tags object = {}
param dataLocation string = 'Europe'
param domainManagement string = 'AzureManaged'
param userEngagementTracking string = 'Disabled'

resource emailservice 'Microsoft.Communication/emailServices@2023-03-31' = {
  name: '${name}-emailservice'
  location: 'global'
  tags: tags
  properties: {
    dataLocation: dataLocation
  }
}

resource emailservicedomain 'Microsoft.Communication/emailServices/domains@2023-03-31' = {
  name: (domainManagement == 'AzureManaged') ? 'AzureManagedDomain' : '${name}-emaildomain'
  location: 'global'
  tags: tags
  parent: emailservice
  properties: {
    domainManagement: domainManagement
    userEngagementTracking: userEngagementTracking
  }
}

resource communicationservice 'Microsoft.Communication/communicationServices@2023-04-01-preview' = {
  name: '${name}-communicationservice'
  location: 'global'
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dataLocation: dataLocation
    linkedDomains: [
      emailservicedomain.id
    ]
  }
}

output EMAIL_SERVICE_ID string = emailservice.id
output EMAIL_SERVICE_NAME string = emailservice.name
output EMAIL_SERVICE_DOMAIN_ID string = emailservicedomain.id
output EMAIL_SERVICE_DOMAIN_NAME string = emailservicedomain.name
output COMMUNICATION_SERVICE_ID string = communicationservice.id
output COMMUNICATION_SERVICE_NAME string = communicationservice.name
