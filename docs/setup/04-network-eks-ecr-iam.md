# 04 — Network, EKS, ECR, IAM

Audience: L2 — Implementer  
Estimated time: 2–4 hours (EKS create often 15–25 minutes)  
Prerequisites: [03 — Terraform remote state](03-remote-state.md) complete  
Creates: VPC (1× NAT), EKS 1.31 + node group, 7 ECR repos, ACM cert, GitLab OIDC CI role, IRSA roles for LB controller / external-dns / ESO; modules under `terraform/modules/*` and `terraform/envs/prod/*`  
Related ADRs: [0002](../adr/0002-single-cluster-namespaces.md) · [0003](../adr/0003-tls-acm-alb.md) · [0004](../adr/0004-dns-hostname-scheme.md)  
Pins: [docs/versions.md](../versions.md)

---

## Topic goal

Provision the AWS foundation so later topics have a Ready **EKS (Elastic Kubernetes Service)** cluster, registries, DNS/TLS inputs, and least-privilege identities for GitLab CI and platform controllers. This topic creates the **VPC (Virtual Private Cloud)** (with one **NAT (Network Address Translation)** gateway), **ECR (Elastic Container Registry)** repositories, **IAM (Identity and Access Management)** roles including **OIDC (OpenID Connect)** for GitLab CI and **IRSA (IAM Roles for Service Accounts)** for controllers, and an **ASG (Auto Scaling Group)** node group.

## Why this topic is required

Every platform and app topic depends on live networking, Kubernetes, ECR, and IAM. Applying this stack is the first **high cost** step — treat plan review as mandatory.

## Before you begin

- Topic 03: remote state init works (`terraform/backend.hcl` present, gitignored).
- Route53 zone `biroltilki.art` in the **same** account (Topic 01).
- Know your GitLab `path_with_namespace` for `gitlab_project_path`.
- **Cost impact: HIGH** — EKS control plane + 3× `m6i.large` + NAT Gateway. Confirm budget; teardown is Topic 14.
- Read [cost model](../architecture/10-cost-model.md).

**Destructive warning:** `terraform destroy` later removes the cluster. Do not destroy mid-pilot without Topic 14 order.

**Idempotent:** Re-plan/re-apply is safe for unchanged config; node group updates may roll nodes.

---

## Step 4.1: Review module layout and configure tfvars

### Goal

Confirm Terraform modules exist and create a local `terraform.tfvars` from the example (no secrets committed).

### Why this step is required

Wrong `gitlab_project_path` or open API CIDRs are hard to fix after habits form; review prevents mis-apply.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"

ls terraform/modules/network terraform/modules/eks terraform/modules/ecr \
   terraform/modules/dns terraform/modules/iam_gitlab_oidc terraform/modules/irsa

test -f terraform/envs/prod/main.tf
test -f terraform/envs/prod/terraform.tfvars.example

cp terraform/envs/prod/terraform.tfvars.example terraform/envs/prod/terraform.tfvars

# Edit placeholders — REQUIRED
# gitlab_project_path = "your-group/boutique-eks-gitops"
# optionally tighten endpoint_public_access_cidrs

grep gitlab_project_path terraform/envs/prod/terraform.tfvars
git check-ignore -q terraform/envs/prod/terraform.tfvars && echo "tfvars ignored: OK"
```

### GUI instructions (if applicable)

N/A for file review. Optional: open modules’ `README.md` files in the editor.

### Expected output

`REPLACE_ME` gone from `gitlab_project_path`. `tfvars ignored: OK`.

### Validation

```bash
! grep -q 'REPLACE_ME' terraform/envs/prod/terraform.tfvars
test -f terraform/modules/network/main.tf
test -f terraform/modules/eks/main.tf
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| tfvars shows in git status | Not ignored | Confirm `.gitignore` has `**/terraform.tfvars` |
| Unknown GitLab path | Project not created | Create project or use correct `group/name` |

### Recovery

Re-copy example; fix values; do not commit `terraform.tfvars`.

### Best practices

Tighten `endpoint_public_access_cidrs` to your IP `/32` for the pilot if you have a stable egress IP.

### Security notes

CI role must **not** gain `eks:*` — module enforces ECR-only. Do not widen that policy “to unblock deploys.”

---

## Step 4.2: Terraform plan (full foundation)

### Goal

Generate and review a full plan for network + EKS + ECR + DNS/ACM + IAM.

### Why this step is required

Plan is the last cheap checkpoint before NAT/EKS charges start.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)/terraform/envs/prod"

terraform init -backend-config=../../backend.hcl -upgrade
terraform fmt -recursive ../..
terraform validate
terraform plan -out=tfplan
```

Expected duration: plan usually 1–3 minutes.

### GUI instructions (if applicable)

N/A.

### Expected output

`terraform validate` succeeds. Plan shows create for VPC, NAT, EKS, node group, ECR repos, ACM, OIDC providers/roles, IRSA roles. **No destroy** of unrelated resources.

### Validation

```bash
terraform show -no-color tfplan | head -100
# Confirm: region eu-central-1 concepts, cluster 1.31, m6i.large, single NAT implied
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Zone not found | Wrong account / zone name | Fix `dns_zone_name`; confirm Topic 01 |
| Provider auth error | AWS creds | `aws sts get-caller-identity` |
| OIDC GitLab thumbprint fail | Network / URL | Check `gitlab_url` reachable |

### Recovery

Fix tfvars/IAM; re-plan. Do not apply a plan you do not understand.

### Best practices

Save plan log privately for change audit.

### Security notes

Reject plans that add AdministratorAccess to the GitLab CI role.

---

## Step 4.3: Apply network (VPC, subnets, NAT, endpoints)

### Goal

Create the VPC foundation (or apply as part of full stack — see note).

### Why this step is required

Private subnets + single NAT + VPC endpoints are required before EKS nodes can pull images economically.

### Commands

**Recommended (first pilot): apply the whole stack in Step 4.3–4.8 as one apply** after reviewing the plan:

```bash
cd "$(git rev-parse --show-toplevel)/terraform/envs/prod"
terraform apply tfplan
```

Expected duration: **20–40 minutes** (EKS + node group dominate).

**Optional stepwise learning** (only if teaching `-target`; reconcile with full apply after):

```bash
terraform apply -target=module.network -auto-approve
```

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | AWS Console |
| Navigation | **VPC** → Your VPCs → select `boutique-eks-gitops-vpc` |
| Permissions | Read VPC |
| Verification | 1 NAT Gateway; public + private subnets across AZs; S3/ECR endpoints |

### Expected output

Apply completes without error (full apply also creates later modules).

### Validation

```bash
terraform output vpc_id
terraform output private_subnet_ids
aws ec2 describe-nat-gateways --filter Name=tag:Project,Values=boutique-eks-gitops \
  --query 'NatGateways[?State==`available`].NatGatewayId' --output text
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| AZ capacity | Region AZ limited | Reduce `az_count` to 2; re-plan |
| EIP limit | Account quota | Request quota or release unused EIPs |

### Recovery

`terraform destroy -target=module.network` only if **nothing else** depends on it yet; otherwise use Topic 14 order.

### Best practices

Prefer one full `terraform apply` over many `-target` applies for the final state.

### Security notes

No public node subnets — nodes stay private.

---

## Step 4.4: Apply / verify EKS + node group

### Goal

Ensure EKS 1.31 is Active and the managed node group reaches desired size.

### Why this step is required

Cluster access is the gate for all Kubernetes work.

### Commands

If you already ran full apply in 4.3, skip apply and validate only:

```bash
cd "$(git rev-parse --show-toplevel)/terraform/envs/prod"
terraform output cluster_name
aws eks describe-cluster --name "$(terraform output -raw cluster_name)" --region eu-central-1 \
  --query 'cluster.{status:status,version:version}' --output table
```

Optional target-only path:

```bash
terraform apply -target=module.eks -auto-approve
```

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | AWS Console |
| Navigation | **EKS** → Clusters → `boutique-eks-gitops` |
| Permissions | `eks:DescribeCluster` |
| Verification | Status **Active**; Kubernetes version **1.31**; Compute tab shows node group |

### Expected output

Cluster status `ACTIVE`, version `1.31`.

### Validation

```bash
aws eks wait cluster-active --name "$(terraform output -raw cluster_name)" --region eu-central-1
echo "cluster active: OK"
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Node group `CREATE_FAILED` | Instance type unavailable | Switch `node_instance_types` to `["m7i.large"]` and apply |
| Long CREATE | Normal | Wait up to ~25 minutes |

### Recovery

Check CloudWatch / EKS console events; fix instance type; re-apply.

### Best practices

Do not enable unnecessary add-ons outside GitOps later topics.

### Security notes

Public API with `0.0.0.0/0` is pilot-only — tighten CIDRs when practical.

---

## Step 4.5: Verify ECR repositories (7 services)

### Goal

Confirm seven immutable, scan-on-push ECR repositories exist.

### Why this step is required

Topics 09–10 push digests here; missing repos block bootstrap images.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)/terraform/envs/prod"
terraform output ecr_repository_urls
aws ecr describe-repositories --region eu-central-1 \
  --query 'repositories[?starts_with(repositoryName, `boutique-eks-gitops/`)].repositoryName' \
  --output table
```

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | AWS Console |
| Navigation | **ECR** → Repositories |
| Verification | Seven repos under `boutique-eks-gitops/…`; tag immutability on; scan on push on |

### Expected output

Repos for: frontend, productcatalogservice, cartservice, checkoutservice, currencyservice, paymentservice, shippingservice.

### Validation

```bash
terraform output -json ecr_repository_urls | jq 'keys | length'
# expect 7
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Count ≠ 7 | Apply incomplete | `terraform apply` again |

### Recovery

Re-apply `module.ecr`; do not manually create divergent repo names.

### Best practices

Keep repository names stable — CI and charts depend on them.

### Security notes

Immutable tags + scan-on-push support digest-only supply chain.

---

## Step 4.6: Verify DNS data + ACM certificate

### Goal

Confirm ACM certificate is **ISSUED** for boutique hosts.

### Why this step is required

Topic 05 ALB HTTPS needs a validated ACM ARN.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)/terraform/envs/prod"
terraform output acm_certificate_arn
terraform output route53_zone_id

aws acm describe-certificate \
  --certificate-arn "$(terraform output -raw acm_certificate_arn)" \
  --region eu-central-1 \
  --query 'Certificate.Status' --output text
```

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | AWS Console |
| Navigation | **ACM** → Certificates (region `eu-central-1`) → boutique cert |
| Verification | Status **Issued**; SANs include `*.boutique.biroltilki.art`, env hosts |

DNS validation records are created automatically by the `dns` module in Route53.

### Expected output

`ISSUED`

### Validation

```bash
test "$(aws acm describe-certificate --certificate-arn "$(terraform output -raw acm_certificate_arn)" --region eu-central-1 --query 'Certificate.Status' --output text)" = "ISSUED"
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `PENDING_VALIDATION` | DNS not visible | Wait; confirm zone is public and in this account |
| Validation timeout | Wrong zone | Fix `dns_zone_name` |

### Recovery

Do not delete validation CNAMEs manually while Terraform manages them. Re-apply `module.dns`.

### Best practices

Save `acm_certificate_arn` for Ingress annotations in Topic 05.

### Security notes

Certificates are public-trust; private keys never leave ACM.

---

## Step 4.7: Verify GitLab OIDC provider + CI role

### Goal

Confirm IAM OIDC provider for GitLab and ECR-scoped CI role exist.

### Why this step is required

Topic 10 federates pipelines into this role; fixing trust later blocks CI.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)/terraform/envs/prod"
terraform output gitlab_ci_role_arn

aws iam get-role --role-name boutique-eks-gitops-gitlab-ci \
  --query 'Role.AssumeRolePolicyDocument' --output json
```

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | AWS Console |
| Navigation | **IAM** → **Identity providers** → GitLab URL · **Roles** → `boutique-eks-gitops-gitlab-ci` |
| Verification | Trust shows `AssumeRoleWithWebIdentity`; permissions limited to ECR |

### Expected output

Role ARN printed; trust policy references GitLab OIDC; **no** `eks:*` actions in role policies.

### Validation

```bash
aws iam list-role-policies --role-name boutique-eks-gitops-gitlab-ci
aws iam get-role-policy --role-name boutique-eks-gitops-gitlab-ci --policy-name ecr-push \
  --query 'PolicyDocument.Statement[].Action' --output json
# Confirm ECR actions only; hop-test deferred to Topic 10
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Wrong project path in trust | tfvars typo | Fix `gitlab_project_path`; apply |

### Recovery

Update tfvars; `terraform apply`; re-check trust `sub` condition.

### Best practices

Document the role ARN in private run notes for GitLab CI variables (Topic 10).

### Security notes

Never attach AdministratorAccess or EKS deploy policies to this role.

---

## Step 4.8: Verify IRSA scaffolding outputs

### Goal

Confirm IRSA role ARNs for aws-load-balancer-controller, external-dns, and external-secrets.

### Why this step is required

Topic 05/07 annotate ServiceAccounts with these ARNs.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)/terraform/envs/prod"
terraform output irsa_aws_lb_controller_role_arn
terraform output irsa_external_dns_role_arn
terraform output irsa_external_secrets_role_arn
```

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | AWS Console |
| Navigation | IAM → Roles → filter `boutique-eks-gitops-` |
| Verification | Three IRSA roles exist; trust to EKS OIDC + specific `system:serviceaccount:…` |

### Expected output

Three ARNs.

### Validation

```bash
terraform output -json | jq '{lb:.irsa_aws_lb_controller_role_arn,dns:.irsa_external_dns_role_arn,eso:.irsa_external_secrets_role_arn}'
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Missing outputs | Apply incomplete | Full `terraform apply` |

### Recovery

Re-apply root module; do not hand-craft duplicate roles with different names.

### Best practices

Keep SA names in sync with GitOps values in Topic 05 (`aws-load-balancer-controller`, `external-dns`).

### Security notes

IRSA policies are broader for LB controller (AWS sample style) — do not reuse that role for app pods.

---

## Step 4.9: Update kubeconfig and validate nodes Ready

### Goal

Access the cluster with kubectl and see Ready nodes.

### Why this step is required

Proves IAM authenticator path and node registration before installing controllers.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)/terraform/envs/prod"
eval "$(terraform output -raw configure_kubectl)"
# or: aws eks update-kubeconfig --region eu-central-1 --name "$(terraform output -raw cluster_name)"

kubectl cluster-info
kubectl get nodes -o wide
kubectl get ns
```

### GUI instructions (if applicable)

N/A (CLI). CloudShell can run the same commands if local kubeconfig is inconvenient.

### Expected output

Three nodes (desired) in `Ready` state; default namespaces listed.

### Validation

```bash
kubectl get nodes --no-headers | awk '{print $2}' | grep -c '^Ready$' 
# expect >= 2 (desired 3)
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `Unauthorized` | Wrong AWS principal | Use same identity that created cluster (creator admin) or add access entry |
| Nodes `NotReady` | CNI / subnet | Check node group events; security groups; re-create node group |

### Recovery

Fix IAM access entries; do not recreate VPC casually. Partner can help interpret `kubectl describe node`.

### Best practices

Keep one kubeconfig context name per cluster; avoid mixing accounts.

### Security notes

Kubeconfig uses AWS IAM — protect your AWS session; no static cluster tokens in Git.

---

## Step 4.10: Topic validation (gate to Topic 05)

### Goal

Run the consolidated foundation checklist.

### Why this step is required

Topic 05 assumes Ready nodes, ACM issued, and IRSA ARNs.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)/terraform/envs/prod"

terraform output
kubectl get nodes
aws eks describe-cluster --name "$(terraform output -raw cluster_name)" --query 'cluster.status' --output text
aws acm describe-certificate --certificate-arn "$(terraform output -raw acm_certificate_arn)" --query 'Certificate.Status' --output text
terraform output -json ecr_repository_urls | jq 'length'
```

### GUI instructions (if applicable)

Spot-check EKS Active + ACM Issued in console.

### Expected output

All green per checklist below.

### Validation

- [ ] `terraform plan` shows no unexpected churn (optional refresh plan)
- [ ] VPC + single NAT present
- [ ] EKS Active, version 1.31
- [ ] Nodes Ready (≈3)
- [ ] 7 ECR repositories
- [ ] ACM **ISSUED**
- [ ] GitLab CI role ARN present (ECR-only)
- [ ] Three IRSA role ARNs present
- [ ] State still in S3 (Topic 03 backend)
- [ ] Cost awareness acknowledged; teardown path is Topic 14

### Common problems

Any failure — return to the matching step; do not install Ingress yet.

### Recovery

Fix and re-validate 4.10 only after the failing component is healthy.

### Best practices

Export outputs to a private notes file for Topic 05 annotations.

### Security notes

Confirm CI role still lacks cluster deploy permissions before celebrating.

---

## Topic validation (end-to-end)

Topic 04 is complete when Step 4.10 checklist passes.

**Cost check:** Billable EKS + NAT + nodes are running — do not leave idle overnight without intent; Topic 14 destroys them.

---

## Topic troubleshooting

| Area | Symptom | Action |
|------|---------|--------|
| Apply | `Error creating IAM OIDC` for GitLab | Provider may already exist — import or rename |
| Nodes | Wrong instance generation | Use `m7i.large` fallback; document deviation |
| ACM | Stuck pending | Check public zone delegation / correct account |
| Kubectl | Works locally, not in CI | Expected — CI must not use kubeconfig (ADR-0001) |

---

## Next step

**[05 — Ingress, DNS, TLS](05-ingress-dns-tls.md)** (Phase B next).

Use IRSA ARNs and `acm_certificate_arn` from outputs when authoring/installing controllers.
