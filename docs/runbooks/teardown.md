# Runbook — Teardown (ordered decommission)

**Audience:** L2 — Operator  
**Setup:** Topic 14 · **Milestone:** **M4**  
**Authority:** [`../setup/14-teardown.md`](../setup/14-teardown.md) is source of truth for live steps  
**Checklist:** [`../PRODUCTION_CHECKLIST.md`](../PRODUCTION_CHECKLIST.md) Appendix T  
**Cost:** [`../architecture/10-cost-model.md`](../architecture/10-cost-model.md)

## Purpose

Stop all pilot billables: release ALBs via GitOps prune, destroy EKS/VPC/NAT via Terraform, then optionally remove remote state. **Never destroy the state backend while foundation resources still exist.**

## Order (do not reorder)

```text
0. Stop CI / schedules that recreate load
1. Prune GitOps: workloads → platform → bootstrap (ALBs/TGs/PVCs release)
2. Confirm no stray ALBs / Target Groups / blocking ENIs
3. terraform destroy (terraform/envs/prod)
4. Decide remote state bucket + lock table (last)
5. Orphan audit (EKS, NAT, ELB, EIP, EC2, ECR policy)
6. Sign Appendix T + ROADMAP Phase 11 ✅
```

## Hard rules

| Do | Do not |
|----|--------|
| Prune Ingress/apps **before** `terraform destroy` | Destroy VPC while ALBs still attached |
| Destroy foundation **before** state backend | Empty/delete state bucket first |
| Record leftovers intentionally retained | Ad-hoc deletes outside this runbook |
| Use `eu-central-1` consistently | Assume “cluster gone” without `aws eks list-clusters` |

## 0 — Stop CI churn

```bash
# GitLab: Settings → CI/CD → Schedules → disable any boutique schedules
# Optional: protect main / pause pipelines if a push would rebuild during destroy
```

## 1 — Prune GitOps (ALBs first)

Prefer Argo UI or CLI. Workloads first so Ingress/ALBs delete while the API server still exists.

```bash
export AWS_REGION=eu-central-1
CLUSTER=$(terraform -chdir=terraform/envs/prod output -raw cluster_name 2>/dev/null || echo boutique-eks-gitops)
aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER"

# List apps
argocd app list --grpc-web || kubectl -n argocd get applications

# Delete workload apps (ApplicationSet children) — examples:
argocd app list --grpc-web -o name | grep -E -- '-(dev|stage|prod)$' | while read -r a; do
  argocd app delete "$a" --cascade --yes --grpc-web || true
done

# Or delete ApplicationSets so children prune:
kubectl -n argocd delete applicationset boutique-workloads --wait=false || true
kubectl -n argocd delete applicationset platform-apps platform-manifests --wait=false || true
kubectl -n argocd delete applicationset workload-namespaces --wait=false || true

# Wait for Ingress ADDRESS to clear / LoadBalancers to delete (often 3–10 min)
kubectl get ingress -A
```

Then remove root / Argo itself last among GitOps:

```bash
kubectl -n argocd delete application root --wait=false 2>/dev/null || true
# If Argo was Helm-installed outside AppSet, uninstall release after apps gone
```

## 2 — Pre-destroy AWS edge check

```bash
export AWS_REGION=eu-central-1
VPC_ID=$(terraform -chdir=terraform/envs/prod output -raw vpc_id 2>/dev/null || true)

aws elbv2 describe-load-balancers --region "$AWS_REGION" \
  --query "LoadBalancers[?contains(LoadBalancerName,'k8s-') || contains(LoadBalancerName,'boutique')].[LoadBalancerName,VpcId,State.Code]" \
  --output table

# If VPC_ID known, filter mentally / with jq
aws ec2 describe-nat-gateways --region "$AWS_REGION" \
  --filter Name=vpc-id,Values="${VPC_ID:-none}" \
  --query 'NatGateways[?State!=`deleted`].[NatGatewayId,State]' --output table 2>/dev/null || true
```

If ALBs remain after Ingress delete: remove leftover Target Groups / manually delete ELBv2 created by the controller, then continue.

## 3 — Terraform destroy foundation

```bash
cd "$(git rev-parse --show-toplevel)/terraform/envs/prod"
test -f ../../backend.hcl
terraform init -backend-config=../../backend.hcl -reconfigure
terraform plan -destroy -out=destroy.tfplan
terraform apply destroy.tfplan
# Expect exit 0. Duration often 15–30+ minutes (EKS + NAT).
```

## 4 — Remote state (last)

Only after step 3 succeeds and orphan audit is clean enough:

```bash
# Values from your private backend.hcl (never committed)
# TF_STATE_BUCKET=...
# TF_LOCK_TABLE=...

# Option A — retain empty backend (document in Appendix T)
# Option B — destroy backend:
# aws s3 rm s3://${TF_STATE_BUCKET} --recursive
# aws s3api delete-bucket --bucket "${TF_STATE_BUCKET}" --region eu-central-1
# aws dynamodb delete-table --table-name "${TF_LOCK_TABLE}" --region eu-central-1
```

## 5 — Orphan audit (must pass)

```bash
export AWS_REGION=eu-central-1
aws eks list-clusters --region "$AWS_REGION"   # must NOT list boutique-eks-gitops
aws ec2 describe-instances --region "$AWS_REGION" \
  --filters Name=tag:Name,Values='*boutique*' Name=instance-state-name,Values=running \
  --query 'Reservations[].Instances[].InstanceId' --output text

aws elbv2 describe-load-balancers --region "$AWS_REGION" --query 'LoadBalancers[].LoadBalancerName' --output text
aws ec2 describe-nat-gateways --region "$AWS_REGION" \
  --filter Name=state,Values=available,pending,deleting \
  --query 'NatGateways[].NatGatewayId' --output text

# Optional: empty ECR images or leave repos (storage cost small) — document choice
aws ecr describe-repositories --region "$AWS_REGION" \
  --query "repositories[?contains(repositoryName,'boutique-eks-gitops')].repositoryName" --output text
```

## 6 — Sign-off

Fill Appendix T in PRODUCTION_CHECKLIST; set ROADMAP Phase 11 ✅.

## Related

- Setup guide: [`../setup/14-teardown.md`](../setup/14-teardown.md)
- Early abort: same order from whatever topic created billables
