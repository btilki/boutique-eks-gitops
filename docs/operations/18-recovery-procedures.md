# 18 — Recovery procedures

**Audience:** L3 — Operator  
**Applies to:** Major failure classes  
**Prerequisites:** [07](07-incident-response.md), [17](17-common-incidents.md)  
**Estimated time:** 30 min – hours  
**Risk level:** High  

## Purpose

Ordered recovery sequences when multiple systems fail together.

## When to use / When not to use

**Use** for SEV-1 cascades.  
**Do not** skip health validation between layers.

## Prerequisites

- [ ] Incident SEV assigned
- [ ] Prefer rollback over rebuild when Git is healthy

## Procedure

### Step 1: Edge (DNS / TLS / ALB)

Restore public HTTPS ([ingress](../runbooks/ingress.md), [14](14-certificate-rotation.md)).

**Validation:** `curl -I https://boutique.biroltilki.art` → 200/302.

### Step 2: GitOps control plane

Argo API/UI healthy; root app syncing ([argo-sync](../runbooks/argo-sync.md)).

**Validation:** `kubectl -n argocd get app | head`

### Step 3: Application desired state

Ensure Git digests are known-good ([03](03-rollback.md)); sync prod manually.

**Validation:** Pods Running; Rollout Healthy.

### Step 4: Data plane capacity

Nodes Ready; Pending cleared ([04](04-scaling.md), [17](17-common-incidents.md) D/E).

### Step 5: Observability

AM/Grafana up so you are not flying blind ([09](09-monitoring.md), [10](10-alerting.md)).

### Step 6: If irreparable

[Teardown](../runbooks/teardown.md) → optional [05-DR rebuild](05-disaster-recovery.md).

## End-to-end validation

Full [08-health-checks](08-health-checks.md) pass.

## Rollback (section-level)

Stop mid-sequence if a step worsens blast radius; document and reassess SEV.

## Related alerts and dashboards

| Alert | Dashboard | Log query |
|-------|-----------|-----------|
| Multiple critical | Grafana | — |

## Security notes

During recovery, do not temporarily grant CI `eks:*`.

## Automation opportunities

None that replace this checklist.
