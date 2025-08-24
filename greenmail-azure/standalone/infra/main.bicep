targetScope = 'resourceGroup'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@description('Primary location for all resources')
param location string

@description('Name of the resource group to deploy resources into')
param resourceGroupName string

param prefix string = 'dev'
param greenmailAppExists bool = false

param tagValues object = {
  'azd-env-name': environmentName
}


var uniqueId = uniqueString(resourceGroup().id)

module avnModule './avn.bicep' = {
  name: 'avn'
  scope: resourceGroup()
  params: {
    uniqueId: uniqueId
    prefix: prefix
    location: location
    tagValues: tagValues
  }
}

module acrModule './acr.bicep' = {
  name: 'acr'
  scope: resourceGroup()
  params: {
    uniqueId: uniqueId
    prefix: prefix
    location: location
    tagValues: tagValues
  }
}

module ace './ace.bicep' = {
  name: 'ace'
  scope: resourceGroup()
  params: {
    uniqueId: uniqueId
    prefix: prefix
    location: location
    infrastructureSubnetId: avnModule.outputs.infrastructureSubnetId
    tagValues: tagValues
  }
}

module aca './aca.bicep' = {
  name: 'aca'
  scope: resourceGroup()
  params: {
    uniqueId: uniqueId
    prefix: prefix
    containerRegistry: acrModule.outputs.acrName
    location: location
    greenmailAppExists: greenmailAppExists
    containerAppEnvId: ace.outputs.containerAppEnvId
    tagValues: tagValues
  }
}

// These outputs are copied by azd to .azure/<env name>/.env file
// post provision script will use these values, too
output AZURE_RESOURCE_GROUP string = resourceGroupName
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = acrModule.outputs.acrEndpoint
