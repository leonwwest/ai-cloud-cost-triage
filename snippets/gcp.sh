# snippets/gcp.sh - GCP CLI for the triage flow
# See: steps 1, 3, 4, 5

# --- Billing accounts ---
gcloud billing accounts list
gcloud alpha billing accounts describe <ACCOUNT> --format="value(displayName)"

# --- BigQuery: token cost export aggregated per request ---
bq query --use_legacy_sql=false '
  SELECT agent_version,
         APPROX_QUANTILES(prompt_tokens, 100)[OFFSET(95)] AS p95,
         APPROX_QUANTILES(prompt_tokens, 100)[OFFSET(99)] AS p99,
         SUM(cost) AS cost
  FROM `proj.ai.token_usage`
  WHERE _PARTITIONDATE >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
  GROUP BY agent_version
  ORDER BY cost DESC'

# --- IAM: effective permissions via Policy Analyzer ---
gcloud asset analyze-iam-policy --full-resource-name=<RESOURCE> \
  --permissions="storage.objects.get" --format=json

# --- VPC: firewall rules allowing egress to 0.0.0.0/0 ---
gcloud compute firewall-rules list \
  --filter="direction:EGRESS AND targetTags:ai-agent" --format="table(name,destinationRanges,allowed[])"
