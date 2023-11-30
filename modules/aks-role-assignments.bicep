
var aks_principal_id = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
var acrPullRoleID = '/subscriptions/xxxxxxxxxxxxxxxxxxxxxx'

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: 'vhacr'
}

resource assignACRPullrole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: 'vhacr'
  scope: acr.id
  properties: {
    description: 'Pull role for vhacr'
    principalId: aks_principal_id
    roleDefinitionId: acrPullRoleID
  }
}
