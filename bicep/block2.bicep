targetScope = 'resourceGroup'

@description('Existing VM with its system-assigned identity already enabled. Compute/networking are not deployed here.')
param vmName string = 'vm-lab07-monitor'
param location string = resourceGroup().location
param workspaceName string = 'law-hn-az104-lab07'
param ruleName string = 'dcr-lab07-linux-syslog'

@description('Preserve the actual portal-created association and source/destination names for adoption.')
param associationName string = 'dcr-lab07-linux-syslog-association'
param syslogSourceName string = 'sysLogsDataSource--1469397783'
param destinationName string = 'la--1994148762'

param tags object = {
  Environment: 'Training'
  Lab: 'Lab07'
  Project: 'AZ104'
  Owner: 'Hilaire'
}

resource vm 'Microsoft.Compute/virtualMachines@2024-11-01' existing = {
  name: vmName
}

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    workspaceCapping: {
      // Bicep has no decimal literal; JSON preserves the observed 0.1 GB quota.
      dailyQuotaGb: json('0.1')
    }
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource rule 'Microsoft.Insights/dataCollectionRules@2023-03-11' = {
  name: ruleName
  location: location
  tags: tags
  // kind was null in the observed All-platform rule. Do not change it to Linux during adoption.
  properties: {
    dataSources: {
      syslog: [
        {
          name: syslogSourceName
          streams: [
            'Microsoft-Syslog'
          ]
          facilityNames: [
            'local0'
          ]
          logLevels: [
            'Info'
            'Notice'
            'Warning'
            'Error'
            'Critical'
            'Alert'
            'Emergency'
          ]
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          name: destinationName
          workspaceResourceId: workspace.id
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-Syslog'
        ]
        destinations: [
          destinationName
        ]
      }
    ]
  }
}

resource agent 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = {
  parent: vm
  name: 'AzureMonitorLinuxAgent'
  location: location
  tags: tags
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorLinuxAgent'
    typeHandlerVersion: '1.6'
    autoUpgradeMinorVersion: true
    // Observed settings and enableAutomaticUpgrade were null. Omit both.
  }
}

resource association 'Microsoft.Insights/dataCollectionRuleAssociations@2023-03-11' = {
  scope: vm
  name: associationName
  properties: {
    dataCollectionRuleId: rule.id
  }
  dependsOn: [
    agent
  ]
}

output workspaceName string = workspace.name
output dataCollectionRuleName string = rule.name
output associationName string = association.name
output agentExtensionName string = agent.name
output monitoredVmId string = vm.id
