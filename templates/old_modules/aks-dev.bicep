@description('The name of the Managed Cluster resource.')
param clusterName string = 'bicep-aks-cluster-2'

@description('The DNS prefix specified when creating the managed cluster.')
param dnsPrefix string = clusterName

@description('Subscription tenant id.')
param tenantID string = '7cb752a7-6dfd-429e-adc9-129f0ea3fcec'


@description('aks subnet id.')
param aksSubnetId_1 string = '/subscriptions/df2f960a-8e92-40ec-a2b8-0a2923d3c074/resourceGroups/MC_bicep_rg/providers/Microsoft.Network/virtualNetworks/vnet-aks-4250/subnets/aks-subnet-2'

@description('The location of the Managed Cluster resource.')
param location string = resourceGroup().location


@description('Disk size (in GB) to provision for each of the agent pool nodes. This value ranges from 0 to 1023. Specifying 0 will apply the default disk size for that agentVMSize.')
@minValue(0)
@maxValue(1023)
param osDiskSizeGB int = 0

@description('The number of nodes for the cluster.')
@minValue(1)
@maxValue(5)
param agentCount int = 2

@description('The size of the Virtual Machine.')
param agentVMSize string = 'standard_d2s_v3'


resource aks 'Microsoft.ContainerService/managedClusters@2023-07-01' = {
  name: clusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    // If you want to use a specific version of Kubernetes, specify that here
    kubernetesVersion: '1.26.6'
    
    oidcIssuerProfile: {
      enabled: true
    }

    disableLocalAccounts: true
    aadProfile: {
      managed: true
      enableAzureRBAC: true
      adminGroupObjectIDs: [
        '468a9d65-ed80-40aa-9146-b2da752f9cfc'
      ]
      tenantID: tenantID
    } 
    
    azureMonitorProfile: {
      metrics: {
        enabled: true
      }
    }
    
    dnsPrefix: dnsPrefix

    // container networking configuration
    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'calico'
      serviceCidr: '10.10.0.0/16'
      dnsServiceIP: '10.10.0.10'
      loadBalancerSku: 'standard'
    }

    agentPoolProfiles: [
      {
        name: 'agentpool'
        osDiskSizeGB: osDiskSizeGB
        count: agentCount
        vmSize: agentVMSize
        osType: 'Linux'
        mode: 'System'
        vnetSubnetID: aksSubnetId_1
        
      }
    ]
    
  }
}

output controlPlaneFQDN string = aks.properties.fqdn
