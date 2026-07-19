# Runbook — Argo CD sync stuck / OutOfSync

**Audience:** L2 — Operator  
**Setup:** Topic 06 · **GitOps:** [`../../gitops/README.md`](../../gitops/README.md)

## Purpose

Restore Git → cluster reconciliation without bypassing Git as source of truth.

## Hard rules

| Do | Do not |
|----|--------|
| Fix Git, then sync | `kubectl apply` permanent fixes that drift from Git |
| Manual sync **prod** only when intended | Enable automated sync on prod “temporarily” |
| Read Application conditions / events | Force replace without understanding hooks/waves |

## Quick triage

```bash
argocd app list --grpc-web
argocd app get <APP> --grpc-web
kubectl -n argocd get applications
kubectl -n argocd logs -l app.kubernetes.io/name=argocd-application-controller --tail=100
```

## Checks (in order)

| # | Check | Action |
|---|--------|--------|
| 1 | Repo reachable | Application `spec.source(s)` repoURL; GitLab token/SSH |
| 2 | Path / chart exists | Confirm `path` or Helm multi-source values ref |
| 3 | Sync wave order | Platform waves before workloads; wait for prior apps Healthy |
| 4 | Diff reason | Argo UI DIFF — placeholders left? CRD missing? |
| 5 | Prod policy | Prod apps: **no** automated sync — click SYNC or `argocd app sync` |
| 6 | Finalizers / prune | Stuck deleting? Check resource finalizers |

## Prod-specific

```bash
# After CODEOWNERS-approved digest MR merges to main:
argocd app sync <boutique-*-prod> --grpc-web
# Confirm syncPolicy still lacks automated:
argocd app get <boutique-*-prod> -o yaml | grep -A8 syncPolicy
```

## Common fixes

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| ComparisonError | Bad repo / credentials | Fix repo secret; refresh |
| Sync failed / blocked | Kyverno deny | See [kyverno.md](kyverno.md) |
| Progressing forever | Rollout pause / PVC | See [canary.md](canary.md); pod events |
| Always OutOfSync | Server-side drift / ignoreDifferences needed | Prefer fix desired state in Git |
| Root app empty | App-of-apps path wrong | Fix `gitops/bootstrap/root/` |

## Recovery

1. Identify failing resource in Argo UI.
2. Commit fix to Git (digest, values, manifest).
3. Refresh + sync (manual for prod).
4. If emergency only: temporary ignore + follow-up MR same day.

## Related

- Setup: [`../setup/06-argocd-bootstrap.md`](../setup/06-argocd-bootstrap.md)
- Rollback: [`../rollback.md`](../rollback.md)
