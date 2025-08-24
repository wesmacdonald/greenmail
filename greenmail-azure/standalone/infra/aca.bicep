param uniqueId string
param prefix string
param containerRegistry string
param location string
param greenmailAppExists bool
param containerAppEnvId string
param tagValues object
param emptyContainerImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
param userAssignedIdentityName string = '${prefix}-greenmail-identity-${uniqueId}'

@description('Number of CPU cores the container can use. Can be with a maximum of two decimals.')
@allowed([
  '0.25'
  '0.5'
  '0.75'
  '1'
  '1.25'
  '1.5'
  '1.75'
  '2'
])
param cpuCore string = '1'

@description('Amount of memory (in gigabytes, GiB) allocated to the container up to 4GiB. Can be with a maximum of two decimals. Ratio with CPU cores must be equal to 2.')
@allowed([
  '0.5'
  '1'
  '1.5'
  '2'
  '3'
  '3.5'
  '4'
])
param memorySize string = '2'

@description('Minimum number of replicas that will be deployed')
@minValue(0)
@maxValue(25)
param minReplicas int = 1

@description('Maximum number of replicas that will be deployed')
@minValue(0)
@maxValue(25)
param maxReplicas int = 1

module fetchLatestImageUI './modules/fetch-container-image.bicep' = {
  name: 'ui-app-image'
  params: {
    exists: greenmailAppExists
    name: '${prefix}-greenmail-${uniqueId}'
  }
}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: userAssignedIdentityName
  location: location
}

resource acr 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' existing = {
  name: containerRegistry
}

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(userAssignedIdentity.id, containerRegistry, 'acrpull')
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource uiContainerApp 'Microsoft.App/containerApps@2025-02-02-preview' = {
  name: '${prefix}-greenmail-${uniqueId}'
  location: location
tags: {
    'azd-service-name': 'api'
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppEnvId
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
        exposedPort: 8080
        transport: 'Tcp'
        traffic: [
          {
            weight: 100
            latestRevision: true
          }
        ]
        allowInsecure: false
        stickySessions: {
          affinity: 'none'
        }
        additionalPortMappings: [
          {
            external: true
            targetPort: 3025
            exposedPort: 3025
          }
          {
            external: true
            targetPort: 3143
            exposedPort: 3143
          }
          {
            external: true
            targetPort: 3110
            exposedPort: 3110
          }
          {
            external: true
            targetPort: 3465
            exposedPort: 3465
          }
          {
            external: true
            targetPort: 3993
            exposedPort: 3993
          }
        ]
      }
      registries: [
        {
          server: '${containerRegistry}.azurecr.io'
          identity: userAssignedIdentity.id
        }
      ]
      runtime: {
        java: {
          enableMetrics: true
          javaAgent: {
            enabled: true
            logging: {
              loggerSettings: [
                {
                  level: 'INFO'
                  logger: 'org.apache.logging.log4j'
                }
              ]
            }
          }
        }
      }
    }
    template: {
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
      }
      containers: [
        {
          name: 'greenmail'
          image: greenmailAppExists ? fetchLatestImageUI.outputs.containers[0].image : emptyContainerImage
          resources: {
            cpu: json(cpuCore)
            memory: '${memorySize}Gi'
          }
        }
      ]
    }
  }
}

output containerAppFQDN string = uiContainerApp.properties.configuration.ingress.fqdn
