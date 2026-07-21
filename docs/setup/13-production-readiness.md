# 13 — Production readiness

Audience: L2 — Implementer / FC reviewer  
Estimated time: 1–2 hours  
Prerequisites: [12 — Canary rollouts](12-canary-rollouts.md) complete (stage + prod canary proven or ready)  
Creates / owns: [`docs/PRODUCTION_CHECKLIST.md`](../PRODUCTION_CHECKLIST.md), runbooks set under [`docs/runbooks/`](../runbooks/), ROADMAP status update at sign-off  
**Milestone:** **M3 — Production path proven**

---

## Topic goal

Prove the full production path with evidence: checklist green, runbooks usable, demo digest → promote → prod manual sync + canary — then proceed **immediately** to teardown (Topic 14).

## Why this topic is required

FR-10 requires operability artifacts and a demonstrated path. Short pilots must not claim “done” without evidence, and must not leave billables running after tests (FR-11 / Topic 14).

## Before you begin

- Topics 01–12 live work complete (or you are filling evidence as you finish Phase C).
- Access to GitLab MRs, Argo UI/CLI, cluster `kubectl`, and inbox used for Alertmanager.
- Phase B Topic 13 files on `main` (this guide + checklist + runbooks).

**Cost:** No new always-on resources. Cluster still burns ~$15–20/day until Topic 14.

**Idempotent:** Re-walking the checklist is safe. Do not mark PASS without evidence.

---

## Step 13.1: Walk PRODUCTION_CHECKLIST

### Goal

Complete [`docs/PRODUCTION_CHECKLIST.md`](../PRODUCTION_CHECKLIST.md) sections **A–D** with evidence notes.

### Why this step is required

M3 is evidence-based. Unticked Must items block FC review.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"
test -f docs/PRODUCTION_CHECKLIST.md

# Sample evidence collectors (paste outputs into checklist Evidence column)
kubectl get nodes
kubectl -n argocd get applications | head
kubectl get clusterpolicy
kubectl -n monitoring get pods
curl -I https://boutique.biroltilki.art
curl -I https://stage-boutique.biroltilki.art
curl -I https://dev-boutique.biroltilki.art
grep -R ':latest' gitops/envs || echo "no :latest in env overlays: OK"
```

Open the checklist in your editor; tick items only when evidence is recorded.

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | Argo CD + Grafana + GitLab |
| Navigation | Confirm apps Healthy; Grafana loads; recent digest/promote MRs |
| Verification | Paste MR URLs and timestamps into checklist |

### Expected output

Sections A–D mostly green; gaps explicitly listed (must be zero Must gaps for PASS).

### Validation

```bash
grep -q 'Milestone:** \*\*M3' docs/PRODUCTION_CHECKLIST.md
grep -q 'FR-11' docs/PRODUCTION_CHECKLIST.md
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Prod still auto-sync | AppSet misconfig | Fix workload AppSet; re-check A7 |
| Email never proven | Skipped Topic 08 | Complete alerting proof; see runbook |
| `:latest` in Git | Bad MR | Remove; re-promote digests |

### Recovery

Fix the failing subsystem via its Setup topic; re-check the row.

### Best practices

One evidence line per row beats vague “works”.

### Security notes

Do not paste SMTP passwords or AWS keys into the checklist.

---

## Step 13.2: Confirm runbooks linked and usable

### Goal

Verify the min runbook set exists and is reachable from the checklist / runbooks index.

### Why this step is required

On-call path must not depend on chat history.

### Commands

```bash
test -f docs/runbooks/README.md
test -f docs/runbooks/alerting.md
test -f docs/runbooks/ingress.md
test -f docs/runbooks/argo-sync.md
test -f docs/runbooks/kyverno.md
test -f docs/runbooks/canary.md

# Spot-check: each names a Setup topic and has triage commands
grep -l 'Quick triage' docs/runbooks/*.md
```

Skim each runbook once; optionally execute a dry read-only triage command from [ingress.md](../runbooks/ingress.md) or [argo-sync.md](../runbooks/argo-sync.md).

### GUI instructions (if applicable)

N/A — docs review.

### Expected output

Checklist **D3** evidence = runbooks index path + date reviewed.

### Validation

```bash
wc -l docs/runbooks/ingress.md docs/runbooks/argo-sync.md \
  docs/runbooks/kyverno.md docs/runbooks/canary.md docs/runbooks/alerting.md
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| teardown.md missing | Expected until Topic 14 | Do not block M3; Appendix T waits for 14 |

### Recovery

Restore files from Topic 13 Phase B delivery.

### Best practices

Link runbooks from GitLab wiki or project README Ops section.

### Security notes

Runbooks must not instruct static AWS keys or cluster deploy from CI.

---

## Step 13.3: Capture demo path (digest → promote → prod + canary)

### Goal

Fill checklist section **E** with one full demo: CI digest MR → promote stage → promote prod (CODEOWNERS) → manual sync → canary → storefront OK.

### Why this step is required

M3 definition of done requires the production path proven, not only component checks.

### Commands

```bash
# Adjust app names via: argocd app list | grep -E 'frontend|boutique'
# Evidence pack skeleton:
mkdir -p /tmp/m3-evidence
date -u > /tmp/m3-evidence/timestamp.txt

# After demo, record:
# - GitLab CI pipeline URL (digest MR to dev)
# - Stage promote MR URL
# - Prod promote MR URL + CODEOWNERS approval
# - argocd app sync <prod-frontend> timestamp
# - kubectl -n stage|prod describe rollout frontend (weights)
# - curl -I https://boutique.biroltilki.art

kubectl -n stage get rollout frontend -o wide | tee /tmp/m3-evidence/stage-rollout.txt
kubectl -n prod get rollout frontend -o wide | tee /tmp/m3-evidence/prod-rollout.txt
curl -I https://boutique.biroltilki.art | tee /tmp/m3-evidence/prod-curl.txt
```

Optional recovery proof: one `git revert` or canary abort + revert ([rollback.md](../rollback.md), [canary.md](../runbooks/canary.md)).

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | GitLab MRs → Argo CD → browser shop |
| Navigation | Merge digests; SYNC prod; watch Rollout |
| Verification | Shop loads on `boutique.biroltilki.art` |

### Expected output

Section **E** fully filled; demo owner + date set.

![Online Boutique storefront — `boutique.biroltilki.art` (prod)](../../assets/images/setup/13-boutique-prod-homepage.png)

### Validation

```bash
grep -q 'Demo path' docs/PRODUCTION_CHECKLIST.md
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Prod unchanged after MR | Forgot manual sync | [`argo-sync.md`](../runbooks/argo-sync.md) |
| Canary skipped | Rollout not enabled | Revisit Topic 12 |

### Recovery

Re-run from last good env; do not invent kubectl image pins.

### Best practices

Keep evidence files until Topic 14 destroy note is written.

### Security notes

Prod promote still requires `@btilki`; demo does not bypass CODEOWNERS.

---

## Step 13.4: M3 sign-off and ROADMAP update

### Goal

Sign the checklist PASS/FAIL; on PASS mark ROADMAP phases **1–10** ✅ and start Topic 14 **immediately**.

### Why this step is required

Closes Milestone M3 and triggers mandatory teardown for short pilots.

### Commands

```bash
# Edit docs/PRODUCTION_CHECKLIST.md sign-off table → PASS
# Edit ROADMAP.md phase overview: set Status ✅ for phases 1–10
# Leave phase 11 ⬜ until Topic 14 completes

grep -n 'Phase overview' -A20 ROADMAP.md | head -25
```

### GUI instructions (if applicable)

FC review at M3: confirm checklist evidence, then approve teardown start.

### Expected output

- Checklist **M3 result = PASS**
- `ROADMAP.md` phases 1–10 ✅; Current focus → Topic 14
- Operator starts [`14-teardown.md`](14-teardown.md) the same day

### Validation

```bash
# After you edit ROADMAP (live step — not done in Phase B alone):
# grep -c '| ✅ |' ROADMAP.md   # expect phases 1–10 updated
test -f docs/PRODUCTION_CHECKLIST.md
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| PASS with open Must | Soft pressure | Re-open FAIL; fix; re-sign |
| Cluster left running | Skipped 14 | Cost risk — start teardown now |

### Recovery

If FAIL: list open Must IDs; fix; re-run 13.1–13.3.

### Best practices

Do not schedule “one more feature” between M3 and teardown for this pilot.

### Security notes

Teardown reduces attack surface and bill — treat as security hygiene.

---

## End-of-topic validation

| Check | Evidence |
|-------|----------|
| Checklist A–E complete | `docs/PRODUCTION_CHECKLIST.md` |
| Runbooks min set | ingress, argo-sync, kyverno, canary (+ alerting) |
| Demo path recorded | Section E |
| ROADMAP 1–10 ✅ | After live sign-off |
| Teardown started | Topic 14 / Appendix T in progress |

**Cost check:** Cluster still on — **Topic 14 next, same session if possible.**

---

## Troubleshooting matrix

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Doc-only PASS | No live cluster | Complete Phase C first |
| Missing teardown.md | Topic 14 not authored/executed | Phase B Topic 14 then execute |
| Checklist drift vs versions | Pin change | Update `docs/versions.md` + re-verify |

---

## What you achieved

- M3 evidence pack and checklist
- Operability runbooks for ingress, Argo, Kyverno, canary
- Explicit handoff to mandatory teardown

## Next topic

**[14 — Teardown](14-teardown.md)** — run **immediately** after tests (Milestone M4).
