# snippets/aws.sh - AWS CLI for the triage flow
# See: steps 1, 3, 4, 5

# --- Cost Explorer: daily cost per agent_version tag + service ---
aws ce get-cost-and-usage \
  --time-period Start=2026-06-01,End=2026-07-02 \
  --granularity DAILY --metrics "UnblendedCost" \
  --group-by Type=TAG,Key=agent_version Type=SERVICE

# --- CloudWatch Logs Insights: token distribution per request ---
# (Start a query, then use start-query-result to poll)
aws logs start-query --log-group-name /ai/agent \
  --start-time $(date -d '7 days ago' +%s) --end-time $(date +%s) \
  --query-string 'filter event="llm_call"
  | stats pct(prompt_tokens,95) as p95, pct(prompt_tokens,99) as p99 by bin(1h)'

# --- IAM: list policies attached to the agent service role ---
aws iam list-attached-role-policies --role-name AgentServiceRole
aws iam get-role --role-name AgentServiceRole --query "Role.MaxSessionDuration"

# --- VPC flow logs: unexpected egress (CloudWatch Logs Insights) ---
aws logs start-query --log-group-name /vpc/flowlogs \
  --start-time $(date -d '1 days ago' +%s) --end-time $(date +%s) \
  --query-string 'filter action="ACCEPT" and dstAddr not in ["10.0.0.0/8"]
  | stats count(*) by dstAddr, dstPort | sort @count desc | limit 20'
