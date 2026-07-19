# 08 — Health checks

**Audience:** L3 — Operator  
**Applies to:** All envs  
**Prerequisites:** kubectl, curl, AWS profile for this account  
**Estimated time:** 5–15 min  
**Risk level:** Low  

## Purpose

Confirm the control plane and storefronts are healthy before/after changes (morning check or post-promote).

## When to use / When not to use

**Use** after promote/sync, after incidents, or daily while the pilot runs.  
**Do not use** as a substitute for CI/Trivy gates.

## Prerequisites

- [ ] Correct kube context
- [ ] Network path to public hostnames

## Procedure

### Step 1: Cluster and nodes

**Commands:**

```bash
export AWS_PROFILE=<PROFILE> AWS_REGION=eu-central-1
kubectl get nodes -o wide
kubectl get --raw='/readyz?verbose' | head
```

**Validation:** All nodes `Ready`; apiserver readyz OK.

**Expected outcome:** 2–5 nodes Ready (ASG 2–5).

**Recovery steps:** See [17 — Node NotReady](17-common-incidents.md).

**Best practices:** Note instance types vs `docs/versions.md` (`m6i.large`).

### Step 2: Argo CD apps

**Commands:**

```bash
kubectl -n argocd get applications -o custom-columns=\
NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status | head -50
```

**Validation:** Critical apps `Healthy`. `frontend-prod` / `frontend-stage` may be `OutOfSync` but Healthy (canary Service/Ingress drift) — non-blocking if storefront 200.

**Expected outcome:** No Widespread `Degraded`/`Missing`.

**Recovery steps:** [runbooks/argo-sync](../runbooks/argo-sync.md).

### Step 3: Storefront HTTPS

**Commands:**

```bash
for h in dev-boutique stage-boutique boutique; do
  printf '%s ' "$h"
  curl -sI -o /dev/null -w '%{http_code}\n' --max-time 15 "https://${h}.biroltilki.art/"
done
```

**Validation:** HTTP **200** (or expected redirect then 200).

**Expected outcome:** All three succeed.

**Recovery steps:** [runbooks/ingress](../runbooks/ingress.md); confirm digests in Git.

### Step 4: Platform edge

**Commands:**

```bash
curl -sI -o /dev/null -w 'argocd=%{http_code}\n' --max-time 15 https://argocd.boutique.biroltilki.art/
curl -sI -o /dev/null -w 'grafana=%{http_code}\n' --max-time 15 https://grafana.boutique.biroltilki.art/
```

**Validation:** Argo/Grafana reachable (200/302).

**Recovery steps:** Ingress/DNS runbook; check ACM cert in AWS console.

### Step 5: Rollouts (if canary recently changed)

**Commands:**

```bash
kubectl -n stage get rollout frontend -o wide 2>/dev/null || true
kubectl -n prod get rollout frontend -o wide 2>/dev/null || true
```

**Validation:** `Healthy` (or expected `Paused` mid-canary).

**Recovery steps:** [runbooks/canary](../runbooks/canary.md).

## End-to-end validation

All steps green → safe to promote or leave idle briefly (still plan Topic 14).

## Rollback (section-level)

N/A (read-only checks).

## Related alerts and dashboards

| Alert | Dashboard | Log query |
|-------|-----------|-----------|
| BoutiqueIngressDown | Grafana | — |
| Node NotReady | Kubernetes / Nodes | — |

## Security notes

Health checks are read-only; use least-privilege IAM for humans.

## Automation opportunities

Bundle Steps 1–4 into a read-only `scripts/ops-status.sh` (document only — see [20](20-automation-opportunities.md)).
