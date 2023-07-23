param name string
param tags object = {}
param dataLocation string = 'Europe'
param domainManagement string = 'AzureManaged'
param userEngagementTracking string = 'Disabled'
//param senderUserName string = 'DoNotReply'
//param senderDisplayName string = 'DoNotReply'

// Create the email service
resource emailService 'Microsoft.Communication/emailServices@2023-03-31' = {
  name: '${name}-emailservice'
  location: 'global'
  tags: tags
  properties: {
    dataLocation: dataLocation
  }
}

// Attach an Azure managed domain
resource emailServiceDomain 'Microsoft.Communication/emailServices/domains@2023-03-31' = {
  name: 'AzureManagedDomain'
  location: 'global'
  tags: tags
  parent: emailService
  properties: {
    domainManagement: domainManagement
    userEngagementTracking: userEngagementTracking
  }
}

// Add a sender username to the domain (optional)
/*
resource senderUserNameAzureDomain 'Microsoft.Communication/emailServices/domains/senderUsernames@2023-03-31' = {
  parent: emailServiceDomain
  name: 'donotreply'
  properties: {
    username: senderUserName
    displayName: senderDisplayName
  }
}
*/

// Attach the email service to the communication service 
resource communicationService 'Microsoft.Communication/communicationServices@2023-03-31' = {
  name: '${name}-communicationservice'
  location: 'global'
  tags: tags
  properties: {
    dataLocation: dataLocation
    linkedDomains: [
      emailServiceDomain.id
    ]
  }
}



output EMAIL_SERVICE_ID string = emailService.id
output EMAIL_SERVICE_NAME string = emailService.name
output EMAIL_SERVICE_DOMAIN_ID string = emailServiceDomain.id
output EMAIL_SERVICE_DOMAIN_NAME string = emailServiceDomain.name
output EMAIL_SERVICE_DOMAIN_SENDER_DOMAIN string = emailServiceDomain.properties.mailFromSenderDomain
output COMMUNICATION_SERVICE_ID string = communicationService.id
output COMMUNICATION_SERVICE_NAME string = communicationService.name
