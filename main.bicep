targetScope = 'resourceGroup'

param location string = resourceGroup().location

module vnetHubModule 'vnet-hub.bicep' = {
  name: '${ deployment().name-hub-1 }'
  params: {
    location: location
  }
  
}





