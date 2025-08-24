param uniqueId string
param prefix string
param location string
param tagValues object

resource containerVirtualNetwork 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: '${prefix}-acvn-${uniqueId}'
  location: location
  tags: tagValues
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    privateEndpointVNetPolicies: 'Disabled'
    subnets: [
      {
        name: '${prefix}-acsn-${uniqueId}'
        properties: {
          addressPrefix: '10.0.0.0/23'
          serviceEndpoints: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

output infrastructureSubnetId string = containerVirtualNetwork.properties.subnets[0].id


