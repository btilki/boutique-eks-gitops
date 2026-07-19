# 13 — Upgrades

**Audience:** L3 — Operator  
**Applies to:** EKS, platform charts, Boutique digests  
**Prerequisites:** [versions.md](../versions.md); staging validation  
**Estimated time:** Hours  
**Risk level:** High  

## Purpose

Upgrade components in a safe order without breaking GitOps or Kyverno.

## When to use / When not to use

**Use** when bumping pins deliberately.  
**Do not** upgrade EKS and all Helm charts in one MR.

## Prerequisites

- [ ] Stage green
- [ ] Rollback plan ([03](03-rollback.md))
- [ ] Maintenance window or accept brief errors

## Procedure

### Step 1: Order of operations

1. **GitLab CI pins** (Trivy/cosign) if needed — `.gitlab-ci.yml` / versions.md  
2. **Boutique digests** via normal promote ([02](02-deployment.md))  
3. **Platform Helm** (Argo AppSet values) — one component per MR  
4. **EKS control plane / node AMI** via Terraform last (or per AWS guidance)  

**Validation:** After each step, [08](08-health-checks.md).

**Expected outcome:** Pins match `docs/versions.md`.

**Recovery steps:** Revert MR; TF apply previous version.

**Best practices:** Update ADR/versions.md in the same change set as the bump.

### Step 2: Kyverno / PSA compatibility

After policy or K8s minor bumps, re-test deny fixtures and a canary deploy on stage.

**Validation:** `kyverno` policies Ready; deny `:latest` still works.

## End-to-end validation

Prod storefront 200 on new pins; CI green for digest path.

## Rollback (section-level)

Git revert platform values; TF downgrade only if AWS supports; prefer forward-fix patches for EKS.

## Related alerts and dashboards

| Alert | Dashboard | Log query |
|-------|-----------|-----------|
| — | Argo | — |

## Security notes

Never disable Kyverno to unblock an upgrade without a tracked exception.

## Automation opportunities

Dependabot/Renovate for chart versions — optional; still human-gated.
