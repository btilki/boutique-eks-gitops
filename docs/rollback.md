# Rollback — Git revert of digest changes

**Audience:** L2 — Implementer / On-call  
**Setup:** Topic 11 · **ADR:** [0001](adr/0001-digest-only-gitops.md)  
**Related:** [promotion.md](promotion.md) · [runbooks/alerting.md](runbooks/alerting.md)

## Principle

Desired state lives in Git. Rollback = return previous digests via **`git revert`** (or a new MR that restores known-good digests). Argo reconciles. Do **not** `kubectl set image` or force-sync an unreproducible state.

## When to rollback

| Signal | Action |
|--------|--------|
| Stage unhealthy after promote | Revert stage digest MR; fix forward in dev |
| Prod unhealthy after manual sync | Revert prod digest MR; manual Argo sync again |
| Canary abort (Topic 12) | Revert digest MR and/or abort Rollout — prefer Git as source of truth; see [`docs/setup/12-canary-rollouts.md`](setup/12-canary-rollouts.md) Step 12.5 |

## Procedure — revert the bad promote MR

```bash
git fetch origin
git checkout -b rollback/$(date +%Y%m%d) origin/main

# Identify the promote commit / MR merge commit SHA
git log --oneline -- gitops/envs/stage/values gitops/envs/prod/values | head

# Revert the merge commit (use -m 1 for merge commits)
git revert -m 1 <MERGE_COMMIT_SHA>
# Or revert a single commit:
# git revert <COMMIT_SHA>

git push -u origin HEAD
# Open MR → main
# If prod paths touched: @btilki CODEOWNERS approval required
```

After merge:

| Env | Action |
|-----|--------|
| stage | Wait for Argo auto-sync; verify host |
| prod | **Manual** Argo sync of `*-prod` apps; verify `https://boutique.biroltilki.art` |

## Procedure — pin known-good digests (alternative)

If revert is messy (multiple commits), copy digests from a known-good env/commit:

```bash
# Example: restore prod frontend digest from git history
git show <GOOD_SHA>:gitops/envs/prod/values/frontend.yaml
# Then set that digest in a new MR (digest-only)
```

## Validation

```bash
# After Argo reconciles
kubectl -n stage get pods   # or prod
curl -I https://stage-boutique.biroltilki.art   # or boutique.biroltilki.art
argocd app list | grep -E 'stage|prod'
```

## What not to do

| Anti-pattern | Why |
|--------------|-----|
| `kubectl rollout undo` only | Drift from Git; next sync undoes you |
| Delete pods hoping for old image | Digests in Git still point at bad image |
| Force-push rewrite of `main` | Breaks audit trail; forbidden unless disaster recovery with explicit approval |
| CI hot-patch prod digests | Violates CI contract |

## Evidence

Keep the revert MR URL and post-sync curl output for Topic 13 / PRODUCTION_CHECKLIST.
