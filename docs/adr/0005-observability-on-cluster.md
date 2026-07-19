# ADR-0005: On-cluster observability (no CloudWatch / PagerDuty / OTel in v1)

- **Status:** Accepted  
- **Date:** 2026-07-18  
- **Setup:** Topic 02  

## Context

The pilot needs metrics, logs, and alerting without multiplying AWS observability cost or introducing a paging vendor. Distributed tracing is valuable but out of scope for v1 depth on GitOps.

## Decision

- **Metrics / UI / alerts:** kube-prometheus-stack (Prometheus, Grafana, Alertmanager)
- **Logs:** Grafana Loki
- **Alert routing:** Alertmanager → **email** (SMTP credentials via ESO)
- **Out of v1:** CloudWatch, PagerDuty, OpenTelemetry / Tempo traces

## Consequences

- **Positive:** Cost control; portable dashboards; email proof for M2.
- **Negative:** Self-operated retention/capacity on `m6i.large` nodes; no distributed traces for deep latency debug.
- **Follow-up:** Topic 08 installs stack; runbook `docs/runbooks/alerting.md`.
