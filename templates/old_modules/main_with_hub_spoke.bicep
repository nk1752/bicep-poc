
@minLength(2)
@description('The location to use for the deployment. defaults to Resource Groups location.')
param location string = resourceGroup().location

@minLength(3)
@maxLength(20)
@description('Used to name all resources')
param resourceName string


//------------------------------------------------------ Create custom vnet
@minLength(9)
@maxLength(18)
@description('The address range for the custom vnet')
param vnetAddressPrefix string = '10.240.0.0/16'

@minLength(9)
@maxLength(18)
@description('The address range for AKS in your custom vnet')
param vnetAksSubnetAddressPrefix string = '10.240.0.0/22'

@minLength(9)
@maxLength(18)
@description('The address range for the App Gateway in your custom vnet')
param vnetAppGatewaySubnetAddressPrefix string = '10.240.5.0/24'

@minLength(9)
@maxLength(18)
@description('The address range for the ACR in your custom vnet')
param acrAgentPoolSubnetAddressPrefix string = '10.240.4.64/26'

@minLength(9)
@maxLength(18)
@description('The address range for Azure Bastion in your custom vnet')
param bastionSubnetAddressPrefix string = '10.240.4.128/26'

@minLength(9)
@maxLength(18)
@description('The address range for private link in your custom vnet')
param privateLinkSubnetAddressPrefix string = '10.240.4.192/26'

@minLength(9)
@maxLength(18)
@description('The address range for Azure Firewall in your custom vnet')
param vnetFirewallSubnetAddressPrefix string = '10.240.50.0/24'

@minLength(9)
@maxLength(18)
@description('The address range for Azure Firewall Management in your custom vnet')
param vnetFirewallManagementSubnetAddressPrefix string = '10.240.51.0/26'

var custom_vnet = true
module network 'modules/network.bicep' = if (custom_vnet) {
  name: take('${deployment().name}-vnet', 64)
  
  params: {
    location: location
    resourceName: resourceName

    //networkPluginIsKubenet: false

    vnetAddressPrefix: vnetAddressPrefix
    vnetAksSubnetAddressPrefix: vnetAksSubnetAddressPrefix
    vnetPodAddressPrefix: cniDyanmicAddressPrefix ? podCidr: ''

    
    
  }



}
