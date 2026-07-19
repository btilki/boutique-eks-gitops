# 02 — Deployment

**Audience:** L3 — Operator / release owner  
**Applies to:** `dev` → `stage` → `prod`  
**Prerequisites:** Maintainer on GitLab; `@btilki` for prod; yq; kubectl  
**Estimated time:** 30–90 min  
**Risk level:** Medium (prod High)  

## Purpose

Promote **digest-only** releases via Git so Argo reconciles the desired state.

## When to use / When not to use

**Use** after CI merged digests to `gitops/envs/dev/**` and stage validation passed.  
**Do not** `kubectl set image` or edit live Rollouts as the release mechanism.

## Prerequisites

- [ ] [docs/promotion.md](../promotion.md) read
- [ ] Stage healthy ([08](08-health-checks.md))
- [ ] Prod: CODEOWNERS + manual sync understood

## Procedure

### Step 1: Promote digests

Follow **[docs/promotion.md](../promotion.md)** exactly (`dev→stage`, then `stage→prod` with `@btilki`).

**Commands:** (canonical copy loop in promotion.md)

**Validation:** MR shows **only** `image.digest` diffs under `gitops/envs/<env>/values/`.

**Expected outcome:** MR merged to `main`.

**Recovery steps:** Close MR; do not force-push `main`.

**Best practices:** One env per MR; never skip stage on the happy path.

### Step 2: Argo sync

| Env | Action |
|-----|--------|
| stage | Wait for auto-sync + canary pauses |
| prod | **Manual** sync `*-prod` (especially `frontend-prod`) — [argo-sync](../runbooks/argo-sync.md) |

**Validation:** Rollout progresses; curl storefront 200.

**Expected outcome:** Prod serving new digest after canary completes.

**Recovery steps:** [03-rollback](03-rollback.md); [canary](../runbooks/canary.md).

## End-to-end validation

```bash
# Compare Git digest to running image
yq '.image.digest' gitops/envs/prod/values/frontend.yaml
kubectl -n prod get pods -l app=frontend -o jsonpath='{.items[0].spec.containers[0].image}{"\n"}'
```

## Rollback (section-level)

Mandatory: [03-rollback](03-rollback.md) / [docs/rollback.md](../rollback.md).

## Related alerts and dashboards

| Alert | Dashboard | Log query |
|-------|-----------|-----------|
| BoutiqueIngressDown | Grafana | `{namespace="prod"}` |

## Security notes

Prod path requires human CODEOWNERS approval; CI cannot write prod digests.

## Automation opportunities

Promote script that only copies digests + opens MR — still requires human merge.
