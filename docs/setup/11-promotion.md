# 11 — Promotion

Audience: L2 — Implementer  
Estimated time: 1–1.5 hours  
Prerequisites: [10 — GitLab CI digests](10-gitlab-ci-digest.md) complete (dev digests flowing)  
Creates: [`docs/promotion.md`](../promotion.md), [`docs/rollback.md`](../rollback.md); GitLab CODEOWNERS enforcement on prod paths  
Related: [CODEOWNERS](../../CODEOWNERS) · ADR [0001](../adr/0001-digest-only-gitops.md)

---

## Topic goal

Operationalize human promotion of digests `dev → stage → prod` with CODEOWNERS on prod and **manual** Argo sync for production — plus a documented rollback via `git revert`.

## Why this topic is required

Without governed promotion, digests can skip stage or land in prod without `@btilki` review, defeating the manual-sync safety model.

## Before you begin

- Dev Boutique healthy on current digests (Topic 09–10).
- You can create MRs; `@btilki` can approve (or you are `@btilki`).
- Argo UI/CLI access for manual prod sync.
- Phase B Topic 11 docs present on `main`.

**Idempotent:** Re-reading docs is safe. Promote MRs are normal Git operations.

---

## Step 11.1: Review promotion rules

### Goal

Read and accept [`docs/promotion.md`](../promotion.md) as the digest-copy contract.

### Why this step is required

Reviewers and releasers need one shared checklist before touching stage/prod.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"
test -f docs/promotion.md
grep -n 'Digest-only' docs/promotion.md
grep -n 'Manual' docs/promotion.md
```

### GUI instructions (if applicable)

N/A — read the doc in your editor or GitLab.

### Expected output

You can state: digest-only MRs; stage before prod; prod CODEOWNERS + manual Argo sync.

### Validation

```bash
grep -q 'gitops/envs/prod' docs/promotion.md && echo "promotion doc: OK"
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Doc missing | Phase B not merged | Restore Topic 11 files |

### Recovery

Re-copy `docs/promotion.md` from Topic 11 delivery.

### Best practices

Link `docs/promotion.md` in GitLab MR description templates.

### Security notes

Promotion is a privileged act — keep MR review required on `main`.

---

## Step 11.2: Review rollback procedure

### Goal

Read [`docs/rollback.md`](../rollback.md) and confirm `git revert` is the default recovery path.

### Why this step is required

Incidents need a rehearsable undo that preserves Git as source of truth.

### Commands

```bash
test -f docs/rollback.md
grep -n 'git revert' docs/rollback.md
grep -n 'kubectl set image' docs/rollback.md  # should appear only as forbidden
```

### GUI instructions (if applicable)

N/A.

### Expected output

You know how to revert a promote merge commit and re-sync prod manually.

### Validation

```bash
grep -q 'Do **not**' docs/rollback.md && echo "rollback doc: OK"
```

### Common problems

None if file present.

### Recovery

Restore file from Git.

### Best practices

Keep a known-good digest list from the last healthy stage promote.

### Security notes

Avoid force-push rewrites of `main` for routine rollback.

---

## Step 11.3: Enforce CODEOWNERS on prod paths (GitLab)

### Goal

Make GitLab require `@btilki` approval for changes under `gitops/envs/prod/**`.

### Why this step is required

Without branch protection + code owner approval, `CODEOWNERS` is advisory only.

### Commands

```bash
test -f CODEOWNERS
grep -n 'gitops/envs/prod' CODEOWNERS
```

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | GitLab |
| Navigation | Project → **Settings** → **Repository** → **Protected branches** |
| Permissions | Maintainer / Owner |
| Verification | Default branch (`main`) protected; **Code owner approval** enabled |

| Field | Value | Why |
|-------|-------|-----|
| Branch | `main` (or `CI_DEFAULT_BRANCH`) | Production Git history |
| Allowed to merge | Maintainers (+ developers if you choose) | Control merges |
| Allowed to push | No one / Maintainers only | No direct pushes preferred |
| **Require code owner approval** | **Enabled** | Enforces `CODEOWNERS` |
| Require approvals | ≥ 1 | At least `@btilki` for prod paths |

Optional: **Settings** → **Merge requests** → ensure approval rules do not bypass code owners.

| Element | Content |
|---------|---------|
| Platform | GitLab |
| Navigation | **Settings** → **Merge requests** → **Merge request approvals** (if present on your tier) |
| Verification | Code owners section cannot be skipped by authors |

### Expected output

A test MR that only touches `gitops/envs/prod/values/frontend.yaml` shows **Code owners** approval required from `@btilki`.

### Validation

Create a dry-run MR (do not merge) editing a prod digest comment/space, confirm UI blocks merge without code owner approval — then close the MR.

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| No code owners section | Feature not enabled / wrong plan | Enable protected branch code owner approval |
| `@btilki` not resolved | Username mismatch | Use exact GitLab username in CODEOWNERS |

### Recovery

Fix username; re-protect branch; re-test with dry-run MR.

### Best practices

Keep CODEOWNERS path rules narrow (`/gitops/envs/prod/`) so stage/dev are not blocked by the same gate.

### Security notes

Do not add broad owners that dilute prod accountability.

---

## Step 11.4: Promote digests to stage and verify

### Goal

Execute a real `dev → stage` digest promote MR and confirm Argo + HTTPS.

### Why this step is required

Proves the promotion path before touching prod.

### Commands

Follow [`docs/promotion.md`](../promotion.md) “promote dev → stage” commands, then:

```bash
# After MR merged
argocd app list --grpc-web | grep -- '-stage' || kubectl -n argocd get app | grep stage
kubectl -n stage get pods
curl -I --max-time 60 https://stage-boutique.biroltilki.art
```

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | GitLab MR → merge promote/stage |
| Argo CD | Confirm `*-stage` apps Synced/Healthy |
| Browser | `https://stage-boutique.biroltilki.art` |

### Expected output

Stage apps healthy; storefront HTTPS success.

![Online Boutique storefront — `stage-boutique.biroltilki.art`](../../assets/images/setup/11-boutique-stage-homepage.png)

### Validation

```bash
curl -fsS -o /dev/null -w "%{http_code}\n" https://stage-boutique.biroltilki.art
# expect 200 or 302
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Digests unchanged in Git | yq/path error | Re-check promote commands |
| Argo not syncing | App unhealthy | Check Application conditions |
| Kyverno deny | Bad digest format | Ensure `sha256:…` only |

### Recovery

Fix values via new MR; use [rollback.md](../rollback.md) if stage is broken.

### Best practices

Promote all services together for the first proof; later allow partial promotes.

### Security notes

Still no cluster credentials in CI for this step — human Git + Argo only.

---

## Step 11.5: Promote digests to prod + manual Argo sync

### Goal

Execute `stage → prod` digest MR with `@btilki` approval, then **manually** sync prod apps.

### Why this step is required

Production must not auto-reconcile; manual sync is the final gate (FR-03/FR-08).

### Commands

Follow [`docs/promotion.md`](../promotion.md) “promote stage → prod”, merge after CODEOWNERS approval, then:

```bash
# Manual sync examples (CLI) — repeat per app or sync from UI
for app in redis-prod productcatalogservice-prod currencyservice-prod cartservice-prod \
           paymentservice-prod shippingservice-prod checkoutservice-prod frontend-prod; do
  argocd app sync "$app" --grpc-web
done

kubectl -n prod get pods
curl -I --max-time 60 https://boutique.biroltilki.art
```

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | GitLab | Merge prod promote MR after **code owner** approval |
| Platform | Argo CD UI | Select each `*-prod` app → **SYNC** (do not enable auto-sync) |
| Browser | `https://boutique.biroltilki.art` | Storefront OK |

| Field (Argo sync) | Value | Why |
|-------------------|-------|-----|
| Prune | As needed / default | Match Git |
| Dry run | Optional first | Safety |

### Expected output

Prod apps Healthy after manual sync; prod hostname HTTPS OK; automated sync still **disabled** on prod apps.

### Validation

```bash
kubectl -n argocd get app frontend-prod -o jsonpath='{.spec.syncPolicy.automated}{"\n"}'
# expect empty
curl -fsS -o /dev/null -w "%{http_code}\n" https://boutique.biroltilki.art
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Merge blocked | CODEOWNERS | Approve as `@btilki` |
| Synced but old pods | Forgot manual sync | Sync `*-prod` |
| Auto-sync enabled | UI mistake | Disable immediately |

### Recovery

[rollback.md](../rollback.md); re-sync prod manually after revert merges.

### Best practices

Record MR URL + sync time for Topic 13 evidence.

### Security notes

Enabling prod auto-sync is a **severity** for this pilot.

---

## Step 11.6: Topic validation (gate to Topic 12)

### Goal

Confirm promotion + rollback docs and one successful stage+prod path.

### Why this step is required

Topic 12 canaries assume stage/prod digests are promotable under governance.

### Commands

```bash
test -f docs/promotion.md && test -f docs/rollback.md && test -f CODEOWNERS
```

### GUI instructions (if applicable)

Confirm protected branch still requires code owner approval.

### Expected output

Checklist complete.

### Validation

- [ ] `docs/promotion.md` reviewed (11.1)
- [ ] `docs/rollback.md` reviewed (11.2)
- [ ] GitLab code owner approval enforced for prod (11.3)
- [ ] Stage promote verified (11.4)
- [ ] Prod promote + **manual** sync verified (11.5)
- [ ] Prod apps still have no automated sync

### Common problems

Missing evidence — re-run curl and capture output.

### Recovery

Re-execute failed step only.

### Best practices

Keep promote/rollback links in the root README (already planned).

### Security notes

Confirm CI still cannot write `gitops/envs/prod/**`.

---

## Topic validation (end-to-end)

Topic 11 is complete when Step 11.6 checklist passes.

**Cost check:** Negligible (process/docs); ALBs already running.

---

## Topic troubleshooting

| Area | Symptom | Action |
|------|---------|--------|
| CODEOWNERS | Ignored | Protected branch setting |
| yq | Syntax | Use `yq -i '.image.digest = "sha256:…"'` |
| Argo | Prod OutOfSync after merge | Expected until manual sync |
| Rollback | Wrong parent for `-m 1` | Use `git log` to find merge commit |

---

## Next step

**[12 — Canary rollouts](12-canary-rollouts.md)** (Phase B next).

Progressive delivery for frontend on **stage and prod** after digests promote cleanly.
