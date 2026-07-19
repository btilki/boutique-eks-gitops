# Terraform — boutique-eks-gitops

AWS foundation for the pilot (remote state, VPC, EKS, ECR, IAM OIDC/IRSA, DNS/ACM data).

**Setup authority:** Topics [03](../docs/setup/03-remote-state.md) and [04](../docs/setup/04-network-eks-ecr-iam.md)  
**Pins:** [docs/versions.md](../docs/versions.md)

## Layout

```text
terraform/
├── README.md
├── backend.hcl.example
├── modules/
│   ├── network/           # VPC, 1× NAT, S3/ECR endpoints
│   ├── eks/               # EKS 1.31 + node group + cluster OIDC
│   ├── ecr/               # 7 service repositories
│   ├── dns/               # Route53 zone data + ACM
│   ├── iam_gitlab_oidc/   # GitLab OIDC → ECR role
│   └── irsa/              # Reusable IRSA helper
└── envs/prod/             # Root module wiring
```

## Modules

| Module | Purpose |
|--------|---------|
| `network` | VPC, subnets, **1× NAT**, S3/ECR endpoints |
| `eks` | EKS 1.31, node group `m6i.large` ASG 2–5 |
| `ecr` | 7 repos, scan-on-push, immutable tags |
| `dns` | Zone data + ACM cert for boutique hosts |
| `iam_gitlab_oidc` | GitLab OIDC provider + CI role (ECR only) |
| `irsa` | Reusable IRSA role helper |

## Rules

- No secrets in committed `tfvars` — use `terraform.tfvars.example` only.
- Local `backend.hcl` and `terraform.tfvars` are gitignored.
- Never apply from ad-hoc scripts that bypass `docs/setup/`.
- GitLab CI role must never gain cluster deploy permissions.

## Apply entrypoint

```bash
cd terraform/envs/prod
terraform init -backend-config=../../backend.hcl
terraform plan
# Follow docs/setup/04-network-eks-ecr-iam.md before apply
```
