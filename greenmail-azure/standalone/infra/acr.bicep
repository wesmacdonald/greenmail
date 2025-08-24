param uniqueId string
param prefix string
param tagValues object
param location string = resourceGroup().location
param acrName string = '${prefix}acr${uniqueId}'

resource acr 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: acrName
  location: location
  tags: tagValues
  sku: {
    name: 'Basic' // Choose between Basic, Standard, and Premium based on your needs
  }
  properties: {
    adminUserEnabled: false
  }
}

output acrName string = acrName
output acrEndpoint string = acr.properties.loginServer
