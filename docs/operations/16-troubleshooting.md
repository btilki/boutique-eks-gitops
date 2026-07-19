# 16 — Troubleshooting

**Audience:** L3 — Operator  
**Applies to:** All  
**Prerequisites:** [08-health-checks](08-health-checks.md)  
**Estimated time:** 10–60 min  
**Risk level:** Low–Medium  

## Purpose

Route symptoms to the right runbook without duplicating long diagnostic trees.

## When to use / When not to use

**Use** at the start of any unclear failure.  
**Do not** invent parallel procedures that contradict [`docs/runbooks/`](../runbooks/).

## Prerequisites

- [ ] Health checks attempted

## Procedure

### Step 1: Symptom flowchart

```text
HTTPS / TLS / DNS / ALB failure?
  → docs/runbooks/ingress.md (+ 14-certificate-rotation)

Argo OutOfSync / Missing / Unknown?
  → docs/runbooks/argo-sync.md

Pod denied / ImagePull / policy message?
  → docs/runbooks/kyverno.md

Canary weights / dual pods stuck?
  → docs/runbooks/canary.md

No email / SMTP?
  → docs/runbooks/alerting.md (+ 15-secret-rotation)

Bad release after promote?
  → 03-rollback.md + docs/rollback.md

Node / OOM / TF lock / CrashLoop?
  → 17-common-incidents.md

Cluster must die (cost / unrecoverable)?
  → docs/runbooks/teardown.md
```

**Validation:** You opened exactly one primary runbook.

**Expected outcome:** Mitigate via that doc’s Validation section.

**Recovery steps:** Escalate SEV per [07](07-incident-response.md).

**Best practices:** Capture `kubectl describe` / Argo conditions before changing Git.

## End-to-end validation

Health checks green or incident ticket updated with next action.

## Rollback (section-level)

Whatever the child runbook specifies.

## Related alerts and dashboards

| Alert | Dashboard | Log query |
|-------|-----------|-----------|
| Any | Grafana | See [11](11-logging.md) |

## Security notes

Redact secrets from pasted logs.

## Automation opportunities

ChatOps “which guide?” mapper — future ([20](20-automation-opportunities.md)).
