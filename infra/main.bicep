targetScope = 'subscription'

@description('Deployment location for the demo resource group and regional resources.')
param location string = 'eastus'

@description('Resource group name for the NSP demo.')
param resourceGroupName string = 'NSP-Demo-RG'

@description('Subscription ID containing the demo.')
param subscriptionId string = subscription().subscriptionId

@description('Tags applied to demo resources.')
param tags object = {
  demo: 'NSP-Demo'
  purpose: 'network-security-perimeter'
  managedBy: 'bicep'
}

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module demo './modules/demo.bicep' = {
  name: 'NSP-demo-resources'
  scope: rg
  params: {
    location: location
    subscriptionId: subscriptionId
    tags: tags
  }
}

output resourceGroupId string = rg.id
output perimeterId string = demo.outputs.perimeterId
output storageAccountName string = demo.outputs.storageAccountName
output keyVaultName string = demo.outputs.keyVaultName
