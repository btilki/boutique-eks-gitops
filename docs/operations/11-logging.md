# 11 — Logging

**Audience:** L3 — Operator  
**Applies to:** All namespaces  
**Prerequisites:** Grafana + Loki datasource  
**Estimated time:** 10 min  
**Risk level:** Low  

## Purpose

Query application and platform logs via Loki (on-cluster, short retention).

## When to use / When not to use

**Use** for CrashLoop, 5xx, SMTP/AM failures.  
**Do not** expect long retention or centralized SIEM — pilot retention ~7d.

## Prerequisites

- [ ] Grafana login
- [ ] Loki app Healthy in Argo

## Procedure

### Step 1: Explore logs

**GUI:** Grafana → Explore → Loki

**Example queries:**

```logql
{namespace="prod"} |= "error"
{namespace="prod", app="frontend"}
{namespace="monitoring"} |= "alertmanager"
```

**Validation:** Query returns recent lines for running pods.

**Expected outcome:** Logs visible within minutes of events.

**Recovery steps:** Check Promtail/Loki pods; PVC/`gp2` storage; re-sync Loki app.

**Best practices:** Avoid high-cardinality labels; prefer namespace + app.

## End-to-end validation

Generate a request to prod shop; see related frontend log lines.

## Rollback (section-level)

N/A.

## Related alerts and dashboards

| Alert | Dashboard | Log query |
|-------|-----------|-----------|
| — | Grafana Explore | `{namespace="prod"}` |

## Security notes

Logs may contain session cookies — do not export raw logs to public issues.

## Automation opportunities

Saved Grafana queries linked from [17](17-common-incidents.md).
