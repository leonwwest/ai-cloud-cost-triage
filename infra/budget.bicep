// infra/budget.bicep - Budget + Alert (Azure)
// Bicep equivalent of budget.tf for the "Budget-Alert" step (8).

param location string = resourceGroup().location
param budgetAmount int = 500
param oncallEmail string = 'platform-oncall@example.com'

// --- Action Group ---
resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-ai-oncall'
  location: 'global'
  properties: {
    groupShortName: 'aiOnCall'
    enabled: true
    emailReceivers: [
      {
        name: 'platform'
        emailAddress: oncallEmail
        useCommonAlertSchema: true
      }
    ]
  }
}

// --- Budget with two thresholds ---
resource budget 'Microsoft.Consumption/budgets@2023-04-01-preview' = {
  name: 'budget-ai-agent'
  properties: {
    amount: budgetAmount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: '2026-07-01T00:00:00Z'
      endDate: '2027-07-01T00:00:00Z'
    }
    filter: {
      tags: {
        name: 'agent_version'
        values: ['prod']
      }
    }
    notifications: {
      warn80: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        contactEmails: [oncallEmail]
      }
      over100: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        contactEmails: [oncallEmail]
      }
    }
  }
}

// --- Cost-Cap as application-layer circuit breaker (pseudocode) ---
// if hourlyCost > threshold:
//   disableRagConnector('B')
//   throttleModel('gpt-4o-mini')
