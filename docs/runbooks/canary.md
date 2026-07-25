# Runbook — Frontend canary abort / stuck

**Audience:** L2 — Operator  
**Setup:** Topic 12 · **Rollback:** [`../rollback.md`](../rollback.md)

## Purpose

Stop a bad frontend progressive delivery and return traffic to stable — with Git as lasting source of truth.

## Scope

| Env | Canary | Sync |
|-----|--------|------|
| `dev` | Off (Deployment) | Automated |
| `stage` | On (Rollout + ALB) | Automated |
| `prod` | On (Rollout + ALB) | **Manual** |

## Quick triage

```bash
NS=stage   # or prod
kubectl -n "$NS" get rollout frontend
kubectl -n "$NS" describe rollout frontend
kubectl argo rollouts get rollout frontend -n "$NS"   # optional plugin
kubectl -n "$NS" get svc,ingress | grep frontend
curl -I https://stage-boutique.biroltilki.art   # or boutique.biroltilki.art
```

## Abort (immediate)

```bash
NS=stage   # or prod
# Preferred (install kubectl-argo-rollouts plugin):
kubectl argo rollouts abort frontend -n "$NS"
```

Then **always** fix Git (lasting recovery):

```bash
# Prefer: git revert of the digest promote MR (see docs/rollback.md)
# Prod: after merge, manual Argo sync of prod apps
```

## Stuck progressing

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Paused by design | Timed `pause` step | Wait, or `kubectl argo rollouts promote frontend -n $NS` if healthy |
| ImagePullBackOff | Bad digest / ECR | Fix digest in Git; sync |
| 503 mid-canary | Canary targets unhealthy | Pods Ready? See [ingress.md](ingress.md) |
| Weights not changing | ALB trafficRouting / Ingress name | Confirm Rollout `trafficRouting.alb.ingress: frontend` |
| AnalysisRun Failed | Smoke/Prom gate (Topic 18) | `kubectl -n $NS get analysisrun`; fix URL/metrics or abort |
| Deployment + Rollout | Orphan Deployment | Delete leftover `deploy/frontend` once |

## Promote early (healthy)

```bash
kubectl argo rollouts promote frontend -n stage
```

Prefer completing timed steps for checklist evidence when safe.

## What not to do

| Anti-pattern | Why |
|--------------|-----|
| `kubectl set image` on canary RS | Drift; next sync fights you |
| Scale canary to 0 only | Git digest still bad; next promote repeats |
| Enable prod auto-sync to “finish” canary | Violates locked prod policy |

## Validation after recovery

```bash
kubectl -n "$NS" get rollout frontend
curl -fsS -o /dev/null -w "%{http_code}\n" "https://$( [ "$NS" = prod ] && echo boutique || echo ${NS}-boutique ).biroltilki.art"
# Confirm Git digests match what you intend
```

## Related

- Setup: [`../setup/12-canary-rollouts.md`](../setup/12-canary-rollouts.md) · [`../setup/18-canary-analysis.md`](../setup/18-canary-analysis.md)
- Argo sync: [`argo-sync.md`](argo-sync.md)
- Ingress: [`ingress.md`](ingress.md)
