targetScope = 'resourceGroup'
param location string

var addressPrefixesVnetHub = '10.200.0.0/18'
var addressPrefixAzureFireWallSubnet = '10.200.0.0/24'
var addressPrefixAzureBastionSubnet = '10.200.2.0/24'

resource vnetHub 'Microsoft.Network/virtualNetworks@2022-09-01' = {
  name: 'vnet-hub'
  location: location

  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefixesVnetHub 
      ]
    }

    subnets: [
      {
        name: 'AzureFireWallSubnet'
        properties: {
          addressPrefix: addressPrefixAzureFireWallSubnet
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: addressPrefixAzureBastionSubnet
        }
      }
      
    ]
    
  }
  
}

output testoutput string = vnetHub.id
