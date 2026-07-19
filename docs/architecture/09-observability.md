# 09 — Observability

## Scope (v1)

| Signal | Included | Tool |
|--------|----------|------|
| Metrics | Yes | Prometheus (kube-prometheus-stack) |
| Logs | Yes | Grafana Loki |
| Alerts | Yes | Alertmanager → **email** |
| Traces | **No** | OTel/Tempo deferred |
| CloudWatch | **No** | Cost |
| PagerDuty | **No** | Email instead |

## Metrics

| Source | What | Retention (target) |
|--------|------|-------------------|
| cAdvisor / kube-state-metrics | Cluster/pod health | 7–15 days |
| ServiceMonitors | Boutique + platform where useful | Same |
| Ingress / ALB metrics via exporters if enabled | 5xx, targets | Same |

**Guardrail:** Limit high-cardinality labels; set resource requests/limits on Prom/Loki.

## Logs

```text
Pods → Loki agent/daemonset or chart default → Loki → Grafana Explore
```

Retention ~**7 days** for pilot cost/disk.

## Alerting

| Alert | Severity | Destination | Why |
|-------|----------|-------------|-----|
| Shop / frontend ingress down (prod host) | Critical | Email via Alertmanager | User-facing availability |
| Optional: Argo app degraded | Warning | Email | GitOps health |

SMTP credentials via **ESO** from Secrets Manager — not in Git.

## Dashboards

| Dashboard | Audience |
|-----------|----------|
| Kubernetes cluster | Platform owner |
| Namespace / Boutique services | Platform owner |
| Argo CD (if packaged) | Platform owner |

Grafana: `grafana.boutique.biroltilki.art` (ACM+ALB).

## On-call (pilot)

- No PagerDuty rotation.
- Owner monitors email + Grafana.
- Runbook: `docs/runbooks/alerting.md` (authored Phase 6).

## Repo mapping

| Component | Path |
|-----------|------|
| Stack values / Apps | `gitops/platform/monitoring/` |
| Alerting runbook | `docs/runbooks/alerting.md` |
| Setup | `docs/setup/08-observability.md` |

## Honest gaps

- No distributed tracing → hard to debug deep checkout latency across services.
- Email alert fatigue / delay vs pages — acceptable for pilot.
- Observability stack sharing cluster with apps → noisy-neighbor risk (mitigate with limits).
