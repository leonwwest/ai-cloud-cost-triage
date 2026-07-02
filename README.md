# AI-Cloud Cost &amp; Access Triage

> Mini-Portfolio-Stück — einseitiger Triage-Runbook für den Fall, dass ein interner AI-Agent plötzlich teurer wird und Antworten auf falsche Daten zugreifen.

**Szenario:** Ein Team nutzt einen internen AI-Agenten. Die Kosten steigen plötzlich und spürbar. Gleichzeitig greifen Antworten auf falsche / nicht autorisierte Datenquellen zu. Beide Symptome zeitgleich = typischerweise eine gemeinsame Ursache (z. B. fehlerhafter Datenquellen-Anschluss, falscher API-Key, leakender Prompt-Kontext, ausrollende RBAC-Änderung).

Diese Seite führt in **9 Schritten** vom Symptom zur Eskalation. Jeder Schritt: *was prüfen → konkrete Aktion → Indikator für "weiter" vs. "stopp".*

---

## Ansehen

- **Live (GitHub Pages):** https://leonwwest.github.io/ai-cloud-cost-triage/
- **English:** https://leonwwest.github.io/ai-cloud-cost-triage/index.en.html
- Lokal: `index.html` im Browser öffnen (kein Build, keine Dependencies).

## Triage-Fluss

`Symptom → User/Team → Modell/API-Key → Tokenkosten → IAM/RBAC → Private Endpoint/Netzwerk → Logs/Traces → Budget-Alert → Eskalation`

| # | Schritt | Ziel | Stopp-Indikator |
|---|---------|------|-----------------|
| 1 | **Symptom** | Beobachtung quantifizieren | Kosten-/Qualitätsspikes korreliert? |
| 2 | **User/Team** | Wer ist betroffen, wer treibt es? | Einzelner User/Agent-Service? |
| 3 | **Modell/API-Key** | Welches Modell, welcher Key? | Key geteilt / geleakt? |
| 4 | **Tokenkosten** | Wo entstehen die Tokens? | Prompt-Size / Retrieval-Blowup? |
| 5 | **IAM/RBAC** | Dürfen die Zugriffe sein? | Over-privilegiertes Principal? |
| 6 | **Private Endpoint/Netzwerk** | Wer darf wohin sprechen? | Datenquelle außerhalb Allow-List? |
| 7 | **Logs/Traces** | Was passierte wirklich? | Trace zeigt Querkommunikation? |
| 8 | **Budget-Alert** | Greift die Frühwarnung? | Alert gefeuert / ignoriert? |
| 9 | **Eskalation** | Wer muss ran? | Security-Verdacht → IR weiterleiten |

Jeder Schritt mit *Was prüfen*, *Konkrete Aktion* und *Stopp-Indikator* → siehe Live-Seite.

## Was drin ist

| Inhalt | Wo |
|--------|-----|
| Triage-Runbook (9 Schritte, je Was prüfen / Aktion / Stopp) | `index.html`, `index.en.html` |
| Architektur-Diagramm (Agent-Flow + Kontrollpunkte) | Live-Sektion "Architektur" |
| Beispieldaten / Plots (Kosten-Spike, Token-P50/P95/P99) | Live-Sektion "Beispieldaten" |
| Metrics-Glossar (KPIs + Formeln) | Live-Sektion "Metrics" |
| Cloud-CLI/Query-Snippets (Azure/AWS/GCP/KQL) | Live-Sektion "CLI-Snippets" & `snippets/` |
| Budget-Alert as Code (Terraform + Bicep) | `infra/` & Live-Sektion "Budget as Code" |
| Worked Post-Mortem (Case #042 + Timeline) | Live-Sektion "Post-Mortem" |
| Druckbare Triage-Checkliste | Live-Sektion "Checkliste" |
| Entscheidungsbaum + Quick-Fixes + Ownership-Matrix | Live + unten |
| CI/CD-Deploy auf GitHub Pages | `.github/workflows/deploy.yml` |

## Repo-Struktur

```
ai-cloud-cost-triage/
├── index.html                 # Triage-Seite (deutsch, self-contained)
├── index.en.html              # English twin
├── README.md                  # diese Datei
├── .github/workflows/deploy.yml   # CI: HTML-Validate + Pages-Deploy
├── infra/
│   ├── budget.tf              # Terraform: Budget + Anomalie-Alert + Action-Group
│   └── budget.bicep           # Bicep-Äquivalent
└── snippets/
    ├── azure.sh               # Azure CLI (Kosten, RBAC, Private Endpoint, NSG)
    ├── azure.kql              # Log Analytics KQL (Token-Verteilung, Traces)
    ├── aws.sh                 # AWS (Cost Explorer, CloudWatch Insights, IAM)
    └── gcp.sh                 # GCP (Billing, BigQuery, Policy Analyzer, VPC)
```

## Entscheidungsbaum (Kurzform)

```
Kosten↑ & falsche Daten gleichzeitig?
├── ja → gemeinsame Ursache vermuten (Schritt 1)
│   ├── eine agent_version dominiert? → Diff Deployment (2)
│   ├── Key ungeklärt / leaked?       → rotieren, IR (3,9)
│   ├── Prompt-Tokens P95↑?           → Retrieval-/Schleifen-Fix (4)
│   ├── Principal over-privileged?    → RBAC eindämmen (5)
│   └── egress außerhalb Perimeter?   → Netzwerk-Fix (6)
└── nein → getrennte Incidents öffnen
```

## Quick-Fixes (erste Stunde)

1. **Cost-Cap setzen** — pro API-Key / pro Agent harte Token- & Kostenobergrenze (Circuit-Breaker).
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
