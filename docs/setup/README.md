# Setup Guide — boutique-eks-gitops

Audience: Implementer  
Authority: This directory is the **single source of truth** for bootstrap. If README, chat, or scripts conflict with `docs/setup/`, this guide wins.  
[Doc index](../README.md) · [Architecture summary](../ARCHITECTURE.md) · [Roadmap](../../ROADMAP.md) · Maintainer: [OUTLINES](OUTLINES.md) · [REQUIRED-FILES](REQUIRED-FILES.md)

> **Pilot status:** Production pilot closed. Milestone 3 (production-pilot path) and Milestone 4 (clean teardown) are complete.  
> There is no live AWS stack — no EKS, VPC, NAT, ALB, ECR, Terraform backend, Secrets Manager, ACM, or Route53 zone from the pilot.  
> This guide is for step-by-step rebuild and validation. Follow topics 01 → 14 in order unless you abort early (still use Topic 14 teardown order). Milestone definitions: [ROADMAP — Milestones](../../ROADMAP.md#milestones).  
> Do not assume a cluster already exists because the repo is complete in Git.

---

## Overview

| Field | Value |
|-------|--------|
| End-to-end goal | Provision one EKS cluster in `eu-central-1`, GitOps platform (Argo CD + security + observability), Online Boutique on digest-pinned Helm, GitLab CI digest MRs, promotion + canary, then ordered teardown |
| Environments | `dev`, `stage`, `prod` as namespaces on one cluster |
| Estimated calendar time | ~4–8 working sessions (plan-dependent); teardown is mandatory after tests |
| Estimated cost | ~$35–45 for a ~2-day pilot with teardown; ~$350–500/mo if left running — see [cost model](../architecture/10-cost-model.md) |
| Who executes | You run every CLI / GUI step |
| Phase status | Topics 01–14 complete (Milestone 3 and Milestone 4) · pilot closed · Phase 12 scaffold: Topics 15–19 authored |

Do not skip topics after an error. Do not replace documented steps with install-all scripts unless explicitly requested.

---

## Topic sequence

Status legend: ⬜ Not started · 🔄 In progress · 🚧 Scaffold (in-repo; enable after rebuild) · ✅ Complete · ⏭️ Skipped (document risk)

| # | Topic | Guide | Prerequisites | Est. time | Cost impact | Status |
|---|--------|-------|---------------|-----------|-------------|--------|
| 01 | Prerequisites | [01-prerequisites.md](01-prerequisites.md) | None | 45–60 min | None | ✅ |
| 02 | Repo foundation | [02-repo-foundation.md](02-repo-foundation.md) | 01 | 2–3 h | None | ✅ |
| 03 | Terraform remote state | [03-remote-state.md](03-remote-state.md) | 02 | 45–60 min | S3 + DynamoDB (low) | ✅ |
| 04 | Network, EKS, ECR, IAM | [04-network-eks-ecr-iam.md](04-network-eks-ecr-iam.md) | 03 | 2–4 h | High (EKS, NAT, nodes) | ✅ |
| 05 | Ingress, DNS, TLS | [05-ingress-dns-tls.md](05-ingress-dns-tls.md) | 04 | 1.5–2.5 h | ALB hours | ✅ |
| 06 | Argo CD bootstrap | [06-argocd-bootstrap.md](06-argocd-bootstrap.md) | 05 | 1.5–2 h | Cluster compute | ✅ |
| 07 | Security baseline | [07-security-baseline.md](07-security-baseline.md) | 06 | 1.5–2 h | Cluster compute | ✅ |
| 08 | Observability | [08-observability.md](08-observability.md) | 07 | 2–3 h | Cluster memory/CPU | ✅ |
| 09 | Boutique charts | [09-boutique-charts.md](09-boutique-charts.md) | 08 | 3–4 h | ECR storage + ALB | ✅ |
| 10 | GitLab CI digests | [10-gitlab-ci-digest.md](10-gitlab-ci-digest.md) | 09 (+ OIDC from 04) | 2–3 h | CI runners + ECR | ✅ |
| 11 | Promotion | [11-promotion.md](11-promotion.md) | 10 | 1–1.5 h | None beyond envs | ✅ |
| 12 | Canary rollouts | [12-canary-rollouts.md](12-canary-rollouts.md) | 11 | 1.5–2.5 h | Extra pods briefly | ✅ |
| 13 | Production-pilot checklist | [13-production-readiness.md](13-production-readiness.md) | 12 | 1–2 h | None | ✅ |
| 14 | Teardown | [14-teardown.md](14-teardown.md) | 13 (or early abort) | 1–2 h | Stops billables | ✅ |
| 15 | Supply chain verify + SBOM | [15-supply-chain-verify-sbom.md](15-supply-chain-verify-sbom.md) | 07 + 10 (live after rebuild) | 1–2 h | None while scaffold-only | 🚧 Scaffold |
| 16 | CI security gates | [16-ci-security-gates.md](16-ci-security-gates.md) | 10 (CI files); no AWS for MR gates | 1–1.5 h | None | 🚧 Scaffold |
| 17 | Argo CD hardening | [17-argocd-hardening.md](17-argocd-hardening.md) | 06 (live after rebuild) | 1.5–2 h | None while scaffold-only | 🚧 Scaffold |
| 18 | Canary AnalysisTemplates | [18-canary-analysis.md](18-canary-analysis.md) | 12 + 08 (live after rebuild) | 1–1.5 h | None while scaffold-only | 🚧 Scaffold |
| 19 | Edge WAF + Falco | [19-edge-runtime-waf-falco.md](19-edge-runtime-waf-falco.md) | 04–06 (WAF); 08 helpful (Falco) | 1–2 h | WAF/Falco only when enabled | 🚧 Scaffold |

Dependency rule: complete topics in numeric order through 14 for the original pilot. Topics 15–19 are Phase 12 scaffolds: author anytime; live apply after the listed prerequisites on a rebuilt cluster. Topic 10 additionally requires GitLab OIDC IAM from topic 04. Topic 14 may run early if you abort the pilot — still follow ordered destroy.

Planning artifacts (Phase A):

- [OUTLINES.md](OUTLINES.md) — step sketches for topics 01–14
- [REQUIRED-FILES.md](REQUIRED-FILES.md) — file inventory per topic

Topic guides 01–14 are authored; live execution through Topic 13 is complete for this pilot.

---

## Conventions

| Convention | Value |
|------------|--------|
| Shell / OS | bash or zsh on macOS/Linux; commands shown for Unix. Windows users: WSL2 |
| AWS region | `eu-central-1` (locked) |
| Cluster | Single EKS 1.31; nodes 3× `m6i.large` (ASG 2–5) |
| DNS zone | `biroltilki.art` (Route53) |
| Terminology | Short form only (CI, EKS, MR). Do not expand in parentheses. Bold only critical rules — see [Terminology](#terminology) |
| Placeholders | Guides use `<ACCOUNT_ID>`, `<GITLAB_PROJECT_PATH>`, `<SMOKE_HOST>` — never commit tokens or SMTP passwords. Env overlays may pin this pilot’s ECR/ACM account IDs so Argo can sync; redact for a public fork (see [CONTRIBUTING.md](../../CONTRIBUTING.md)). |
| Local state | Terraform state in remote S3/DynamoDB after topic 03; kubeconfig via `aws eks update-kubeconfig`; no secrets in Git |
| Version pins | Authoritative matrix in `docs/versions.md` (materialized in topic 02 / used from 01) |
| CODEOWNERS | `@btilki` on `gitops/envs/prod/**` |
| TLS | ACM on ALB primary; cert-manager installed |
| Alerts | Alertmanager → email |
| Signing | Sigstore keyless (GitLab OIDC) |
| First images | Bootstrap ECR digests in topic 09 before first CI digest MR |
| After tests | Topic 14 teardown immediately |

### Terminology

Use short forms in prose. Do not write `CI (Continuous Integration)`. Bold only hard rules (for example **CI never deploys**), not every abbreviation. Glossary:

| Abbreviation | Full form | Owning topic |
|--------------|-----------|--------------|
| AWS | Amazon Web Services | [01](01-prerequisites.md) |
| DNS | Domain Name System | [01](01-prerequisites.md) |
| SMTP | Simple Mail Transfer Protocol | [01](01-prerequisites.md) |
| SSO | AWS IAM Identity Center | [01](01-prerequisites.md) |
| SRE | Site Reliability Engineering | Root [README](../../README.md) (audience) |
| S3 | Simple Storage Service | [03](03-remote-state.md) |
| VPC | Virtual Private Cloud | [04](04-network-eks-ecr-iam.md) |
| EKS | Elastic Kubernetes Service | [04](04-network-eks-ecr-iam.md) |
| ECR | Elastic Container Registry | [04](04-network-eks-ecr-iam.md) |
| IAM | Identity and Access Management | [04](04-network-eks-ecr-iam.md) |
| NAT | Network Address Translation | [04](04-network-eks-ecr-iam.md) |
| OIDC | OpenID Connect | [04](04-network-eks-ecr-iam.md) |
| IRSA | IAM Roles for Service Accounts | [04](04-network-eks-ecr-iam.md) |
| ASG | Auto Scaling Group | [04](04-network-eks-ecr-iam.md) |
| ALB | Application Load Balancer | [05](05-ingress-dns-tls.md) |
| TLS | Transport Layer Security | [05](05-ingress-dns-tls.md) |
| ACM | AWS Certificate Manager | [05](05-ingress-dns-tls.md) |
| GitOps | Git as the deploy authority | [06](06-argocd-bootstrap.md) |
| ESO | External Secrets Operator | [07](07-security-baseline.md) |
| CI | Continuous Integration | [10](10-gitlab-ci-digest.md) |
| MR | Merge Request | [10](10-gitlab-ci-digest.md) |
| SBOM | Software Bill of Materials | [15](15-supply-chain-verify-sbom.md) |
| GUI | Graphical User Interface | Setup Guide (this README) |

DNS / TLS hostnames: [dns-and-tls.md](../dns-and-tls.md) · [ADR-0004](../adr/0004-dns-hostname-scheme.md)

### How to use a topic

1. Confirm prerequisites (prior topics ✅).
2. Execute one step (N.M): Goal → Why → Commands/GUI → Expected output → Validation.
3. Report validation output (or error) before the next step.
4. Mark topic ✅ only after Topic validation passes.

---

## Getting help

### Troubleshooting

- Per-topic Common problems / Recovery / Topic troubleshooting sections (Phase B).
- Runbooks under [`docs/runbooks/`](../runbooks/) (Topics 08 + 13; teardown in 14).
- Architecture context: [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md).

### Failed-step report format

Paste this when a step fails:

```text
Topic: NN — <title>
Step: N.M — <title>
Command or GUI path:
Exit code / UI symptom:
Actual output (trimmed):
Expected (from guide):
Already tried:
```

Partner response pattern: symptom → likely cause → fix (guide and/or files) → re-validation → wait.

---

## Rebuild quick path

| Step | Action |
|------|--------|
| 1 | [01 — Prerequisites](01-prerequisites.md) (access + pins; no AWS billables) |
| 2 | [02 — Repo foundation](02-repo-foundation.md) → [03 — Remote state](03-remote-state.md) |
| 3 | [04 — Network, EKS, ECR, IAM](04-network-eks-ecr-iam.md) onward through [14 — Teardown](14-teardown.md) |
| 4 | Optional scaffolds after cluster is up: Topics [15](15-supply-chain-verify-sbom.md)–[19](19-edge-runtime-waf-falco.md) |

Phase 12 scaffolds (15–19) are in Git; enable only after rebuild and deliberate choice — not required to repeat the original pilot.
