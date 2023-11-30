
param location string = resourceGroup().location

@description('Subscription tenant id.')
var tenantID = '72f988bf-86f1-41af-91ab-2d7cd011db47'

// aks cluster name
var clusterName = 'aks-dev'

// The DNS prefix specified when creating the managed cluster.
var dnsPrefix = 'aks-dev'

var vnetAddressPrefix = '10.167.0.0/16'
var aksSubnetPrefix = '10.167.0.0/24'
var appgw4K8sSubnetPrefix = '10.167.1.0/24'



// call network module to deploy VNet for aks cluster
module network './modules/vnet-aks-dev.bicep' = {
  name: 'aks-vnet-dev'
  params: {
    location: location
    vnetAddressPrefix: vnetAddressPrefix
    aksSubnetPrefix: aksSubnetPrefix
    appgw4K8sSubnetPrefix: appgw4K8sSubnetPrefix
  }
  
}

// call aks module to deploy aks cluster
module aks './modules/aks-dev.bicep' = {
  name: 'aks-dev'
  dependsOn: [
    network
  ]
  params: {
    location: location
    tenantID: tenantID
    clusterName: clusterName
    dnsPrefix: dnsPrefix
    aksSubnetID: network.outputs.aksSubnetID
  }   
}

