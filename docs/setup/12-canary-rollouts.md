# 12 — Canary rollouts

Audience: L2 — Implementer  
Estimated time: 1.5–2.5 hours  
Prerequisites: [11 — Promotion](11-promotion.md) complete (stage/prod digests promotable)  
Creates: [`gitops/platform/argo-rollouts/`](../../gitops/platform/argo-rollouts/), frontend `Rollout` + ALB services, stage/prod canary values  
Related: [deployment flow](../architecture/05-deployment-flow.md) · [rollback.md](../rollback.md) · FR-09  
**Pin:** Argo Rollouts **v1.8.2** · Helm chart **2.39.5** ([`docs/versions.md`](../versions.md))

---

## Topic goal

Install Argo Rollouts and run **frontend** progressive delivery with **ALB traffic splitting** on **stage and prod** (dev stays Deployment).

## Why this topic is required

FR-09 requires canary on stage **and** prod. Without Rollouts + ALB weights, digest promotes are all-or-nothing cutovers.

## Before you begin

- Topics 09–11 complete: Boutique charts synced; promotion/CODEOWNERS working; prod **manual** sync discipline.
- AWS LB Controller healthy (Topic 05); Ingress `target-type: ip` already set on frontend.
- Phase B Topic 12 files on `main` (this guide + repo files).
- Optional: install `kubectl-argo-rollouts` plugin for status/abort UX.

**Cost:** Brief extra canary pods during weight steps; controller footprint is small.

**Idempotent:** Re-sync Rollouts app safe. Switching Deployment → Rollout once may require pruning the old Deployment (Step 12.2).

---

## Step 12.1: Sync Argo Rollouts controller

### Goal

Install the Rollouts controller (CRDs + controller) via ApplicationSet wave **25**.

### Why this step is required

`Rollout` CRDs must exist before stage/prod frontend charts render `kind: Rollout`.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"

# Confirm AppSet lists argo-rollouts
grep -A6 'name: argo-rollouts' gitops/apps/platform-apps/applicationset.yaml

# After merge to main (or force refresh):
argocd app sync argo-rollouts --grpc-web
kubectl -n argo-rollouts get deploy,pods
kubectl get crd rollouts.argoproj.io
```

Expected duration: 1–3 minutes.

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | Argo CD UI |
| Navigation | Application **argo-rollouts** → SYNC if needed |
| Verification | Healthy; pods Ready in `argo-rollouts` |

### Expected output

Controller Ready; `rollouts.argoproj.io` CRD present.

### Validation

```bash
kubectl -n argo-rollouts rollout status deploy/argo-rollouts --timeout=180s
kubectl api-resources | grep -E 'rollout|analysis'
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| App missing | AppSet not refreshed | Sync root / `platform-apps` ApplicationSet |
| Chart pull fail | Repo URL / network | Confirm `https://argoproj.github.io/argo-helm` reachable from cluster |
| CRD conflict | Prior manual install | Align to chart `installCRDs: true` or adopt existing CRDs carefully |

### Recovery

Fix values or AppSet pin; re-sync `argo-rollouts`.

### Best practices

Leave dashboard disabled for the pilot (values already set).

### Security notes

Controller needs cluster RBAC to manage ReplicaSets/Services/Ingress annotations — use the chart defaults; do not widen unnecessarily.

---

## Step 12.2: Frontend Rollout + ALB wiring

### Goal

Confirm the frontend chart emits a `Rollout` (not `Deployment`) when `canary.enabled: true`, with stable / canary / root Services and Ingress `use-annotation` backend.

### Why this step is required

ALB canary requires Rollouts to own weighted target groups via Ingress action annotations.

### Commands

```bash
# Template check (no cluster required)
helm template frontend charts/frontend \
  -f gitops/envs/stage/values/frontend.yaml \
  | grep -E 'kind: (Rollout|Deployment|Service|Ingress)'

# Expect: Rollout, three Services (frontend, frontend-canary, frontend-root), Ingress
# Dev must still be Deployment:
helm template frontend charts/frontend \
  -f gitops/envs/dev/values/frontend.yaml \
  | grep -E 'kind: (Rollout|Deployment)'
```

### Migration note (first enable on a live env)

If stage/prod already have a `Deployment/frontend`, the chart stops rendering it when canary is enabled. Allow Argo prune **or** delete once after sync:

```bash
# Only if the old Deployment remains after first canary sync
kubectl -n stage get deploy frontend 2>/dev/null && \
  kubectl -n stage delete deploy frontend --wait=false
# Repeat for prod after manual sync if needed
```

Prefer letting Argo prune when the Application has `prune: true`.

### GUI instructions (if applicable)

N/A for template check; Argo UI shows frontend app resources after sync.

### Expected output

Stage/prod values set `canary.enabled: true`; chart templates include `rollout.yaml` + ALB root Ingress path.

### Validation

```bash
test -f charts/frontend/templates/rollout.yaml
grep -q 'canary.enabled' charts/frontend/templates/rollout.yaml
grep -q 'use-annotation' charts/frontend/templates/ingress.yaml
grep -q 'enabled: true' gitops/envs/stage/values/frontend.yaml
grep -q 'enabled: true' gitops/envs/prod/values/frontend.yaml
grep -q 'enabled: false' gitops/envs/dev/values/frontend.yaml
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Still Deployment on stage | Overlay not merged / wrong values file | Confirm ApplicationSet valueFiles include env overlay |
| Ingress 503 | Root service / action annotation missing | Confirm Rollouts patched `alb.ingress.kubernetes.io/actions.frontend-root` |
| Two controllers fighting | Deployment + Rollout both exist | Delete leftover Deployment |

### Recovery

Set `canary.enabled: false` temporarily to restore Deployment path; fix wiring; re-enable.

### Best practices

Keep service port **8080** consistent across stable/canary/root and Rollout `servicePort`.

### Security notes

Kyverno digest policies still apply to Rollout pods — images remain `repository@digest`.

---

## Step 12.3: Enable and observe canary on stage

### Goal

Sync stage frontend; trigger a digest change (or promote) and watch canary weights progress.

### Why this step is required

Prove ALB weight steps before touching prod.

### Commands

```bash
# After chart+values on main — stage auto-syncs
argocd app get boutique-frontend-stage --grpc-web   # name may vary; use: argocd app list | grep stage

kubectl -n stage get rollout,svc,ingress
kubectl -n stage describe rollout frontend

# Optional plugin:
kubectl argo rollouts get rollout frontend -n stage
kubectl argo rollouts status frontend -n stage

# During a digest change, watch weights:
watch -n5 'kubectl -n stage get rollout frontend -o jsonpath="{.status.canary.weights}" ; echo'

curl -I https://stage-boutique.biroltilki.art
```

To **exercise** canary without a full CI cycle: open a promote MR that changes **only** `image.digest` under `gitops/envs/stage/values/frontend.yaml` to a known-good newer digest (Topic 11 rules).

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | Argo CD UI |
| Navigation | Stage frontend Application → Healthy; Events |
| Verification | HTTPS storefront still responds during pauses |

### Expected output

Rollout progresses through `setWeight` steps (20 → 50 → 100 on stage) with pauses; host remains healthy.

### Validation

```bash
kubectl -n stage get rollout frontend -o wide
kubectl -n stage get pods -l app=frontend
curl -fsS -o /dev/null -w "%{http_code}\n" https://stage-boutique.biroltilki.art
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Stuck in Progressing | Image pull / readiness | Check events; digest/ECR |
| Weights never change | ALB trafficRouting misconfig | Verify Ingress name matches Rollout; root service + action |
| Pause forever | Step is bare `pause: {}` | Our values use timed pauses; promote if someone removed duration |

### Recovery

```bash
kubectl argo rollouts abort frontend -n stage
# Then git revert the digest MR (preferred) — see Step 12.5
```

### Best practices

Observe at least one full canary on stage before prod MR.

### Security notes

Stage is still non-prod — use it to validate Kyverno + Rollouts coexistence.

---

## Step 12.4: Enable canary on prod (manual sync)

### Goal

Apply prod frontend Rollout/canary via **manual** Argo sync after CODEOWNERS-approved MR.

### Why this step is required

FR-09 includes prod; prod must not auto-reconcile (locked sync policy).

### Commands

```bash
# 1) Merge chart + prod canary values (CODEOWNERS if touching gitops/envs/prod/**)
# 2) Manual sync ONLY for prod frontend (and siblings if needed)
argocd app sync boutique-frontend-prod --grpc-web   # adjust name via: argocd app list | grep prod

kubectl -n prod get rollout,svc,ingress
kubectl argo rollouts get rollout frontend -n prod

# Trigger canary by merging a digest promote MR (stage → prod), then manual sync again
curl -I https://boutique.biroltilki.art
```

Prod canary steps are slower/safer (10 → 30 → 50 → 100 with 120s pauses) than stage.

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | Argo CD UI |
| Navigation | Prod frontend Application → **SYNC** (manual) |
| Verification | Rollout Progressing → Healthy; shop HTTPS OK |

### Expected output

Prod Rollout exists; canary runs only after manual sync of a digest change; full weight reaches stable.

### Validation

```bash
kubectl -n prod get rollout frontend
curl -fsS -o /dev/null -w "%{http_code}\n" https://boutique.biroltilki.art
# Confirm Application still has no automated sync:
argocd app get boutique-frontend-prod -o yaml | grep -A5 syncPolicy || true
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Nothing happens after MR | Forgot manual sync | Sync prod app in UI/CLI |
| Auto-synced unexpectedly | Wrong Application syncPolicy | Fix workload AppSet — prod must stay manual |

### Recovery

Abort Rollout + `git revert` digest MR + manual sync (Step 12.5).

### Best practices

Watch the first prod canary live; do not leave mid-canary overnight without a plan.

### Security notes

CODEOWNERS `@btilki` still gates prod path merges — canary does not bypass review.

---

## Step 12.5: Abort and promote recovery path

### Goal

Document and practice abort: prefer **Git revert** of the digest; optionally abort the Rollout immediately.

### Why this step is required

Bad canaries must return to stable without `kubectl set image`.

### Commands

```bash
# Immediate stop of progressive delivery (cluster):
kubectl argo rollouts abort frontend -n stage   # or -n prod

# Source of truth (required for lasting fix):
# Follow docs/rollback.md — git revert the digest MR, merge, then:
#   stage: wait for auto-sync
#   prod:  manual Argo sync

kubectl argo rollouts status frontend -n stage
```

Promote (finish early) if healthy:

```bash
kubectl argo rollouts promote frontend -n stage
```

Prefer letting timed steps complete for the pilot evidence path.

### GUI instructions (if applicable)

N/A — CLI abort + GitLab revert MR.

### Expected output

Traffic returns to previous stable ReplicaSet; Git digests match what Argo serves after sync.

### Validation

```bash
grep -q 'Canary abort' docs/rollback.md
test -f docs/rollback.md
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Abort then sync re-triggers bad canary | Git still has bad digest | Revert/fix digests in Git first |
| Drift | Manual kubectl image change | Undo; fix via Git only |

### Recovery

Known-good digest pin MR (see [`docs/rollback.md`](../rollback.md)).

### Best practices

Treat abort as emergency; always close the loop with a Git change.

### Security notes

Prod revert MRs still need CODEOWNERS when touching `gitops/envs/prod/**`.

---

## Step 12.6: Topic validation (gate to Topic 13)

### Goal

Prove FR-09: Rollouts installed; stage **and** prod frontend canaries observed; abort path known.

### Why this step is required

Topic 13 production checklist assumes canary evidence exists.

### Commands

```bash
kubectl -n argo-rollouts get deploy
kubectl -n stage get rollout frontend
kubectl -n prod get rollout frontend
curl -I https://stage-boutique.biroltilki.art
curl -I https://boutique.biroltilki.art

# Chart contract
test -f charts/frontend/templates/rollout.yaml
grep -q 'enabled: true' gitops/envs/stage/values/frontend.yaml
grep -q 'enabled: true' gitops/envs/prod/values/frontend.yaml
```

### Validation checklist

- [ ] `argo-rollouts` Application Healthy; CRD present
- [ ] Stage frontend is a `Rollout` with ALB canary services
- [ ] Prod frontend is a `Rollout`; sync remains **manual**
- [ ] At least one canary weight progression observed on stage
- [ ] Prod canary exercised (or ready) after manual sync
- [ ] Abort = Rollout abort + Git revert documented
- [ ] Dev still `canary.enabled: false` (Deployment)

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Prod still Deployment | Values not synced | Manual sync prod after merge |
| Dev accidentally canary | Overlay mistake | Keep `canary.enabled: false` on dev |

### Recovery

Re-run failed step; capture screenshots/URLs for Topic 13 evidence.

### Best practices

Store Rollout `kubectl describe` / plugin status output for the checklist.

### Security notes

Confirm no `:latest` and digests still enforced under canary pods.

---

## End-of-topic validation

| Check | Command / evidence |
|-------|-------------------|
| Controller | `kubectl -n argo-rollouts get pods` |
| Stage Rollout | `kubectl -n stage get rollout frontend` |
| Prod Rollout | `kubectl -n prod get rollout frontend` |
| HTTPS | curl stage + prod hosts |
| Dev non-canary | `grep enabled: false gitops/envs/dev/values/frontend.yaml` |

**Cost check:** Canary pods temporary; controller always-on but small. Teardown still Topic 14.

---

## Troubleshooting matrix

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `no matches for kind Rollout` | Controller/CRD not synced | Step 12.1 |
| ALB 502/503 mid-canary | Target health / readiness | Check canary pods Ready; SG |
| Annotation not updating | Wrong Ingress name in Rollout | Must match `frontend` Ingress metadata.name |
| Kyverno deny | Bad image ref | Digest-only ECR image |
| Deployment orphan | Prune disabled / race | Delete old Deployment once |

---

## What you achieved

- Argo Rollouts **v1.8.2** on the cluster (wave 25)
- Frontend progressive delivery on **stage and prod** via ALB weights
- Dev unchanged (Deployment) for fast digest feedback
- Abort path tied to Git revert

## Next topic

**[13 — Production readiness](13-production-readiness.md)** (Phase B next).
