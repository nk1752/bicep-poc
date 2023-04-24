@description('The location of this regional hub. All resources, including spoke resources, will be deployed to this region. This region must support availability zones.')
@minLength(6)
param location string = resourceGroup().location

@description('Set to true to include a basic VPN Gateway deployment into the hub. Set to false to leave network space for a VPN Gateway, but do not deploy one. Default is false. Note deploying VPN gateways can take significant time.')
param deployVpnGateway bool = false

@description('Set to true to include one Windows and one Linux virtual machine for you to experience peering, gateway transit, and bastion access. Default is false.')
param deployVirtualMachines bool = false

@description('Username for both the Linux and Windows VM. Must only contain letters, numbers, hyphens, and underscores and may not start with a hyphen or number. Only needed when providing deployVirtualMachines=true.')
@minLength(4)
@maxLength(20)
param adminUsername string = 'azureadmin'

@description('Password for both the Linux and Windows VM. Password must have 3 of the following: 1 lower case character, 1 upper case character, 1 number, and 1 special character. Must be at least 12 characters. Only needed when providing deployVirtualMachines=true.')
@maxLength(70)
@secure()
param adminPassword string

var suffix = uniqueString(subscription().subscriptionId, resourceGroup().id)
var numFirewallIpAddressesToAssign = 3

resource vnet_location_hub_to_vnet_location_spoke_one 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-01-01' = {
  parent: vnet_location_hub
  name: 'to_vnet-${location}-spoke-one'
  properties: {
    allowForwardedTraffic: false
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnet_location_spoke_one.id
    }
  }
  dependsOn: [
    vnet_location_spoke_one_to_vnet_location_hub

  ]
}

resource vnet_location_hub_to_vnet_location_spoke_two 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-01-01' = {
  parent: vnet_location_hub
  name: 'to_vnet-${location}-spoke-two'
  properties: {
    allowForwardedTraffic: false
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnet_location_spoke_two.id
    }
  }
  dependsOn: [
    vnet_location_spoke_two_to_vnet_location_hub

  ]
}

resource fw_policies_location_DefaultNetworkRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2022-01-01' = {
  parent: fw_policies_location
  name: 'DefaultNetworkRuleCollectionGroup'
  properties: {
    priority: 200
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'org-wide-allowed'
        priority: 100
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'DNS'
            description: 'Allow DNS outbound (for simplicity, adjust as needed)'
            ipProtocols: [
              'UDP'
            ]
            sourceAddresses: [
              '*'
            ]
            sourceIpGroups: []
            destinationAddresses: [
              '*'
            ]
            destinationIpGroups: []
            destinationFqdns: []
            destinationPorts: [
              '53'
            ]
          }
        ]
      }
    ]
  }
}

resource fw_policies_location_DefaultApplicationRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2022-01-01' = {
  parent: fw_policies_location
  name: 'DefaultApplicationRuleCollectionGroup'
  properties: {
    priority: 300
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'org-wide-allowed'
        priority: 100
        action: {
          type: 'Allow'
        }
        rules: (deployVirtualMachines ? [
          {
            ruleType: 'ApplicationRule'
            name: 'WindowsVirtualMachineHealth'
            description: 'Supports Windows Updates and Windows Diagnostics'
            fqdnTags: [
              'WindowsDiagnostics'
              'WindowsUpdate'
            ]
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            sourceAddresses: [
              '10.200.0.0/24'
            ]
          }
        ] : [])
      }
    ]
  }
  dependsOn: [
    fw_policies_location_DefaultNetworkRuleCollectionGroup

  ]
}

resource vnet_location_spoke_one_to_vnet_location_hub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-01-01' = {
  parent: vnet_location_spoke_one
  name: 'to_vnet-${location}-hub'
  properties: {
    allowForwardedTraffic: false
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnet_location_hub.id
    }
  }
}

resource vnet_location_spoke_two_to_vnet_location_hub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-01-01' = {
  parent: vnet_location_spoke_two
  name: 'to_vnet-${location}-hub'
  properties: {
    allowForwardedTraffic: false
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnet_location_hub.id
    }
  }
}

@description('This Log Analyics Workspace stores logs from the regional hub network, its spokes, and other related resources. Workspaces are regional resource, as such there would be one workspace per hub (region)')
resource la_hub_location_suffix 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: 'la-hub-${location}-${suffix}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 90
    forceCmkForQuery: false
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    features: {
      disableLocalAuth: false
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
  }
}

resource to_hub_la_1 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: 'Microsoft.OperationalInsights/workspaces/la-hub-${location}-${suffix}'
  name: 'to-hub-la-1'
  properties: {
    workspaceId: la_hub_location_suffix.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

@description('The NSG around the Azure Bastion subnet. Source: https://learn.microsoft.com/azure/bastion/bastion-nsg')
resource nsg_location_bastion 'Microsoft.Network/networkSecurityGroups@2022-01-01' = {
  name: 'nsg-${location}-bastion'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowWebExperienceInbound'
        properties: {
          description: 'Allow our users in. Update this to be as restrictive as possible.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowControlPlaneInbound'
        properties: {
          description: 'Service Requirement. Allow control plane access. Regional Tag not yet supported.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowHealthProbesInbound'
        properties: {
          description: 'Service Requirement. Allow Health Probes.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowBastionHostToHostInbound'
        properties: {
          description: 'Service Requirement. Allow Required Host to Host Communication.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          description: 'No further inbound traffic allowed.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowSshToVnetOutbound'
        properties: {
          description: 'Allow SSH out to the virtual network'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '22'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowRdpToVnetOutbound'
        properties: {
          description: 'Allow RDP out to the virtual network'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '3389'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 110
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowControlPlaneOutbound'
        properties: {
          description: 'Required for control plane outbound. Regional prefix not yet supported'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '443'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 120
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowBastionHostToHostOutbound'
        properties: {
          description: 'Service Requirement. Allow Required Host to Host Communication.'
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 130
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowBastionCertificateValidationOutbound'
        properties: {
          description: 'Service Requirement. Allow Required Session and Certificate Validation.'
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '80'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 140
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyAllOutbound'
        properties: {
          description: 'No further outbound traffic allowed.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource to_hub_la_2 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: 'Microsoft.Network/networkSecurityGroups/nsg-${location}-bastion'
  name: 'to-hub-la-2'
  properties: {
    workspaceId: la_hub_location_suffix.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
  dependsOn: [

    nsg_location_bastion
  ]
}

@description('The regional hub network.')
resource vnet_location_hub 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: 'vnet-${location}-hub'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/22'
      ]
    }
    subnets: [
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.0.1.0/26'
          networkSecurityGroup: {
            id: nsg_location_bastion.id
          }
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.0.2.0/27'
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.0.3.0/26'
        }
      }
    ]
  }
}

resource to_hub_la_3 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: 'Microsoft.Network/virtualNetworks/vnet-${location}-hub'
  name: 'to-hub-la-3'
  properties: {
    workspaceId: la_hub_location_suffix.id
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
  dependsOn: [

    vnet_location_hub
  ]
}

resource pip_fw_location_0_numFirewallIpAddressesToAssign_2_0 'Microsoft.Network/publicIPAddresses@2022-01-01' = [for i in range(0, length(range(0, numFirewallIpAddressesToAssign))): {
  name: 'pip-fw-${location}-${padLeft(range(0, numFirewallIpAddressesToAssign)[i], 2, '0')}'
  location: location
  sku: {
    name: 'Standard'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    publicIPAddressVersion: 'IPv4'
  }
}]

resource to_hub_la_4 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [for i in range(0, length(range(0, numFirewallIpAddressesToAssign))): {
  scope: 'Microsoft.Network/publicIPAddresses/pip-fw-${location}-${padLeft(range(0, numFirewallIpAddressesToAssign)[range(0, numFirewallIpAddressesToAssign)[i]], 2, '0')}'
  name: 'to-hub-la-4'
  properties: {
    workspaceId: la_hub_location_suffix.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
  dependsOn: [
    la_hub_location_suffix
    resourceId('Microsoft.Network/publicIPAddresses', 'pip-fw-${location}-${padLeft(range(0, numFirewallIpAddressesToAssign)[range(0, numFirewallIpAddressesToAssign)[i]], 2, '0')}')
  ]
}]

@description('Azure Firewall Policy')
resource fw_policies_location 'Microsoft.Network/firewallPolicies@2022-01-01' = {
  name: 'fw-policies-${location}'
  location: location
  properties: {
    sku: {
      tier: 'Standard'
    }
    threatIntelMode: 'Deny'
    insights: {
      isEnabled: true
      retentionDays: 30
      logAnalyticsResources: {
        defaultWorkspaceId: {
          id: la_hub_location_suffix.id
        }
      }
    }
    threatIntelWhitelist: {
      fqdns: []
      ipAddresses: []
    }
    intrusionDetection: null
    dnsSettings: {
      servers: []
      enableProxy: true
    }
  }
}

@description('This is the regional Azure Firewall that all regional spoke networks can egress through.')
resource fw_location 'Microsoft.Network/azureFirewalls@2022-01-01' = {
  name: 'fw-${location}'
  location: location
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    ipConfigurations: [for j in range(0, length(range(0, numFirewallIpAddressesToAssign))): {
      name: 'pip-fw-${location}-${padLeft(range(0, numFirewallIpAddressesToAssign)[range(0, numFirewallIpAddressesToAssign)[j]], 2, '0')}'
      properties: {
        subnet: ((0 == range(0, numFirewallIpAddressesToAssign)[j]) ? {
          id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'vnet-${location}-hub', 'AzureFirewallSubnet')
        } : null)
        publicIPAddress: {
          id: resourceId('Microsoft.Network/publicIPAddresses', 'pip-fw-${location}-${padLeft(range(0, numFirewallIpAddressesToAssign)[range(0, numFirewallIpAddressesToAssign)[j]], 2, '0')}')
        }
      }
    }]
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    firewallPolicy: {
      id: fw_policies_location.id
    }
  }
  dependsOn: [
    fw_policies_location_DefaultApplicationRuleCollectionGroup
    fw_policies_location_DefaultNetworkRuleCollectionGroup

    pip_fw_location_0_numFirewallIpAddressesToAssign_2_0
    vnet_location_hub
  ]
}

resource to_hub_la_5 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: 'Microsoft.Network/azureFirewalls/fw-${location}'
  name: 'to-hub-la-5'
  properties: {
    workspaceId: la_hub_location_suffix.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
  dependsOn: [
    fw_location

  ]
}

@description('The public IP for the regional hub\'s Azure Bastion service.')
resource pip_ab_location 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: 'pip-ab-${location}'
  location: location
  sku: {
    name: 'Standard'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    publicIPAddressVersion: 'IPv4'
  }
}

resource to_hub_la_6 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: 'Microsoft.Network/publicIPAddresses/pip-ab-${location}'
  name: 'to-hub-la-6'
  properties: {
    workspaceId: la_hub_location_suffix.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
  dependsOn: [

    pip_ab_location
  ]
}

@description('This regional hub\'s Azure Bastion service. NSGs are configured to allow Bastion to reach any resource subnet in peered spokes.')
resource ab_location_suffix 'Microsoft.Network/bastionHosts@2022-01-01' = {
  name: 'ab-${location}-${suffix}'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'hub-subnet'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'vnet-${location}-hub', 'AzureBastionSubnet')
          }
          publicIPAddress: {
            id: pip_ab_location.id
          }
        }
      }
    ]
  }
  dependsOn: [

    vnet_location_hub
  ]
}

resource to_hub_la_7 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: 'Microsoft.Network/bastionHosts/ab-${location}-${suffix}'
  name: 'to-hub-la-7'
  properties: {
    workspaceId: la_hub_location_suffix.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
  dependsOn: [
    ab_location_suffix

  ]
}

@description('The public IPs for the regional VPN gateway. Only deployed if requested.')
resource pip_vgw_location 'Microsoft.Network/publicIPAddresses@2022-01-01' = if (deployVpnGateway) {
  name: 'pip-vgw-${location}'
  location: location
  sku: {
    name: 'Standard'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    publicIPAddressVersion: 'IPv4'
  }
}

resource to_hub_la_8 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (deployVpnGateway) {
  scope: 'Microsoft.Network/publicIPAddresses/pip-vgw-${location}'
  name: 'to-hub-la-8'
  properties: {
    workspaceId: la_hub_location_suffix.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
  dependsOn: [

    pip_vgw_location
  ]
}

@description('The is the regional VPN gateway, configured with basic settings. Only deployed if requested.')
resource vgw_location_hub 'Microsoft.Network/virtualNetworkGateways@2022-01-01' = if (deployVpnGateway) {
  name: 'vgw-${location}-hub'
  location: location
  properties: {
    sku: {
      name: 'VpnGw2AZ'
      tier: 'VpnGw2AZ'
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    vpnGatewayGeneration: 'Generation2'
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pip_vgw_location.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'vnet-${location}-hub', 'GatewaySubnet')
          }
        }
      }
    ]
  }
  dependsOn: [

    vnet_location_hub
  ]
}

resource to_hub_la_9 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (deployVpnGateway) {
  scope: 'Microsoft.Network/virtualNetworkGateways/vgw-${location}-hub'
  name: 'to-hub-la-9'
  properties: {
    workspaceId: la_hub_location_suffix.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
  dependsOn: [

    vgw_location_hub
  ]
}

@description('Next hop to the regional hub\'s Azure Firewall')
resource route_to_location_hub_fw 'Microsoft.Network/routeTables@2022-01-01' = {
  name: 'route-to-${location}-hub-fw'
  location: location
  properties: {
    routes: [
      {
        name: 'r-nexthop-to-fw'
        properties: {
          nextHopType: 'VirtualAppliance'
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: fw_location.properties.ipConfigurations[0].properties.privateIPAddress
        }
      }
    ]
  }
}

@description('NSG on the resource subnet (just using a common one for all as an example, but usually would be based on the specific needs of the spoke).')
resource nsg_spoke_resources 'Microsoft.Network/networkSecurityGroups@2022-01-01' = {
  name: 'nsg-spoke-resources'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowBastionRdpFromHub'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: reference(resourceId('Microsoft.Network/virtualNetworks/subnets', 'vnet-${location}-hub', 'AzureBastionSubnet'), '2022-01-01').addressPrefix
          destinationPortRanges: [
            '3389'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowBastionSshFromHub'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: reference(resourceId('Microsoft.Network/virtualNetworks/subnets', 'vnet-${location}-hub', 'AzureBastionSubnet'), '2022-01-01').addressPrefix
          destinationPortRanges: [
            '22'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
    ]
  }
  dependsOn: [
    vnet_location_hub
  ]
}

resource to_hub_la_10 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: nsg_spoke_resources
  name: 'to-hub-la-10'
  properties: {
    workspaceId: la_hub_location_suffix.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

@description('NSG on the Private Link subnet (just using a common one for all as an example, but usually would be based on the specific needs of the spoke).')
resource nsg_spoke_privatelinkendpoints 'Microsoft.Network/networkSecurityGroups@2022-01-01' = {
  name: 'nsg-spoke-privatelinkendpoints'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowAll443InFromVnet'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '443'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllOutbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource to_hub_la_11 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: nsg_spoke_privatelinkendpoints
  name: 'to-hub-la-11'
  properties: {
    workspaceId: la_hub_location_suffix.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

resource vnet_location_spoke_one 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: 'vnet-${location}-spoke-one'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.100.0.0/22'
      ]
    }
    subnets: [
      {
        name: 'snet-resources'
        properties: {
          addressPrefix: '10.100.0.0/24'
          networkSecurityGroup: {
            id: nsg_spoke_resources.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
          routeTable: {
            id: route_to_location_hub_fw.id
          }
        }
      }
      {
        name: 'snet-privatelinkendpoints'
        properties: {
          addressPrefix: '10.100.1.0/26'
          networkSecurityGroup: {
            id: nsg_spoke_privatelinkendpoints.id
          }
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          routeTable: {
            id: route_to_location_hub_fw.id
          }
        }
      }
    ]
  }
}

resource to_hub_la_12 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: 'Microsoft.Network/virtualNetworks/vnet-${location}-spoke-one'
  name: 'to-hub-la-12'
  properties: {
    workspaceId: la_hub_location_suffix.id
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
  dependsOn: [

    vnet_location_spoke_one
  ]
}

@description('The private Network Interface Card for the linux VM in spoke one.')
resource nic_vm_location_spoke_one_linux 'Microsoft.Network/networkInterfaces@2022-01-01' = if (deployVirtualMachines) {
  name: 'nic-vm-${location}-spoke-one-linux'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'vnet-${location}-spoke-one', 'snet-resources')
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    enableAcceleratedNetworking: true
  }
  dependsOn: [
    vnet_location_spoke_one
  ]
}

resource to_hub_la_15 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: 'Microsoft.Network/networkInterfaces/nic-vm-${location}-spoke-one-linux'
  name: 'to-hub-la-15'
  properties: {
    workspaceId: la_hub_location_suffix.id
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
  dependsOn: [

    nic_vm_location_spoke_one_linux
  ]
}

@description('A basic Linux virtual machine that will be attached to spoke one.')
resource vm_location_spoke_one_linux 'Microsoft.Compute/virtualMachines@2022-03-01' = if (deployVirtualMachines) {
  name: 'vm-${location}-spoke-one-linux'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2ds_v4'
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
        caching: 'ReadOnly'
        diffDiskSettings: {
          option: 'Local'
          placement: 'CacheDisk'
        }
        deleteOption: 'Delete'
      }
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: '20_04-lts-gen2'
        version: 'latest'
      }
      dataDisks: []
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: null
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic_vm_location_spoke_one_linux.id
          properties: {
            deleteOption: 'Delete'
            primary: true
          }
        }
      ]
    }
    osProfile: {
      computerName: 'examplevm'
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
        patchSettings: {
          patchMode: 'ImageDefault'
          assessmentMode: 'ImageDefault'
        }
      }
    }
    priority: 'Regular'
  }
}

resource vnet_location_spoke_two 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: 'vnet-${location}-spoke-two'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.200.0.0/22'
      ]
    }
    subnets: [
      {
        name: 'snet-resources'
        properties: {
          addressPrefix: '10.200.0.0/24'
          networkSecurityGroup: {
            id: nsg_spoke_resources.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
          routeTable: {
            id: route_to_location_hub_fw.id
          }
        }
      }
      {
        name: 'snet-privatelinkendpoints'
        properties: {
          addressPrefix: '10.200.1.0/26'
          networkSecurityGroup: {
            id: nsg_spoke_privatelinkendpoints.id
          }
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          routeTable: {
            id: route_to_location_hub_fw.id
          }
        }
      }
    ]
  }
}

resource to_hub_la_16 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: 'Microsoft.Network/virtualNetworks/vnet-${location}-spoke-two'
  name: 'to-hub-la-16'
  properties: {
    workspaceId: la_hub_location_suffix.id
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
  dependsOn: [

    vnet_location_spoke_two
  ]
}

@description('The private Network Interface Card for the Windows VM in spoke two.')
resource nic_vm_location_spoke_two_windows 'Microsoft.Network/networkInterfaces@2022-01-01' = if (deployVirtualMachines) {
  name: 'nic-vm-${location}-spoke-two-windows'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'vnet-${location}-spoke-two', 'snet-resources')
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    enableAcceleratedNetworking: true
  }
  dependsOn: [
    vnet_location_spoke_two
  ]
}

resource to_hub_la_17 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: 'Microsoft.Network/networkInterfaces/nic-vm-${location}-spoke-two-windows'
  name: 'to-hub-la-17'
  properties: {
    workspaceId: la_hub_location_suffix.id
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
  dependsOn: [

    nic_vm_location_spoke_two_windows
  ]
}

@description('A basic Windows virtual machine that will be attached to spoke two.')
resource vm_location_spoke_two_windows 'Microsoft.Compute/virtualMachines@2022-03-01' = if (deployVirtualMachines) {
  name: 'vm-${location}-spoke-two-windows'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        deleteOption: 'Delete'
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      dataDisks: []
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: null
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic_vm_location_spoke_two_windows.id
          properties: {
            deleteOption: 'Delete'
            primary: true
          }
        }
      ]
    }
    osProfile: {
      computerName: 'examplevm'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
        }
      }
    }
    priority: 'Regular'
  }
}