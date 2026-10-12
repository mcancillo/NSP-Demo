@description('Deployment location.')
param location string

@description('Subscription containing the demo.')
param subscriptionId string

@description('Common resource tags.')
param tags object

var suffix = uniqueString(subscriptionId, resourceGroup().id)
var vnetName = 'NSP-demo-vnet'
var storageName = toLower('nspdemo${suffix}')
var keyVaultName = toLower('nspdemokv${suffix}')

resource vnet 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.42.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'NSP-demo-snet-workload'
        properties: {
          addressPrefix: '10.42.1.0/24'
        }
      }
      {
        name: 'NSP-demo-snet-management'
        properties: {
          addressPrefix: '10.42.2.0/24'
        }
      }
    ]
  }
}

resource avnm 'Microsoft.Network/networkManagers@2023-09-01' = {
  name: 'NSP-demo-avnm'
  location: location
  tags: tags
  properties: {
    networkManagerScopes: {
      managementGroups: []
      subscriptions: [
        subscription().id
      ]
    }
    networkManagerScopeAccesses: [
      'Connectivity'
      'SecurityAdmin'
    ]
  }
}

resource networkGroup 'Microsoft.Network/networkManagers/networkGroups@2023-09-01' = {
  parent: avnm
  name: 'NSP-demo-network-group'
  properties: {
    description: 'VNet group used by the NSP demo security-admin policy.'
  }
}

resource networkGroupMember 'Microsoft.Network/networkManagers/networkGroups/staticMembers@2023-09-01' = {
  parent: networkGroup
  name: 'NSP-demo-vnet-member'
  properties: {
    resourceId: vnet.id
  }
}

resource securityAdmin 'Microsoft.Network/networkManagers/securityAdminConfigurations@2023-09-01' = {
  parent: avnm
  name: 'NSP-demo-security-admin'
  properties: {
    description: 'Deny inbound RDP in the demo VNet to illustrate centralized AVNM governance.'
  }
}

resource ruleCollection 'Microsoft.Network/networkManagers/securityAdminConfigurations/ruleCollections@2023-09-01' = {
  parent: securityAdmin
  name: 'NSP-demo-inbound-baseline'
  properties: {
    appliesToGroups: [
      {
        networkGroupId: networkGroup.id
      }
    ]
  }
}

resource denyRdp 'Microsoft.Network/networkManagers/securityAdminConfigurations/ruleCollections/rules@2023-09-01' = {
  parent: ruleCollection
  name: 'NSP-demo-deny-rdp'
  kind: 'Custom'
  properties: {
    access: 'Deny'
    direction: 'Inbound'
    priority: 100
    protocol: 'Tcp'
    sourcePortRanges: [
      '0-65535'
    ]
    destinationPortRanges: [
      '3389'
    ]
    sources: [
      {
        addressPrefix: '*'
        addressPrefixType: 'IPPrefix'
      }
    ]
    destinations: [
      {
        addressPrefix: '*'
        addressPrefixType: 'IPPrefix'
      }
    ]
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  tags: tags
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Enabled'
    supportsHttpsTrafficOnly: true
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    tenantId: tenant().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    publicNetworkAccess: 'Enabled'
  }
}

resource log 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'NSP-demo-log'
  location: location
  tags: tags
  properties: {
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource perimeter 'Microsoft.Network/networkSecurityPerimeters@2025-05-01' = {
  name: 'NSP-demo-perimeter'
  location: location
  tags: tags
  properties: {}
}

resource profile 'Microsoft.Network/networkSecurityPerimeters/profiles@2025-05-01' = {
  parent: perimeter
  name: 'NSP-demo-profile'
  properties: {}
}

resource outboundRule 'Microsoft.Network/networkSecurityPerimeters/profiles/accessRules@2025-05-01' = {
  parent: profile
  name: 'NSP-demo-allow-azure-monitor'
  properties: {
    direction: 'Outbound'
    fullyQualifiedDomainNames: [
      'dc.services.visualstudio.com'
      'ods.opinsights.azure.com'
    ]
  }
}

resource storageAssociation 'Microsoft.Network/networkSecurityPerimeters/resourceAssociations@2025-05-01' = {
  parent: perimeter
  name: 'NSP-demo-storage-association'
  properties: {
    accessMode: 'Enforced'
    privateLinkResource: {
      id: storage.id
    }
    profile: {
      id: profile.id
    }
  }
}

resource keyVaultAssociation 'Microsoft.Network/networkSecurityPerimeters/resourceAssociations@2025-05-01' = {
  parent: perimeter
  name: 'NSP-demo-keyvault-association'
  properties: {
    accessMode: 'Enforced'
    privateLinkResource: {
      id: keyVault.id
    }
    profile: {
      id: profile.id
    }
  }
}

output perimeterId string = perimeter.id
output storageAccountName string = storage.name
output keyVaultName string = keyVault.name
