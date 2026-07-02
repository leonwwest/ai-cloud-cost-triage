# snippets/azure.sh - Azure CLI for the triage flow
# See: steps 2, 3, 5, 6, 8

# --- Cost & usage per API-Key / model (Cost Management) ---
az consumption usage list --top 50 \
  --query "[?contains(instanceName,'ai-agent')].{name:instanceName, cost:pretaxCost, date:usageStart}"

# --- Effective permissions of the agent principal on data sources ---
az role assignment list --assignee <agent-object-id> --all \
  --query "[].{role:roleDefinitionName, scope:scope}" -o table

# --- Last RBAC changes (Activity Log) ---
az monitor activity-log list --caller <agent-object-id> \
  --status Succeeded --resource-type "Microsoft.Authorization/roleAssignments"

# --- Private Endpoint connections of a Storage account ---
az storage account show --name <storage> --query "privateEndpointConnections"

# --- NSG flow logs: unexpected egress (last 24h) ---
az network watcher flow-log show --resource-group <rg> --network-watcher-name <watcher> \
  --query "flowAnalyticsConfiguration.networkWatcherFlowAnalyticsConfiguration"
