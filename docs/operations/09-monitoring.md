# 09 — Monitoring

**Audience:** L3 — Operator  
**Applies to:** Cluster-wide (`monitoring` ns)  
**Prerequisites:** Grafana admin password from Secret (rotated); kubectl  
**Estimated time:** 15 min  
**Risk level:** Low  

## Purpose

Use on-cluster Prometheus / Grafana / Loki to observe golden signals for Boutique and platform.

## When to use / When not to use

**Use** during incidents and after deploys.  
**Do not** expect CloudWatch/PagerDuty/OTel — out of v1 scope ([ADR-0005](../adr/0005-observability-on-cluster.md)).

## Prerequisites

- [ ] https://grafana.boutique.biroltilki.art reachable
- [ ] Know namespace labels: `dev` / `stage` / `prod` / `monitoring` / `argocd`

## Procedure

### Step 1: Open Grafana

**GUI:** Browser → `https://grafana.boutique.biroltilki.art` → login `admin` / password from:

```bash
kubectl -n monitoring get secret kube-prometheus-stack-grafana \
  -o jsonpath='{.data.admin-password}' | base64 -d; echo
```

**Validation:** Home dashboard loads.

**Expected outcome:** Datasources Prometheus + Loki present.

**Recovery steps:** Re-sync monitoring Argo app; [argo-sync](../runbooks/argo-sync.md).

**Best practices:** Rotate admin password after bootstrap; store in password manager — never Git.

### Step 2: Golden signals (frontend)

| Signal | Where to look |
|--------|----------------|
| Traffic | Ingress/ALB metrics if scraped; else curl success rate |
| Errors | Pod restarts; logs `{namespace="prod"} \|= "error"` |
| Latency | App metrics if exported; else synthetic curl timing |
| Saturation | `kubectl top nodes/pods`; node memory |

**Validation:** Can explain current prod frontend health in one sentence.

## End-to-end validation

Grafana + Prometheus targets UI show kubelet/cadvisor up.

## Rollback (section-level)

N/A (read-only).

## Related alerts and dashboards

| Alert | Dashboard | Log query |
|-------|-----------|-----------|
| BoutiqueIngressDown | Grafana Explore | `{namespace="prod"}` |

## Security notes

Grafana is public HTTPS — rotate admin; prefer SSO if keep-alive (not in pilot).

## Automation opportunities

Import a Boutique overview dashboard JSON under `gitops/platform/monitoring/` via GitOps.
