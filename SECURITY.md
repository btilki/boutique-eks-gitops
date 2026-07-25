# Security — boutique-eks-gitops

**Audience:** Engineers operating or reviewing this control plane  
**Related:** [docs/architecture/07-security-architecture.md](docs/architecture/07-security-architecture.md) · Setup Topics [07](docs/setup/07-security-baseline.md) · [15](docs/setup/15-supply-chain-verify-sbom.md)

## Principles

| Principle | How we apply it |
|-----------|-----------------|
| Least privilege | IRSA for controllers; GitLab OIDC role scoped to ECR (no cluster deploy from CI) |
| Secrets hygiene | AWS Secrets Manager / SSM → External Secrets Operator; **never** commit secrets |
| Supply chain | Trivy CRITICAL gate → cosign Sigstore keyless → CycloneDX SBOM attest → digest-only Git references |
| Admission | Kyverno: deny `:latest`, require digests, ECR allowlist; signature/SBOM verify (**Audit** scaffold, Topic 15) |
| Network | Default-deny NetworkPolicy patterns in app namespaces |
| Prod governance | CODEOWNERS `@btilki` on `gitops/envs/prod/**`; Argo **manual** sync for prod |
| Argo projects | `boutique-platform` / `boutique-workloads` (Topic 17); SSO/notifications example-only until enabled |
| Edge / runtime | WAFv2 + Falco **scaffolded, off by default** (Topic 19) |

## Trust boundaries (summary)

1. **Human + GitLab** — change desired state via MR  
2. **Argo CD** — only reconciler with cluster write for apps/platform  
3. **AWS account** — VPC, EKS, ECR, IAM, Route53, ACM  
4. **SMTP** — Alertmanager egress only (credentials via ESO)

## Reporting

If you find a vulnerability in this repository’s configs or docs, open a confidential issue with your GitLab project owner (`@btilki`) — do not file public issues with exploit details for live accounts.

## Honest limits

Namespace isolation on a **single** cluster is not multi-account isolation. Short pilots must run **Topic 14 teardown** immediately after tests to remove blast radius and cost.
