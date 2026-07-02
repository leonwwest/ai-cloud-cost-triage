# AI-Cloud Cost & Access Triage

> Mini-Portfolio-Stück — einseitiger Triage-Runbook für den Fall, dass ein interner AI-Agent plötzlich teurer wird und Antworten auf falsche Daten zugreifen.

**Szenario:** Ein Team nutzt einen internen AI-Agenten. Die Kosten steigen plötzlich und spürbar. Gleichzeitig greifen Antworten auf falsche / nicht autorisierte Datenquellen zu. Beide Symptome treten zeitgleich auf — typischerweise kein Zufall, sondern eine gemeinsame Ursache (z. B. fehlerhafter Datenquellen-Anschluss, falscher API-Key, leakender Prompt-Kontext, ausrollende RBAC-Änderung).

Diese Seite führt in **9 Schritten** vom Symptom zur Eskalation. Jeder Schritt: *was prüfen → konkrete Aktion → Indikator für "weiter" vs. "stopp".*

---

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

---

## 1 · Symptom — Beobachtung quantifizieren

**Was prüfen**
- Kosten-Delta: Tages-/Stundenschnitt vs. 7-Tage-Baseline (absolut und pro Aufruf).
- Antwortqualität: Welche Antworten greifen auf falsche Daten zu? Reproduzierbar?
- Zeitkorrelation: Wann begannen *beide* Symptome? Gemeinsamer Zeitpunkt = gemeinsame Ursache.

**Konkrete Aktion**
- Metriken-Plot der letzten 14 Tage: `cost/day`, `tokens/req`, `error_rate`, `data-source-mismatch`-Tickets.
- Beispiel-Queries des Agenten mit Bezug auf die falsche Datenquelle fixieren (Golden-Case).

> ⚠️ Stopp, falls: Kosten- und Qualitätssymptom zum selben Timestamp starten → behandeln als *ein* Incident, nicht zwei.

---

## 2 · User/Team — Betroffenheit & Verursacher

**Was prüfen**
- Welche Teams/User melden falsche Antworten? Konzentriert oder verteilt?
- Welcher Agent-Service / welche Deployment-Edition produziert die Kosten?
- Letzte Änderungen im Team: neues Feature-Rollout, neuer Datenkonnektor, Prompt-Änderung?

**Konkrete Aktion**
- Aufrufe nach `tenant/team/user_id` und `agent_version` gruppieren.
- Diff des letzten Deployments (Prompt-Template, Tool-/Function-Definitionen, Retrieval-Quellen).

> ⚠️ Stopp, falls: ein einzelner Service-Account oder eine `agent_version` dominiert → Ursache dort eingrenzen.

---

## 3 · Modell/API-Key — Welches Modell, welcher Key

**Was prüfen**
- Genutztes Modell: teureres Modell deployt? (z. B. `gpt-4o` statt `gpt-4o-mini`, `claude-opus` statt `sonnet`).
- API-Key-Herkunft: produktiver Key vs. Test-/Shared-Key? Rotationsdatum?
- Routing: Fallback auf teureres Modell bei Fehler? RAG-/Retrieval-Erweiterung aktiviert?

**Konkrete Aktion**
- Pro-Key: `requests`, `tokens_in/out`, `cost` der letzten 24 h aus Billing-/Usage-API.
- Key-Usage auf Anomalien prüfen (ungeklärte Nutzung = möglicher Leak).

> ⚠️ Stopp, falls: Key im Code/Logs/öffentlichen Repos auftaucht → **sofort rotieren**, Nutzung als möglichen Missbrauch behandeln.

---

## 4 · Tokenkosten — Wo entstehen die Tokens

**Was prüfen**
- Prompt-Tokens vs. Completion-Tokens. Hohe Prompt-Tokens = Kontext-/Retrieval-Blowup.
- System-Prompt-Größe pro Request; mitgelieferte Doku-/Tool-Definitionen.
- Schleifen / Retries: ruft der Agent das Modell mehrfach pro User-Task auf?

**Konkrete Aktion**
- Verteilung von `prompt_tokens` pro Request (P50/P95/P99). P95 >> P50 = Ausreißer-Requests.
- Top-10 Requests nach Token-Verbrauch inspizieren → oft 1–2 krasse Verursacher.
- Caching-Prüfung: ist Prompt-Caching aktiv für statische System-Prompts?

> ⚠️ Stopp, falls: Prompt-Tokens P95 plötzlich 5–10× höher → verdächtig auf angehängten Datenquellen-Kontext / Schleife.

---

## 5 · IAM/RBAC — Dürfen die Zugriffe sein

**Was prüfen**
- Unter welcher Identität liest der Agent Daten? Managed Identity / Service Principal / User?
- Verfügte Berechtigungen vs. benötigte (least privilege) — z. B. Storage-Blob-Reader vs. Contributor.
- Wer kann welche Datenquelle anbinden? Gibt es eine Allow-List der Tools/Datenquellen?

**Konkrete Aktion**
- Effective-Permissions des Agent-Principals für jede verknüpfte Datenquelle auslesen.
- Letzte RBAC-Änderungen am Principal / an den Datenquellen (Audit-Log).
- Hat der Agent Zugriff auf Datenquellen, die *nicht* zum beabsichtigten Scope gehören? → das erklärt "falsche Daten".

> ⚠️ Stopp, falls: Principal ist `Contributor`/`Owner` auf breitem Scope → Over-Privilegierung als wahrscheinliche Ursache für falsche Datenzugriffe.

---

## 6 · Private Endpoint / Netzwerk — Wer darf wohin sprechen

**Was prüfen**
- Spricht der Agent nur mit Allow-List-Endpunkten? (Private Endpoint, VNet/Subnet, Egress-Rules).
- Neue Datenquelle per Public-IP / nicht-privatem Endpunkt angebunden?
- DNS-Auflösung: löst der Datenquellen-Name auf den Private Endpoint oder öffentlich auf?

**Konkrete Aktion**
- Egress-/NSG-Flow-Logs der letzten 24 h prüfen → unerwartete Ziel-IPs/Domains.
- Verifizieren, dass jede genutzte Datenquelle über Private/Service Endpoint erreichbar ist.
- Falls RAG-Connector Public-Endpoint nutzt: Daten könnten von anderem Tenant/Workspace stammen.

> ⚠️ Stopp, falls: Agent erreicht Datenquellen außerhalb des definierten Netzwerk-Perimeters → mögliche Ursache für "falsche Daten" und unkontrollierte Abrufe.

---

## 7 · Logs / Traces — Was passierte wirklich

**Was prüfen**
- End-to-End-Trace eines fehlerhaften Requests: User → Agent → Retrieval → Datenquelle → Modell → Antwort.
- Wurden mehrere Datenquellen abgefragt? Welche Inhalte landeten im Prompt-Kontext?
- Tool-/Function-Call-Logs: welche Tools wurden mit welchen Argumenten gerufen?

**Konkrete Aktion**
- Distributed-Tracing (Trace-ID) für Beispiel-Fälle ziehen.
- Prompt-Kontext einer falschen Antwort rekonstruieren → welche Quellen wurden ins Prompt injiziert?
- Correlation-ID durch alle Hops verfolgen; fehlende Spans = Lücken in der Observability.

> ⚠️ Stopp, falls: Trace zeigt Retrieval aus nicht-erwarteter Datenquelle → beweist die Ursache für falsche Antworten; Fix in Schritt 5/6.

---

## 8 · Budget-Alert — Greift die Frühwarnung

**Was prüfen**
- Gab es einen Budget-/Anomalie-Alert? Wann hat er gefeuert?
- Wurde er ignoriert / nicht geroutet (E-Mail-Graben, Paging-Logik fehlt)?
- Schwellenwerte realistisch? Anomalie-Erkennung vs. fixer Threshold.

**Konkrete Aktion**
- Alert-Historie der letzten 14 Tage prüfen; Latenz zwischen Kostenereignis und Alert.
- Alerting auf `tokens/req`-P95 und `cost/hour` ergänzen (nicht nur `cost/day`).
- Ownership klären: Wem wird der Alert zugestellt? Runbook-Link im Alert ergänzen.

> ⚠️ Stopp, falls: Alert gefeuert, aber 6+ h unbearbeitet → Post-Incident auch Alerting-/On-Call-Prozess prüfen.

---

## 9 · Eskalation — Wer muss ran

**Was prüfen**
- Liegt ein Security-Verdacht vor (geleakter Key, Zugriff auf fremde Datenquelle, unautorisierte Egress)?
- Kostenschaden bisher (für Stakeholder-Kommunikation).
- Wer ist zuständig: Platform-Team, Security-Team, Daten-Owner, Product-Owner?

**Konkrete Aktion**
- Security-Verdacht → sofort IR-Workflow anstoßen, Key rotieren, Principal temp. sperren.
- Klarer Eskalationspfad: L1 (Platform/Dev) → L2 (Security) → L3 (Data Owner + Management).
- Stakeholder-Update: Symptom, Impact, laufende Hypothese, nächste Aktion, ETA.

> ⚠️ Stopp, falls: Security-Indizien (ungeklärte Key-Nutzung, Cross-Tenant-Zugriff) → **nicht** selbst weiter debuggen, sondern IR-Owner übergeben und Beweise sichern.

---

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
4. **Key rotieren** — bei minimalem Verdacht auf Leak, Aufwand ist gering, Wirkung hoch.
5. **Stakeholder-Briefing** — 1-Zeiler: "Kostenanomalie + Datenzugriffs-Problem, Untersuchung läuft, Cost-Cap aktiv."

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
