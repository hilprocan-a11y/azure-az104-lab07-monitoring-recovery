targetScope = 'resourceGroup'

@description('Existing Recovery Services vault in the same region as the protected VM.')
param vaultName string = 'rsv-hn-az104-lab07-wus3'
param vmName string = 'vm-lab07-backup'
param policyName string = 'policy-lab07-vm-daily'

@description('Preserve the observed UTC schedule timestamp during adoption. The policy repeats daily.')
param scheduleTime string = '2026-10-29T08:00:00Z'

resource vault 'Microsoft.RecoveryServices/vaults@2024-10-01' existing = {
  name: vaultName
}

resource vm 'Microsoft.Compute/virtualMachines@2024-11-01' existing = {
  name: vmName
}

resource policy 'Microsoft.RecoveryServices/vaults/backupPolicies@2024-10-01' = {
  parent: vault
  name: policyName
  properties: {
    backupManagementType: 'AzureIaasVM'
    policyType: 'V2'
    timeZone: 'UTC'
    instantRpRetentionRangeInDays: 1
    schedulePolicy: {
      schedulePolicyType: 'SimpleSchedulePolicyV2'
      scheduleRunFrequency: 'Daily'
      dailySchedule: {
        scheduleRunTimes: [
          scheduleTime
        ]
      }
    }
    retentionPolicy: {
      retentionPolicyType: 'LongTermRetentionPolicy'
      dailySchedule: {
        retentionTimes: [
          scheduleTime
        ]
        retentionDuration: {
          count: 7
          durationType: 'Days'
        }
      }
    }
    // Observed snapshotConsistencyType was null. Preserve the service default.
  }
}

var containerName = 'IaasVMContainer;iaasvmcontainerv2;${toLower(resourceGroup().name)};${vmName}'
var itemName = 'VM;iaasvmcontainerv2;${toLower(resourceGroup().name)};${vmName}'

resource protectedItem 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2024-10-01' = {
  name: '${vault.name}/Azure/${containerName}/${itemName}'
  properties: {
    protectedItemType: 'Microsoft.Compute/virtualMachines'
    sourceResourceId: vm.id
    policyId: policy.id
  }
}

output vaultName string = vault.name
output backupPolicyName string = policy.name
output protectedVmId string = vm.id
output protectedItemId string = protectedItem.id


