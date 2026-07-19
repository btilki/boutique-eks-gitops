# 14 — Teardown

Audience: L2 — Implementer  
Estimated time: 1–2 hours (EKS destroy often 15–30+ minutes)  
Prerequisites: [13 — Production readiness](13-production-readiness.md) **PASS**, **or** early abort after any billable topic  
Creates / owns: [`docs/runbooks/teardown.md`](../runbooks/teardown.md); fills [`PRODUCTION_CHECKLIST`](../PRODUCTION_CHECKLIST.md) Appendix T; ROADMAP Phase 11 ✅  
**Milestone:** **M4 — Clean teardown**  
**Related:** [cost model](../architecture/10-cost-model.md)

---

## Topic goal

Decommission the pilot in a fixed order so **no orphan billables** remain: GitOps prune (ALBs) → confirm edge cleanup → `terraform destroy` → optional state backend → orphan audit.

## Why this topic is required

FR-11 / cost guardrail: short pilots must destroy **immediately after tests**. Leaving EKS + NAT + ALBs running is the largest cost and attack-surface failure mode.

## Before you begin

- M3 complete **or** you are aborting early (still use this order from the furthest topic reached).
- AWS admin credentials; `terraform/backend.hcl` and `terraform/envs/prod/terraform.tfvars` available locally.
- Argo / kubeconfig still work **until** cluster destroy (keep a terminal ready).
- Read [`docs/runbooks/teardown.md`](../runbooks/teardown.md) once end-to-end.

**Destructive:** This topic deletes the cluster and network. Repo docs remain; rebuild = re-apply from Topic 03/04.

**Cost:** Goal is **stop** hourly EKS/NAT/ALB charges. Confirm next-day bill if needed.

**Idempotent:** Re-running destroy on empty state should plan zero resources; safe to re-audit.

---

## Step 14.1: Stop CI churn and prune GitOps (ALBs gone)

### Goal

Disable schedules that recreate load; delete Boutique + platform Ingress paths so AWS Load Balancers and Target Groups release **before** Terraform destroy.

### Why this step is required

Destroying the VPC while controller-managed ALBs exist fails or orphans ELBv2/ENIs.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"
export AWS_REGION=eu-central-1
export AWS_DEFAULT_REGION=eu-central-1

# 1) GitLab UI: disable CI Schedules for this project (document in Appendix T)

# 2) Kubeconfig
CLUSTER=$(terraform -chdir=terraform/envs/prod output -raw cluster_name)
aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER"

# 3) Delete workload apps / ApplicationSets (cascade)
kubectl -n argocd get applicationset,applications

# Preferred: delete ApplicationSets (children prune with finalizers)
kubectl -n argocd delete applicationset boutique-workloads --wait=true || true
# Wait until boutique Ingresses disappear
kubectl get ingress -A

# Platform apps that own Ingress (Grafana, Argo UI, etc.)
kubectl -n argocd delete applicationset platform-apps --wait=false || true
kubectl -n argocd delete applicationset platform-manifests --wait=false || true
kubectl -n argocd delete applicationset workload-namespaces --wait=false || true

# Root app-of-apps last among Argo-managed apps
kubectl -n argocd get applications
# Delete remaining Applications if needed:
# kubectl -n argocd delete applications --all --wait=false

# Confirm no shop/platform Ingress left
kubectl get ingress -A
```

Expected duration: **3–15 minutes** for ALB deletion after Ingress removal.

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | Argo CD UI |
| Navigation | Delete Applications / ApplicationSets; confirm resources pruned |
| Verification | AWS Console → EC2 → Load Balancers — k8s ALBs terminating |

### Expected output

No Boutique/Grafana/Argo Ingress objects (or only terminating); ALB count for this VPC trending to zero.

### Validation

```bash
kubectl get ingress -A
aws elbv2 describe-load-balancers --region "$AWS_REGION" \
  --query 'length(LoadBalancers)' --output text
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Apps stuck Deleting | Finalizer / resource deadlock | Describe Application; clear stuck Ingress/NS carefully |
| ALB remains | Orphan TG / annotation | Delete ELBv2 manually after noting name in Appendix T |
| No kube API | Cluster already half-destroyed | Skip to Step 14.2 AWS-only checks |

### Recovery

Do **not** start `terraform destroy` until Ingress/ALB situation is understood.

### Best practices

Prefer ApplicationSet delete over one-by-one when many apps exist.

### Security notes

You still have cluster-admin until destroy — treat the window as sensitive.

---

## Step 14.2: Confirm no stray ALBs / TGs / blocking ENIs

### Goal

AWS-side pre-check so Terraform destroy is not blocked by load balancer ENIs.

### Why this step is required

Stuck ENIs in subnets are a common destroy failure for EKS/VPC.

### Commands

```bash
VPC_ID=$(terraform -chdir=terraform/envs/prod output -raw vpc_id)

aws elbv2 describe-load-balancers --region "$AWS_REGION" \
  --query "LoadBalancers[?VpcId=='${VPC_ID}'].[LoadBalancerName,State.Code,Type]" \
  --output table

aws elbv2 describe-target-groups --region "$AWS_REGION" \
  --query "TargetGroups[?VpcId=='${VPC_ID}'].TargetGroupName" --output text

aws ec2 describe-network-interfaces --region "$AWS_REGION" \
  --filters Name=vpc-id,Values="$VPC_ID" \
  --query 'NetworkInterfaces[?Status!=`available`].[NetworkInterfaceId,Description,Status]' \
  --output table
```

If ALBs still `active`, delete them (and dependent TGs) in Console or CLI **after** confirming they belong to this pilot.

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | AWS Console → EC2 → Load Balancers / Target Groups |
| Navigation | Filter by VPC ID from Terraform output |
| Verification | Zero ALBs in this VPC (or documented leftovers) |

### Expected output

Empty (or documented) ELBv2 list for the pilot VPC.

### Validation

```bash
# Should print nothing or only non-pilot LBs in other VPCs
aws elbv2 describe-load-balancers --region "$AWS_REGION" \
  --query "LoadBalancers[?VpcId=='${VPC_ID}'].LoadBalancerName" --output text
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `dependencyViolation` later | ENI still in use | Wait; delete leftover ALB/TG; retry |
| Wrong VPC | Output stale | Re-init Terraform; re-read `vpc_id` |

### Recovery

Manual ELBv2 delete; wait 2–5 minutes; re-list ENIs.

### Best practices

Paste VPC ID and final ELB list into Appendix T.

### Security notes

Do not delete ALBs from unrelated VPCs/accounts.

---

## Step 14.3: `terraform destroy` foundation

### Goal

Destroy EKS, node groups, NAT, VPC, IAM roles/OIDC, ECR (as coded), ACM resources managed by Terraform, etc.

### Why this step is required

This is the primary cost stop for control plane, nodes, and NAT.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)/terraform/envs/prod"

test -f ../../backend.hcl
test -f terraform.tfvars

terraform init -backend-config=../../backend.hcl -reconfigure
terraform plan -destroy -out=destroy.tfplan

# Review plan: eks, nat, vpc, ecr, iam — then:
terraform apply destroy.tfplan
echo "destroy exit: $?"
```

Expected duration: **15–40 minutes**. Do not interrupt mid-apply casually.

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | AWS Console → EKS / VPC |
| Navigation | Watch cluster → Deleting; NAT → deleted |
| Verification | Cluster absent from EKS list |

### Expected output

`Apply complete` / destroy finished with **0** errored resources (or only documented manual leftovers).

### Validation

```bash
aws eks list-clusters --region "$AWS_REGION"
# Must NOT include boutique-eks-gitops (or your cluster_name)

terraform -chdir=terraform/envs/prod state list 2>/dev/null || echo "state empty or backend unreachable: OK if destroy done"
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Subnet has dependencies | ALB/ENI leftover | Return to 14.2; delete; re-apply destroy |
| IAM/OIDC delete fail | Still attached | Retry; remove leftover OIDC provider manually if needed |
| Timeout | EKS slow | Re-run `terraform apply destroy.tfplan` / `terraform destroy` |

### Recovery

Fix blocker; `terraform destroy` again (idempotent toward empty).

### Best practices

Keep `destroy.tfplan` artifact until Appendix T signed (local only).

### Security notes

Destroy removes IRSA/CI roles — expected. Rotate any SMTP secrets used for the pilot if the mailbox is shared.

---

## Step 14.4: Remote state bucket / lock table (guided, last)

### Goal

Choose **retain empty backend** vs **delete bucket + DynamoDB table**. Never do this before Step 14.3 succeeds.

### Why this step is required

State backend is cheap but still an account resource; deleting it early loses the destroy audit trail mid-flight.

### Commands

```bash
# Read names from local gitignored file (do not commit):
grep -E 'bucket|dynamodb_table' terraform/backend.hcl

# Option A — RETAIN (recommended if you may rebuild soon)
echo "Retaining TF state backend — document in Appendix T"

# Option B — DELETE (only after orphan audit mostly clean)
# export TF_STATE_BUCKET=...
# export TF_LOCK_TABLE=...
# aws s3 rm "s3://${TF_STATE_BUCKET}" --recursive
# aws s3api delete-bucket --bucket "${TF_STATE_BUCKET}" --region "$AWS_REGION"
# aws dynamodb delete-table --table-name "${TF_LOCK_TABLE}" --region "$AWS_REGION"
```

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | S3 + DynamoDB consoles |
| Navigation | Confirm bucket empty before delete |
| Verification | Bucket/table gone **or** retained noted |

### Expected output

Appendix T records Option A or B with resource names.

### Validation

```bash
# If deleted:
# aws s3api head-bucket --bucket "$TF_STATE_BUCKET"  # expect 404
# If retained: head-bucket succeeds
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Bucket not empty | Old state versions | Empty all versions/delete markers, then delete |
| Lock table in use | Destroy still running | Finish 14.3 first |

### Recovery

Leave backend retained; continue orphan audit.

### Best practices

Prefer retain for 24–48h after destroy, then delete if unused.

### Security notes

State may contain resource IDs — treat retained buckets as sensitive.

---

## Step 14.5: Orphan audit

### Goal

Prove no EKS cluster, no pilot NAT, no stray ALBs, no running node instances; document ECR/ACM/Route53 choices.

### Why this step is required

M4 validation criteria require explicit AWS checks, not “terraform said ok”.

### Commands

```bash
export AWS_REGION=eu-central-1

echo "=== EKS ==="
aws eks list-clusters --region "$AWS_REGION"

echo "=== NAT (available) ==="
aws ec2 describe-nat-gateways --region "$AWS_REGION" \
  --filter Name=state,Values=available \
  --query 'NatGateways[].{Id:NatGatewayId,Vpc:VpcId}' --output table

echo "=== ELBv2 names ==="
aws elbv2 describe-load-balancers --region "$AWS_REGION" \
  --query 'LoadBalancers[].LoadBalancerName' --output text

echo "=== EIP unassociated (review) ==="
aws ec2 describe-addresses --region "$AWS_REGION" \
  --query 'Addresses[?AssociationId==null].[AllocationId,PublicIp]' --output table

echo "=== ECR boutique repos (optional retain) ==="
aws ecr describe-repositories --region "$AWS_REGION" \
  --query "repositories[?contains(repositoryName,'boutique')].[repositoryName]" --output table

echo "=== Route53 boutique records (spot-check) ==="
# ZONE_ID from your notes / prior output — list record names containing boutique
# aws route53 list-resource-record-sets --hosted-zone-id "$ZONE_ID" --query ...
```

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | Billing → Cost Explorer (optional next day) |
| Navigation | Confirm EKS service cost flat after destroy |
| Verification | No ongoing cluster hours |

### Expected output

Cluster absent; NAT/ALB clean for this pilot; leftovers listed with disposition (delete later / accept).

### Validation

Checklist Appendix T rows all addressed.

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| NAT still available | Wrong VPC / destroy incomplete | Re-run destroy; verify VPC deleted |
| Records left in Route53 | external-dns removed early | Delete A/CNAME records manually |
| ECR repos remain | Terraform retain / failed destroy | `aws ecr delete-repository --force` per repo if desired |

### Recovery

Document and clear leftovers before M4 PASS.

### Best practices

Screenshot or paste CLI output into Appendix T evidence links.

### Security notes

Remove unused ACM certs only if unused elsewhere; do not delete certs for other apps on `biroltilki.art` without care.

---

## Step 14.6: Topic validation — M4 sign-off

### Goal

Complete Appendix T; mark ROADMAP **Phase 11 ✅**; declare pilot **closed** (bill stopped / residuals documented).

### Why this step is required

Closes FR-11 and Milestone M4.

### Commands

```bash
# Edit docs/PRODUCTION_CHECKLIST.md Appendix T — all boxes
# Edit ROADMAP.md — Phase 11 status ✅; Current focus → closed / rebuild

grep -n 'Appendix T' -A20 docs/PRODUCTION_CHECKLIST.md | head -25
```

### GUI instructions (if applicable)

N/A — docs sign-off.

### Expected output

| Check | Result |
|-------|--------|
| `aws eks list-clusters` lacks this cluster | PASS |
| No pilot NAT / ALB (or documented) | PASS |
| Nodes terminated | PASS |
| Appendix T complete | PASS |
| ROADMAP Phase 11 ✅ | PASS |

### Validation

```bash
aws eks list-clusters --region eu-central-1
test -f docs/runbooks/teardown.md
test -f docs/setup/14-teardown.md
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Soft PASS with orphans | Time pressure | FAIL M4 until audit clean |

### Recovery

Return to 14.5; fix; re-sign.

### Best practices

Note destroy UTC timestamp for cost discussions.

### Security notes

Revoke temporary AWS keys used for the pilot if any were created (prefer SSO/OIDC only).

---

## End-of-topic validation

| Check | Command / evidence |
|-------|-------------------|
| No cluster | `aws eks list-clusters` |
| Destroy OK | Terraform apply destroy exit 0 |
| Runbook followed | No undocumented ad-hoc steps |
| Appendix T | Filled |
| ROADMAP | Phase 11 ✅ |

**Cost check:** Hourly EKS/NAT/ALB should stop. Spot-check Cost Explorer next day if required.

---

## Troubleshooting matrix

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Destroy blocked on ENI | ALB not gone | Step 14.2 |
| State locked | Stale DynamoDB lock | `force-unlock` only if sure no other apply |
| Accidentally destroyed backend first | Order violated | Stop; inventory orphans manually; do not recreate blindly |

---

## Early abort path

If stopping after Topics 04–12 without M3: **still** run Steps 14.1→14.6 from the furthest resources created. Skip checklist M3; still fill Appendix T.

---

## What you achieved

- Ordered decommission without orphan billables
- M4 evidence in Appendix T
- Pilot closed (repo retained for rebuild)

## Next

**Phase B complete** after this topic’s approval.  
**Phase C:** live bootstrap starting at [`01-prerequisites.md`](01-prerequisites.md) Step **1.1** (one step per turn).  
If the cluster was just destroyed after a successful pilot, Phase C is only needed for a **rebuild**.
