# AI-Cloud Cost &amp; Access Triage

> Mini-Portfolio-Stück — einseitiger Triage-Runbook für den Fall, dass ein interner AI-Agent plötzlich teurer wird und Antworten auf falsche Daten zugreifen.

[![CI &amp; Deploy](https://github.com/leonwwest/ai-cloud-cost-triage/actions/workflows/deploy.yml/badge.svg)](https://github.com/leonwwest/ai-cloud-cost-triage/actions/workflows/deploy.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**Szenario:** Ein Team nutzt einen internen AI-Agenten. Die Kosten steigen plötzlich und spürbar. Gleichzeitig greifen Antworten auf falsche / nicht autorisierte Datenquellen zu. Beide Symptome zeitgleich = typischerweise eine gemeinsame Ursache (z. B. fehlerhafter Datenquellen-Anschluss, falscher API-Key, leakender Prompt-Kontext, ausrollende RBAC-Änderung).

Diese Seite führt in **9 Schritten** vom Symptom zur Eskalation. Jeder Schritt: *was prüfen → konkrete Aktion → Indikator für „weiter" vs. „stopp".*

---

## Ansehen

- **Live (GitHub Pages):** https://leonwwest.github.io/ai-cloud-cost-triage/
- **English:** https://leonwwest.github.io/ai-cloud-cost-triage/index.en.html
- Lokal: `index.html` im Browser öffnen (kein Build, keine Dependencies) — oder `node scripts/build-plots.mjs` für frische Plots.

## Was dieses Stück demonstriert

Multi-Cloud (Azure/AWS/GCP) · IAM &amp; Least-Privilege · Infrastructure as Code (Terraform/Bicep) · Observability (KQL/CloudWatch/Tracing) · FinOps &amp; Cost Engineering · Incident Response &amp; Post-Mortem · CI/CD &amp; SRE · Accessibility (ARIA-Tabs, Keyboard-Navi, SVG-Titel).

## Triage-Fluss

`Symptom → User/Team → Modell/API-Key → Tokenkosten → IAM/RBAC → Private Endpoint/Netzwerk → Logs/Traces → Budget-Alert → Eskalation`

Jeder Schritt mit *Was prüfen*, *Konkrete Aktion* und *Stopp-Indikator* → siehe Live-Seite. Plus: Architektur-Diagramm, Beispieldaten/Plots, Metrics-Glossar, Cloud-CLI-Snippets, Budget-as-Code, Prevention-Guardrails, zwei Post-Mortems (Case #042 &amp; #051), Framework-Mapping (SRE/NIST), druckbare Checkliste.

## Repo-Struktur

```
ai-cloud-cost-triage/
├── index.html                     # Triage-Seite (DE, self-contained, dark/light toggle)
├── index.en.html                  # English twin
├── README.md                      # diese Datei
├── LICENSE                        # MIT
├── .htmlhintrc                    # HTML-Validation-Config
├── .lighthouserc.json             # Lighthouse-Budgets (A11y ≥0,9 error, andere warn)
├── .github/workflows/deploy.yml   # CI: HTMLHint + Plot-Drift + Lychee + Lighthouse + Pages-Deploy
├── assets/
│   ├── cost-plot.svg              # generiert von scripts/build-plots.mjs
│   ├── token-plot.svg             # generiert
│   ├── favicon.svg
│   └── og-image.png               # 1200x630 Open-Graph-Preview
├── data/
│   └── triage-data.json           # Quelle für die Plots (fiktive, typische Verläufe)
├── scripts/
│   └── build-plots.mjs            # data → assets/*.svg (CI prüft auf Drift)
├── infra/
│   ├── budget.tf                  # Terraform: Budget + Anomalie-Alert + Action-Group
│   └── budget.bicep               # Bicep-Äquivalent
└── snippets/
    ├── azure.sh                   # Azure CLI (Kosten, RBAC, Private Endpoint, NSG)
    ├── azure.kql                  # Log Analytics KQL (Token-Verteilung, Traces)
    ├── aws.sh                     # AWS (Cost Explorer, CloudWatch Insights, IAM)
    └── gcp.sh                     # GCP (Billing, BigQuery, Policy Analyzer, VPC)
```

## CI

`deploy.yml` läuft bei Push/PR auf `main` und bei `workflow_dispatch`:

1. **validate** — `node scripts/build-plots.mjs` + Drift-Check (assets müssen committed data entsprechen) + HTMLHint (blocking).
2. **links** — Lychee prüft alle Links in HTML &amp; MD (non-blocking).
3. **lighthouse** — LHCI mit Budgets (Accessibility ≥ 0,9 = error; Performance/SEO/Best-Practices = warn) (non-blocking, Report als Artifact).
4. **build** — Pages-Artifact bauen (nach validem validate).
5. **deploy** — auf GitHub Pages (nur auf `main`).

## Quick-Fixes (erste Stunde)

1. **Cost-Cap setzen** — pro API-Key / pro Agent harte Token- &amp; Kostenobergrenze (Circuit-Breaker).
2. **Rate-Limit drosseln** — bis Ursache klar ist, Agent-Durchsatz begrenzen.
3. **Falsche-Daten-Source togglen** — betroffenen Datenquellen-Konnektor deaktivieren / auf Allow-List setzen.
4. **Key rotieren** — bei minimalem Verdacht auf Leak, Aufwand gering, Wirkung hoch.
5. **Stakeholder-Briefing** — 1-Zeiler: „Kostenanomalie + Datenzugriffs-Problem, Untersuchung läuft, Cost-Cap aktiv."

## Ownership-Matrix

| Bereich | Owner | Benachrichtigt bei |
|---------|-------|-------------------|
| Agent-Plattform / Modell-Routing | Platform-Team | Kosten↑, Modell-Wechsel |
| API-Keys / Secrets | Platform + Security | ungeklärte Key-Nutzung |
| Datenquellen / RAG | Data-Owner | falsche Datenzugriffe |
| IAM / RBAC | Identity-Team | Over-Privilegierung |
| Netzwerk / Private Endpoints | Network-Team | Egress-Anomalie |
| Budget / Alerting | FinOps | Alert gefeuert |
| Security / IR | Security-Team | Leak-Verdacht, Cross-Tenant |

---

## Lizenz

MIT — frei verwendbar als Portfolio-Beispiel. Keine Garantie für Produktivnutzung.
