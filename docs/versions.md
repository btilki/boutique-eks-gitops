# Version pin matrix — boutique-eks-gitops

**Audience:** L2 — Implementer / CI author  
**Authority:** Locked stack from Planning Gate + [implementation plan](implementation/plan.md) §7.11  
**Setup owner:** Topic 01 (consume) · Topic 02 (align ADRs/README)  
**Last reviewed:** 2026-07-18

Do not drift these pins without an ADR update and Setup Guide revision.

---

## Cloud & region

| Item | Pin | Notes |
|------|-----|--------|
| AWS region | `eu-central-1` | Locked |
| DNS zone | `biroltilki.art` | Route53 |
| EKS version | **1.31** | Control plane + kubectl minor match |
| Node instance | `m6i.large` ×3 (ASG 2–5) | On-Demand; fallback `m7i.large` if capacity fails (document in setup) |

---

## Local CLI (Topic 01 verify)

| Tool | Required version | Why |
|------|------------------|-----|
| AWS CLI | v2.x (latest stable 2.x) | IAM, EKS kubeconfig, ECR |
| Terraform | **≥ 1.9** | Backend + module features used in foundation |
| kubectl | **1.31.x** | Within one minor of EKS 1.31 |
| Helm | **3.16.x** | Platform chart installs |
| git | 2.40+ (any modern) | Repo + digest MRs |
| jq | 1.6+ | JSON validation snippets |
| curl | any modern | HTTPS smoke checks |

### Optional on workstation (required in CI — Topic 10)

| Tool | Required version | Why |
|------|------------------|-----|
| Trivy | **0.71.0** | CRITICAL gate — pin exact in CI image/job |
| cosign | **2.4.x** | Sigstore keyless sign (GitLab OIDC) |

---

## Terraform providers

| Provider | Constraint |
|----------|------------|
| `hashicorp/aws` | `~> 5.80` |
| `hashicorp/kubernetes` | Pin when first used (Topic 04+/modules) — `TODO(setup:4.1)` |
| `hashicorp/helm` | Pin when first used — `TODO(setup:4.1)` |

---

## Cluster add-ons & platform (chart / app pins)

Exact chart versions are confirmed when each platform topic is authored. Treat the following as **target pins**; Phase B topics 05–12 must write the concrete `chartVersion` / image tags into GitOps values.

| Component | Target pin | First setup topic |
|-----------|------------|-------------------|
| AWS Load Balancer Controller | **v2.11.0** (Helm chart **1.11.0**) | 05 |
| external-dns | **v0.15.1** (Helm chart **1.15.0**) | 05 |
| cert-manager | **v1.16.2** (Helm chart **v1.16.2**) | 05 |
| Argo CD | **v2.14.x** (Helm chart **7.8.14**) | 06 |
| Kyverno | **1.16.x** (Helm chart **3.3.7**) | 07 |
| External Secrets Operator | **0.14.x** (Helm chart **0.14.4**) | 07 |
| kube-prometheus-stack | **chart 69.8.0** (pin at Topic 08) | 08 |
| Grafana Loki | **chart 6.24.0** (Loki 3.x) | 08 |
| Argo Rollouts | **v1.8.2** (Helm chart **2.39.5**) | 12 |

---

## Supply chain (CI)

| Item | Pin |
|------|-----|
| Trivy | **0.71.0** |
| cosign | **2.4.x** |
| Signing mode | Sigstore **keyless** via GitLab OIDC (`SIGSTORE_ID_TOKEN`) |
| Image references in Git | **digest only** (`image.digest`); never `:latest` |

---

## Governance

| Item | Value |
|------|--------|
| CODEOWNERS (prod digests) | `@btilki` on `gitops/envs/prod/**` |
| Prod Argo sync | **Manual** (no automated sync) |

---

## Verification snippet (Topic 01)

```bash
terraform version   # >= 1.9
kubectl version --client
helm version
aws --version
git --version
jq --version
```

Expected: kubectl client reports **1.31.x**; Helm **v3.16.x**; Terraform **v1.9+**.
