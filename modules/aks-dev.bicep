@description('The name of the Managed Cluster resource.')
param clusterName string

@description('The DNS prefix specified when creating the managed cluster.')
param dnsPrefix string = clusterName

@description('The ID of the Azure Active Directory tenant used for authentication.')
param tenantID string


@description('aks subnet id.')
//param aksSubnetId_1 string = '/subscriptions/df2f960a-8e92-40ec-a2b8-0a2923d3c074/resourceGroups/MC_bicep_rg/providers/Microsoft.Network/virtualNetworks/vnet-aks-4250/subnets/aks-subnet-2'
param aksSubnetID string 

@description('The location of the Managed Cluster resource.')
param location string


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
  
  tags: {
    environment: 'dev'
    tier: 'free'
  }

  identity: {
    type: 'SystemAssigned'
  }

  sku: {
    name: 'Base'
    tier: 'Free'
  }
  
  // ** properties of the managed cluster
  properties: {
    kubernetesVersion: '1.26.6'
    oidcIssuerProfile: {
      enabled: true
    }
    addonProfiles: {
      azurekeyvaultsecretsprovider: {
        enabled: true
        config: {
          enableSecretRotation: true
          keyvaultName: 'kv-aks-4250'
        }
      }
    }
    disableLocalAccounts: true
    enableRBAC: true
    aadProfile: {
      managed: true
      // Azure AD auth with kubernetes RBAC
      enableAzureRBAC: false
      
      adminGroupObjectIDs: [
        '468a9d65-ed80-40aa-9146-b2da752f9cfc'
      ]
      tenantID: tenantID
    } 

    // container networking configuration
    dnsPrefix: dnsPrefix
    
    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'calico'
      serviceCidr: '10.10.0.0/16'
      dnsServiceIP: '10.10.0.10'
      loadBalancerSku: 'standard'
      
    }
    // agent pool configuration
    agentPoolProfiles: [
      {
        name: 'agentpool'
        osDiskSizeGB: osDiskSizeGB
        count: agentCount
        vmSize: agentVMSize
        osType: 'Linux'
        mode: 'System'
        vnetSubnetID: aksSubnetID
        
      }
    ]
    // enable monitoring
    azureMonitorProfile: {
      metrics: {
        enabled: true
      }
    }
    
  }
}

//output controlPlaneFQDN string = aks.properties.fqdn
output aks_name string = aks.name
output aks_id string = aks.id
output aks_location string = aks.location


