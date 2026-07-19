# 03 — Rollback

**Audience:** L3 — Operator  
**Applies to:** `stage` / `prod` (and `dev` if needed)  
**Prerequisites:** Git push + MR rights; prod CODEOWNERS if touching prod  
**Estimated time:** 15–40 min  
**Risk level:** Medium  

## Purpose

Return environments to a known-good digest set using **Git**, not imperative cluster edits.

## When to use / When not to use

**Use** when promote/canary causes errors, 5xx, or CrashLoop.  
**Do not** leave a bad digest and “fix forward” on SEV-1 without a time box.

## Prerequisites

- [ ] Identify bad merge SHA (`git log -- gitops/envs/...`)
- [ ] Read [docs/rollback.md](../rollback.md)

## Procedure

### Step 1: Git revert

Follow **[docs/rollback.md](../rollback.md)** (`git revert` / restore prior digests MR).

**Validation:** MR restores previous digests only.

**Expected outcome:** Merged to `main`.

**Recovery steps:** If revert conflicts, open explicit digest-restore MR (as in C6 rehearsal).

**Best practices:** Prefer revert of the promote merge commit.

### Step 2: Sync and canary

- Auto-sync envs: wait for Rollout  
- Prod: **manual** Argo sync  
- If canary mid-flight: abort per [runbooks/canary](../runbooks/canary.md), then ensure Git matches desired stable digest

**Validation:** [08-health-checks](08-health-checks.md); Rollout `Healthy`.

## End-to-end validation

Storefront 200; running image digest matches reverted Git.

## Rollback (section-level)

Re-promote a known-good digest later via [02](02-deployment.md) after root cause.

## Related alerts and dashboards

| Alert | Dashboard | Log query |
|-------|-----------|-----------|
| — | Argo UI | — |

## Security notes

Prod revert still needs CODEOWNERS if files under `gitops/envs/prod/**` change.

## Automation opportunities

None that bypass MR review.
