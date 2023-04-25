targetScope = 'resourceGroup'

param location string = resourceGroup().location

module vnetHubModule 'vnet-hub.bicep' = {
  name: 'vnet-hub'
  params: {
    location: location
  }
  
}





