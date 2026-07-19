# 04 — Scaling

**Audience:** L3 — Operator  
**Applies to:** Cluster + Boutique workloads  
**Prerequisites:** Terraform access for node ASG; Git for replica changes  
**Estimated time:** 20–60 min  
**Risk level:** Medium (cost)  

## Purpose

Adjust capacity within the pilot envelope (ASG **2–5** × `m6i.large`; chart replicas).

## When to use / When not to use

**Use** when pods Pending (capacity) or sustained CPU/mem pressure.  
**Do not** enable unbounded autoscaling or large instance classes without cost review. **HPA is not enabled** in v1.

## Prerequisites

- [ ] Confirm cost model ([10-cost-model](../architecture/10-cost-model.md))
- [ ] Prefer teardown over scaling if pilot is finished

## Procedure

### Step 1: Inspect pressure

```bash
kubectl get nodes
kubectl top nodes 2>/dev/null || true
kubectl get pods -A | grep -i pending || true
```

**Validation:** Identify Pending reason (`FailedScheduling` events).

### Step 2: Node pool (Terraform)

Change desired/min/max in `terraform/envs/prod` / EKS module vars (within 2–5), `terraform plan` → `apply`.

**Validation:** New nodes Ready.

**Expected outcome:** Pending pods schedule.

**Recovery steps:** Scale back desired; `terraform apply` prior values.

**Best practices:** Never raise max above budgeted 5 without written approval.

### Step 3: Pod replicas (Git)

Edit `replicaCount` (or equivalent) in chart values / env overlay via MR — Argo syncs.

**Validation:** Extra pods Ready; storefront OK.

## End-to-end validation

No Pending Boutique pods; curl 200.

## Rollback (section-level)

Revert TF and/or Git replica MR.

## Related alerts and dashboards

| Alert | Dashboard | Log query |
|-------|-----------|-----------|
| Node pressure | Grafana Kubernetes | — |

## Security notes

Larger cluster = larger blast radius; keep IRSA unchanged.

## Automation opportunities

Cluster Autoscaler — deferred; document if added later.
