// vnet
@description('Location for all resources.')
param location string

@description('Address prefix for the virtual network.')
param vnetAddressPrefix string

@description('Address prefix for the AKS subnet.')
param aksSubnetPrefix string

@description('Address prefix for the App Gateway subnet.')
param appgw4K8sSubnetPrefix string

resource vNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: 'aks-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'aks-subnet'
        properties: {
          addressPrefix: aksSubnetPrefix
        }
      }
      {
        name: 'appgw4K8s-subnet'
        properties: {
          addressPrefix: appgw4K8sSubnetPrefix
        }
      }
    ]
  }
}
output vnetId string = vNetwork.id
output vnetName string = vNetwork.name
output aksSubnetID string = vNetwork.properties.subnets[0].id
output appgw4K8sSubnetID string = vNetwork.properties.subnets[1].id
