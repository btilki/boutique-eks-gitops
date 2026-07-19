# 06 — Backup and restore

**Audience:** L3 — Operator  
**Applies to:** Terraform state + Git desired state  
**Prerequisites:** AWS access to state bucket; GitLab  
**Estimated time:** 15–45 min  
**Risk level:** Medium–High (state restore)  

## Purpose

Define what is backed up for this pilot and how to restore it.

## When to use / When not to use

**Use** after accidental TF apply, state corruption, or bad Git merge already reverted.  
**Do not** expect Redis cart backup — ephemeral by design.

## Prerequisites

- [ ] Know state bucket / DynamoDB lock table names (from local `backend.hcl`)
- [ ] S3 versioning enabled on state bucket (Topic 03)

## Procedure

### Step 1: What we back up

| Asset | Mechanism | Retention |
|-------|-----------|-----------|
| Desired cluster state | Git history | GitLab |
| Terraform state | S3 versioning + DynamoDB lock | Per bucket lifecycle |
| Container images | ECR (until teardown destroys) | Until destroy |
| Redis / carts | **None** | Ephemeral |
| SMTP password | AWS Secrets Manager | SM versioning |

### Step 2: Restore Terraform state version

**GUI:** S3 → state object → Versions → Download prior → coordinate with team  

**Commands:** (illustrative — paths from your `backend.hcl`)

```bash
# List versions via console or:
aws s3api list-object-versions --bucket <STATE_BUCKET> --prefix <STATE_KEY> --max-items 10
```

Restore by copying the good version to current key **only** when no apply is running.

**Validation:** `terraform plan` shows expected drift (ideally small).

**Expected outcome:** State matches reality or intentional re-apply path is clear.

**Recovery steps:** If worse, restore next-older version.

**Best practices:** Never delete all versions; unlock only when sure ([17](17-common-incidents.md) F).

### Step 3: Restore app desired state

```bash
git revert / git checkout <good-sha> -- gitops/
# MR → merge → Argo sync
```

**Validation:** Digests and health match known-good.

## End-to-end validation

`terraform plan` + storefront health checks pass.

## Rollback (section-level)

Re-restore previous state version / re-revert Git.

## Related alerts and dashboards

| Alert | Dashboard | Log query |
|-------|-----------|-----------|
| — | AWS S3 console | — |

## Security notes

State may contain sensitive attributes — restrict bucket IAM; never commit state files.

## Automation opportunities

Periodic `terraform state pull` to encrypted offline store — optional hardening.
