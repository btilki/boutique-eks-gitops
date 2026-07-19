# Monitoring stack — Prometheus / Grafana / Alertmanager / Loki

**Setup:** Topic 08 · **Milestone M2** (with Topics 06–07)  
**Pins:** kube-prometheus-stack **69.8.0** · Loki chart **6.24.0**

## Layout

| Path | Purpose |
|------|---------|
| `values-kube-prometheus.yaml` | Prom / AM / Grafana (+ Ingress) |
| `loki/values.yaml` | Loki SingleBinary |
| `manifests/externalsecret-smtp.yaml` | SMTP password via ESO |
| `manifests/prometheusrule-boutique.yaml` | Email test + critical rule stub |

## Hosts

- Grafana: `https://grafana.boutique.biroltilki.art`
- Alerts: Alertmanager → **email** (ADR-0005)

## Sync

- Helm apps: `kube-prometheus-stack`, `loki` via `platform-apps` (wave 30)
- Manifests: `monitoring-config` via `platform-manifests` (wave 31)

## Runbook

[`docs/runbooks/alerting.md`](../../../docs/runbooks/alerting.md)
