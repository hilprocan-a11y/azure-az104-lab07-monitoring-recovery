targetScope = 'resourceGroup'

@description('Existing VM in this resource group. Compute and networking are not deployed here.')
param vmName string = 'vm-lab07-monitor'
param vmRegion string = 'centralus'

@description('Current email address read from the existing action group. Keep private.')
@secure()
@minLength(3)
param notificationEmail string

@description('Exact existing receiver name, including its portal-generated suffix.')
@minLength(1)
param emailReceiverName string

param tags object = {
  Environment: 'Training'
  Lab: 'Lab07'
  Project: 'AZ104'
  Owner: 'Hilaire'
}

resource vm 'Microsoft.Compute/virtualMachines@2024-11-01' existing = {
  name: vmName
}

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-lab07-email'
  location: 'global'
  tags: tags
  properties: {
    groupShortName: 'Lab07Monitor'
    enabled: true
    emailReceivers: [
      {
        name: emailReceiverName
        emailAddress: notificationEmail
        useCommonAlertSchema: true
      }
    ]
  }
}

resource cpuAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-lab07-cpu-high'
  location: 'global'
  tags: tags
  properties: {
    description: 'Average CPU above 40 percent over 5 minutes'
    severity: 2
    enabled: true
    autoMitigate: true
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    targetResourceType: 'Microsoft.Compute/virtualMachines'
    targetResourceRegion: vmRegion
    scopes: [
      vm.id
    ]
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'Metric1'
          criterionType: 'StaticThresholdCriterion'
          metricName: 'Percentage CPU'
          metricNamespace: 'microsoft.compute/virtualmachines'
          operator: 'GreaterThan'
          threshold: 40
          timeAggregation: 'Average'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
        webHookProperties: {}
      }
    ]
  }
}

output alertName string = cpuAlert.name
output actionGroupName string = actionGroup.name
output monitoredVmId string = vm.id
