resource symbolicname 'Microsoft.ContainerService/managedClusters@2023-07-02-preview' = {
  name: 'string'
  location: 'string'
  tags: {
    tagName1: 'tagValue1'
    tagName2: 'tagValue2'
  }
  sku: {
    name: 'Base'
    tier: 'string'
  }
  extendedLocation: {
    name: 'string'
    type: 'EdgeZone'
  }
  identity: {
    delegatedResources: {}
    type: 'string'
    userAssignedIdentities: {}
  }
  properties: {
    aadProfile: {
      adminGroupObjectIDs: [
        'string'
      ]
      clientAppID: 'string'
      enableAzureRBAC: bool
      managed: bool
      serverAppID: 'string'
      serverAppSecret: 'string'
      tenantID: 'string'
    }
    addonProfiles: {}
    agentPoolProfiles: [
      {
        availabilityZones: [
          'string'
        ]
        capacityReservationGroupID: 'string'
        count: int
        creationData: {
          sourceResourceId: 'string'
        }
        enableAutoScaling: bool
        enableCustomCATrust: bool
        enableEncryptionAtHost: bool
        enableFIPS: bool
        enableNodePublicIP: bool
        enableUltraSSD: bool
        gpuInstanceProfile: 'string'
        hostGroupID: 'string'
        kubeletConfig: {
          allowedUnsafeSysctls: [
            'string'
          ]
          containerLogMaxFiles: int
          containerLogMaxSizeMB: int
          cpuCfsQuota: bool
          cpuCfsQuotaPeriod: 'string'
          cpuManagerPolicy: 'string'
          failSwapOn: bool
          imageGcHighThreshold: int
          imageGcLowThreshold: int
          podMaxPids: int
          topologyManagerPolicy: 'string'
        }
        kubeletDiskType: 'string'
        linuxOSConfig: {
          swapFileSizeMB: int
          sysctls: {
            fsAioMaxNr: int
            fsFileMax: int
            fsInotifyMaxUserWatches: int
            fsNrOpen: int
            kernelThreadsMax: int
            netCoreNetdevMaxBacklog: int
            netCoreOptmemMax: int
            netCoreRmemDefault: int
            netCoreRmemMax: int
            netCoreSomaxconn: int
            netCoreWmemDefault: int
            netCoreWmemMax: int
            netIpv4IpLocalPortRange: 'string'
            netIpv4NeighDefaultGcThresh1: int
            netIpv4NeighDefaultGcThresh2: int
            netIpv4NeighDefaultGcThresh3: int
            netIpv4TcpFinTimeout: int
            netIpv4TcpkeepaliveIntvl: int
            netIpv4TcpKeepaliveProbes: int
            netIpv4TcpKeepaliveTime: int
            netIpv4TcpMaxSynBacklog: int
            netIpv4TcpMaxTwBuckets: int
            netIpv4TcpTwReuse: bool
            netNetfilterNfConntrackBuckets: int
            netNetfilterNfConntrackMax: int
            vmMaxMapCount: int
            vmSwappiness: int
            vmVfsCachePressure: int
          }
          transparentHugePageDefrag: 'string'
          transparentHugePageEnabled: 'string'
        }
        maxCount: int
        maxPods: int
        messageOfTheDay: 'string'
        minCount: int
        mode: 'string'
        name: 'string'
        networkProfile: {
          allowedHostPorts: [
            {
              portEnd: int
              portStart: int
              protocol: 'string'
            }
          ]
          applicationSecurityGroups: [
            'string'
          ]
          nodePublicIPTags: [
            {
              ipTagType: 'string'
              tag: 'string'
            }
          ]
        }
        nodeLabels: {}
        nodePublicIPPrefixID: 'string'
        nodeTaints: [
          'string'
        ]
        orchestratorVersion: 'string'
        osDiskSizeGB: int
        osDiskType: 'string'
        osSKU: 'string'
        osType: 'string'
        podSubnetID: 'string'
        powerState: {
          code: 'string'
        }
        proximityPlacementGroupID: 'string'
        scaleDownMode: 'string'
        scaleSetEvictionPolicy: 'string'
        scaleSetPriority: 'string'
        securityProfile: {
          sshAccess: 'string'
        }
        spotMaxPrice: json('decimal-as-string')
        tags: {}
        type: 'string'
        upgradeSettings: {
          drainTimeoutInMinutes: int
          maxSurge: 'string'
        }
        vmSize: 'string'
        vnetSubnetID: 'string'
        windowsProfile: {
          disableOutboundNat: bool
        }
        workloadRuntime: 'string'
      }
    ]
    apiServerAccessProfile: {
      authorizedIPRanges: [
        'string'
      ]
      disableRunCommand: bool
      enablePrivateCluster: bool
      enablePrivateClusterPublicFQDN: bool
      enableVnetIntegration: bool
      privateDNSZone: 'string'
      subnetId: 'string'
    }
    autoScalerProfile: {
      'balance-similar-node-groups': 'string'
      expander: 'string'
      'max-empty-bulk-delete': 'string'
      'max-graceful-termination-sec': 'string'
      'max-node-provision-time': 'string'
      'max-total-unready-percentage': 'string'
      'new-pod-scale-up-delay': 'string'
      'ok-total-unready-count': 'string'
      'scale-down-delay-after-add': 'string'
      'scale-down-delay-after-delete': 'string'
      'scale-down-delay-after-failure': 'string'
      'scale-down-unneeded-time': 'string'
      'scale-down-unready-time': 'string'
      'scale-down-utilization-threshold': 'string'
      'scan-interval': 'string'
      'skip-nodes-with-local-storage': 'string'
      'skip-nodes-with-system-pods': 'string'
    }
    autoUpgradeProfile: {
      nodeOSUpgradeChannel: 'string'
      upgradeChannel: 'string'
    }
    azureMonitorProfile: {
      logs: {
        appMonitoring: {
          enabled: bool
        }
        containerInsights: {
          enabled: bool
          logAnalyticsWorkspaceResourceId: 'string'
          windowsHostLogs: {
            enabled: bool
          }
        }
      }
      metrics: {
        appMonitoringOpenTelemetryMetrics: {
          enabled: bool
        }
        enabled: bool
        kubeStateMetrics: {
          metricAnnotationsAllowList: 'string'
          metricLabelsAllowlist: 'string'
        }
      }
    }
    creationData: {
      sourceResourceId: 'string'
    }
    disableLocalAccounts: bool
    diskEncryptionSetID: 'string'
    dnsPrefix: 'string'
    enableNamespaceResources: bool
    enablePodSecurityPolicy: bool
    enableRBAC: bool
    fqdnSubdomain: 'string'
    guardrailsProfile: {
      excludedNamespaces: [
        'string'
      ]
      level: 'string'
      version: 'string'
    }
    httpProxyConfig: {
      httpProxy: 'string'
      httpsProxy: 'string'
      noProxy: [
        'string'
      ]
      trustedCa: 'string'
    }
    identityProfile: {}
    ingressProfile: {
      webAppRouting: {
        dnsZoneResourceIds: [
          'string'
        ]
        enabled: bool
      }
    }
    kubernetesVersion: 'string'
    linuxProfile: {
      adminUsername: 'string'
      ssh: {
        publicKeys: [
          {
            keyData: 'string'
          }
        ]
      }
    }
    metricsProfile: {
      costAnalysis: {
        enabled: bool
      }
    }
    networkProfile: {
      dnsServiceIP: 'string'
      ipFamilies: [
        'string'
      ]
      kubeProxyConfig: {
        enabled: bool
        ipvsConfig: {
          scheduler: 'string'
          tcpFinTimeoutSeconds: int
          tcpTimeoutSeconds: int
          udpTimeoutSeconds: int
        }
        mode: 'string'
      }
      loadBalancerProfile: {
        allocatedOutboundPorts: int
        backendPoolType: 'string'
        effectiveOutboundIPs: [
          {
            id: 'string'
          }
        ]
        enableMultipleStandardLoadBalancers: bool
        idleTimeoutInMinutes: int
        managedOutboundIPs: {
          count: int
          countIPv6: int
        }
        outboundIPPrefixes: {
          publicIPPrefixes: [
            {
              id: 'string'
            }
          ]
        }
        outboundIPs: {
          publicIPs: [
            {
              id: 'string'
            }
          ]
        }
      }
      loadBalancerSku: 'string'
      monitoring: {
        enabled: bool
      }
      natGatewayProfile: {
        effectiveOutboundIPs: [
          {
            id: 'string'
          }
        ]
        idleTimeoutInMinutes: int
        managedOutboundIPProfile: {
          count: int
        }
      }
      networkDataplane: 'string'
      networkMode: 'string'
      networkPlugin: 'string'
      networkPluginMode: 'overlay'
      networkPolicy: 'string'
      outboundType: 'string'
      podCidr: 'string'
      podCidrs: [
        'string'
      ]
      serviceCidr: 'string'
      serviceCidrs: [
        'string'
      ]
    }
    nodeResourceGroup: 'string'
    nodeResourceGroupProfile: {
      restrictionLevel: 'string'
    }
    oidcIssuerProfile: {
      enabled: bool
    }
    podIdentityProfile: {
      allowNetworkPluginKubenet: bool
      enabled: bool
      userAssignedIdentities: [
        {
          bindingSelector: 'string'
          identity: {
            clientId: 'string'
            objectId: 'string'
            resourceId: 'string'
          }
          name: 'string'
          namespace: 'string'
        }
      ]
      userAssignedIdentityExceptions: [
        {
          name: 'string'
          namespace: 'string'
          podLabels: {}
        }
      ]
    }
    privateLinkResources: [
      {
        groupId: 'string'
        id: 'string'
        name: 'string'
        requiredMembers: [
          'string'
        ]
        type: 'string'
      }
    ]
    publicNetworkAccess: 'string'
    securityProfile: {
      azureKeyVaultKms: {
        enabled: bool
        keyId: 'string'
        keyVaultNetworkAccess: 'string'
        keyVaultResourceId: 'string'
      }
      customCATrustCertificates: [
        any
      ]
      defender: {
        logAnalyticsWorkspaceResourceId: 'string'
        securityMonitoring: {
          enabled: bool
        }
      }
      imageCleaner: {
        enabled: bool
        intervalHours: int
      }
      imageIntegrity: {
        enabled: bool
      }
      nodeRestriction: {
        enabled: bool
      }
      workloadIdentity: {
        enabled: bool
      }
    }
    serviceMeshProfile: {
      istio: {
        certificateAuthority: {
          plugin: {
            certChainObjectName: 'string'
            certObjectName: 'string'
            keyObjectName: 'string'
            keyVaultId: 'string'
            rootCertObjectName: 'string'
          }
        }
        components: {
          ingressGateways: [
            {
              enabled: bool
              mode: 'string'
            }
          ]
        }
        revisions: [
          'string'
        ]
      }
      mode: 'string'
    }
    servicePrincipalProfile: {
      clientId: 'string'
      secret: 'string'
    }
    storageProfile: {
      blobCSIDriver: {
        enabled: bool
      }
      diskCSIDriver: {
        enabled: bool
        version: 'string'
      }
      fileCSIDriver: {
        enabled: bool
      }
      snapshotController: {
        enabled: bool
      }
    }
    supportPlan: 'string'
    upgradeSettings: {
      overrideSettings: {
        forceUpgrade: bool
        until: 'string'
      }
    }
    windowsProfile: {
      adminPassword: 'string'
      adminUsername: 'string'
      enableCSIProxy: bool
      gmsaProfile: {
        dnsServer: 'string'
        enabled: bool
        rootDomainName: 'string'
      }
      licenseType: 'string'
    }
    workloadAutoScalerProfile: {
      keda: {
        enabled: bool
      }
      verticalPodAutoscaler: {
        enabled: bool
      }
    }
  }
}
