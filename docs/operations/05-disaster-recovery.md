# 05 — Disaster recovery

**Audience:** L3 — Operator  
**Applies to:** Full platform  
**Prerequisites:** GitLab repo intact; TF state backend accessible **or** willingness to re-bootstrap state  
**Estimated time:** Hours (RTO)  
**Risk level:** High  

## Purpose

Recover from cluster loss or unrecoverable corruption by **rebuilding from Git + Terraform** (pilot DR).

## When to use / When not to use

**Use** when EKS is gone/unusable and apps must return.  
**Do not** expect multi-region failover — **out of scope**.

## Prerequisites

- [ ] Read [08-resilience-and-dr](../architecture/08-resilience-and-dr.md)
- [ ] Pins in [versions.md](../versions.md)
- [ ] `backend.hcl` / tfvars available locally (not in Git)

## Procedure

### Step 1: Decide rebuild vs teardown-only

If the pilot is over → [teardown](../runbooks/teardown.md) and stop.  
If rebuild required → continue.

### Step 2: Restore / recreate foundation

1. Ensure remote state (Topic 03) exists or re-create  
2. `terraform -chdir=terraform/envs/prod init` + `apply` (Topics 03–04)  
3. Continue Setup Guide from Topic 05 onward as needed  

**Validation:** `kubectl get nodes` Ready.

**Expected outcome:** Cluster API reachable.

**Recovery steps:** Fix IAM/CIDR; do not force-unlock blindly ([17](17-common-incidents.md) Playbook F).

**Best practices:** Prefer apply from known Git SHA (`main`).

### Step 3: GitOps catch-up

Register Argo repo creds; sync root app-of-apps; wait for platform + Boutique.

**Validation:** [08-health-checks](08-health-checks.md).

### Step 4: Images

ECR may be empty after destroy — re-run Topic 09 bootstrap and/or CI digest pipeline.

**Validation:** Pods pull `@sha256:…` from ECR; Kyverno allows.

## End-to-end validation

All five hostnames healthy; prod manual sync path works once.

## Rollback (section-level)

If rebuild is worse than nothing, complete teardown and accept downtime.

## Related alerts and dashboards

| Alert | Dashboard | Log query |
|-------|-----------|-----------|
| — | — | Rebuild is offline-first |

## Security notes

Recreate OIDC trust carefully; rotate SMTP and admin passwords after rebuild.

## Automation opportunities

Documented rebuild checklist only — no `rebuild-all.sh`.
