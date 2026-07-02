# infra/budget.tf - Budget + Anomaly Alert + Action Group (Azure)
# Shows IaC for the "Budget-Alert" step (8) of the triage flow.

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "law_id" {
  description = "Resource ID of the Log Analytics Workspace used for cost/hour anomaly alert"
  type        = string
}

resource "azurerm_resource_group" "ai" {
  name     = "rg-ai-agent"
  location = var.location
}

# --- Action Group: routes alerts to the on-call channel ---
resource "azurerm_monitor_action_group" "oncall" {
  name                = "ag-ai-oncall"
  resource_group_name = azurerm_resource_group.ai.name
  short_name          = "aiOnCall"

  email_receiver {
    name          = "platform"
    email_address = "platform-oncall@example.com"
  }
}

# --- Monthly budget with two thresholds (80% warn, 100% over) ---
resource "azurerm_consumption_budget_resource_group" "agent" {
  name              = "budget-ai-agent"
  resource_group_id = azurerm_resource_group.ai.id
  amount            = 500 # EUR / month
  time_grain        = "Monthly"

  time_period {
    start_date = "2026-07-01T00:00:00Z"
    end_date   = "2027-07-01T00:00:00Z"
  }

  filter {
    tag {
      name   = "agent_version"
      values = ["prod"]
    }
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    contact_groups = [azurerm_monitor_action_group.oncall.id]
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    contact_groups = [azurerm_monitor_action_group.oncall.id]
  }
}

# --- Anomaly alert on cost/hour (faster than daily threshold) ---
resource "azurerm_monitor_scheduled_query_rules_alert" "cost_spike" {
  name                = "alert-ai-cost-spike"
  resource_group_name = azurerm_resource_group.ai.name
  location            = azurerm_resource_group.ai.location
  severity            = 2
  frequency           = 5
  time_window         = 15
  data_source_id      = var.law_id

  query = <<QUERY
AIAgentLLMCall
| summarize cost = sum(todouble(cost)) by bin(1h)
| where cost > 20   // EUR/h threshold
QUERY

  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }

  action {
    action_groups = [azurerm_monitor_action_group.oncall.id]
  }
}
