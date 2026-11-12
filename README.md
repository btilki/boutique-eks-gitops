# boutique-eks-gitops

Production-pilot GitOps platform for Online Boutique on Amazon EKS — Git is the only deploy authority.

[![Terraform](https://img.shields.io/badge/terraform-%3E%3D1.9-purple.svg)](https://www.terraform.io/)
[![EKS](https://img.shields.io/badge/EKS-1.31-FF9900.svg)](https://aws.amazon.com/eks/)
[![GitLab CI](https://img.shields.io/badge/CI-GitLab%20CI-FC6D26.svg)](https://docs.gitlab.com/ee/ci/)
[![Argo CD](https://img.shields.io/badge/GitOps-Argo%20CD-EF7B4D.svg)](https://argo-cd.readthedocs.io/)
[![Maturity](https://img.shields.io/badge/maturity-production%20pilot-blue.svg)](docs/ARCHITECTURE.md)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

> **Status:** Production pilot closed (July 2026). Digest MR → promote → prod (manual sync and canary) ran end to end; then all AWS billable resources were destroyed. No live cluster. To run again, follow [`docs/setup/`](docs/setup/).

---

## Problem

Tag-based deploys and CI `kubectl`/`argocd` pushes make “what is running?” hard to audit and easy to drift. `:latest` and mutable tags break immutability; a pipeline with cluster credentials becomes a second deploy authority next to Git.

## Decision

- **Digest-only** image pins in Git; promotion is `dev → stage → prod` via MRs that change digests only ([ADR-0001](docs/adr/0001-digest-only-gitops.md)).
- **CI never deploys** — GitLab CI builds/retags, scans (Trivy), signs (cosign), and opens digest MRs; Argo CD pulls and reconciles.
- **Manual Argo sync for prod**; lower envs can auto-sync. Single EKS cluster, three namespaces (cost over blast-radius isolation).

## Result

Milestone 3 (production-pilot path) and Milestone 4 (clean teardown) completed. Cost stayed in the short-pilot band (~$35–45 with teardown vs ~$350–500/mo if left running). Screenshots from the live run are below; file-backed claims: [`docs/pilot-claims.md`](docs/pilot-claims.md).

---

## At a glance

| | |
|-|-|
| What | Digest-only GitOps on one EKS cluster in `eu-central-1` |
| Hard rule | **CI never deploys** — GitLab CI opens digest MRs; Argo CD reconciles from Git |
| Scope | Production pilot — one account, one region; not multi-region HA |
| Stack | Terraform · EKS 1.31 · Argo CD · Rollouts · Kyverno · Prometheus / Loki / Grafana |

---

## Proof

Pilot captures (~2026-07-19). Full captions and gaps: [`docs/evidence/`](docs/evidence/README.md).

**Argo CD** — 40 apps Healthy on `argocd.boutique.biroltilki.art` (4 OutOfSync at capture; not named in this crop):

![Argo CD applications dashboard](assets/images/setup/06-argocd-applications-dashboard.png)

**GitLab CI** — pipeline `#2688809559` passed: lint → build → scan → sign → `gitops_digest_mr` (Jobs tab / MR diff not in this crop):

![GitLab CI pipeline passed](assets/images/setup/10-gitlab-ci-pipeline-passed.png)

**Storefront** — `https://dev-boutique.biroltilki.art` over HTTPS. The purple `local` badge is the Boutique demo default when `ENV_PLATFORM` is unset — not a local Docker run:

![Boutique dev homepage](assets/images/setup/09-boutique-dev-homepage.png)

More: stage/prod storefronts, Grafana list — [`docs/evidence/`](docs/evidence/README.md). Not in repo yet: Kyverno deny, digest MR diff, canary UI, alert email, teardown logs.

---

## Tradeoffs / what I would change for real production

- **Single cluster, three namespaces** — fine for a cost-capped pilot; not true env isolation. Multi-account or separate clusters for prod.
- **Single NAT** — documented cost tradeoff; HA egress would use NAT per AZ.
- **CODEOWNERS is solo (`@btilki`)** — without GitLab “Code owner approval” enabled, the file is documentation-only, not enforced dual control ([`CODEOWNERS`](CODEOWNERS)).
- **Email-only Alertmanager** — no PagerDuty; SLOs / burn-rate alerts would come next.
- **Pins match the July 2026 evidence matrix** (EKS 1.31, Argo CD 2.14.x). A rebuild starts by bumping [`docs/versions.md`](docs/versions.md) and following [`docs/operations/13-upgrades.md`](docs/operations/13-upgrades.md).

Lessons from the pilot: [`docs/lessons-learned.md`](docs/lessons-learned.md). Optional hardening ideas after a rebuild (not part of the closed pilot): [`docs/setup/README.md`](docs/setup/README.md#optional-after-rebuild-phase-12-scaffolds--not-part-of-the-closed-pilot).

---

## Where to start

| I want to… | Read |
|------------|------|
| Understand the project in ~10 minutes | This page → [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) → [ADR-0001](docs/adr/0001-digest-only-gitops.md) |
| See pilot proof | [`docs/evidence/`](docs/evidence/README.md) · [`docs/pilot-claims.md`](docs/pilot-claims.md) |
| Review design and delivery | [`docs/architecture/`](docs/architecture/) · [`docs/promotion.md`](docs/promotion.md) · [`docs/rollback.md`](docs/rollback.md) · [`docs/ci.md`](docs/ci.md) |
| Rebuild or operate | [`docs/setup/`](docs/setup/) (topics 01–14) · [`docs/versions.md`](docs/versions.md) · [`docs/PRODUCTION_CHECKLIST.md`](docs/PRODUCTION_CHECKLIST.md) · [`docs/runbooks/`](docs/runbooks/README.md) |

Full index: [`docs/README.md`](docs/README.md)

---

## GitOps flow (summary)

```mermaid
flowchart LR
  GL[GitLab CI] -->|digest MR only| Git[(Git)]
  GL -->|OIDC push| ECR[ECR]
  Git -->|pull| Argo[Argo CD]
  Argo --> Dev[dev]
  Argo --> Stage[stage]
  Argo --> Prod[prod]
  Users((Users)) -->|HTTPS ACM+ALB| Dev & Stage & Prod
```

Promotion: `dev → stage → prod` (digest-only MRs; **manual Argo sync for prod**). Details: [`docs/architecture/05-deployment-flow.md`](docs/architecture/05-deployment-flow.md).

---

## Repository map and navigation

Use this map for repository layout, platform components, and where each engineering area lives.

![Boutique EKS GitOps Platform — Repository Map and Navigation](assets/images/aws-eks-gitops-platform-architecture.png)

---

## What the pilot demonstrated

- Digest-only releases with promotion `dev → stage → prod` and manual prod sync
- Argo CD app-of-apps + ApplicationSet; Kyverno, External Secrets, NetworkPolicy
- GitLab CI: scan (Trivy) → sign (cosign) → digest MR only (no `kubectl` / `argocd` in CI)
- On-cluster observability (Prometheus, Loki, Grafana, Alertmanager → email) and frontend canary on stage and prod
- Ordered teardown after validation (see [`ROADMAP.md`](ROADMAP.md))

---

## Technology stack

| Area | Choices |
|------|---------|
| Cloud / region | AWS `eu-central-1` |
| IaC | Terraform ≥ 1.9 |
| Kubernetes | EKS 1.31, Helm 3.16.x |
| GitOps / delivery | Argo CD, Argo Rollouts |
| Policy / secrets | Kyverno, External Secrets Operator |
| Ingress / TLS | AWS LB Controller, external-dns, ACM |
| CI / supply chain | GitLab CI, ECR, Trivy, Sigstore cosign |
| Observability | kube-prometheus-stack, Loki, Grafana |

Pins and rationale: [`docs/versions.md`](docs/versions.md) · [`docs/architecture/README.md`](docs/architecture/README.md)

---

## Repository layout

```text
boutique-eks-gitops/
├── terraform/        # VPC, EKS, ECR, IAM, remote state
├── gitops/           # Argo CD desired state (bootstrap, platform, envs)
├── charts/           # Boutique Helm charts (7 services + Redis)
├── docs/             # Architecture, setup guide, runbooks, ADRs
├── tests/            # Policy and lint fixtures
└── .gitlab-ci.yml    # Digest pipeline (dormant until CI flags are set)
```

---

## Quick clone

```bash
git clone https://github.com/btilki/boutique-eks-gitops.git
cd boutique-eks-gitops
```

Do not provision AWS from this file. Bootstrap and destroy live under [`docs/setup/`](docs/setup/).

---

## Contributing · License · References

- Contributing: [`CONTRIBUTING.md`](CONTRIBUTING.md)
- Security: [`SECURITY.md`](SECURITY.md)
- Changelog: [`CHANGELOG.md`](CHANGELOG.md)
- Roadmap: [`ROADMAP.md`](ROADMAP.md)

Licensed under Apache License 2.0 — see [`LICENSE`](LICENSE). Upstream app inspiration: [Google Online Boutique](https://github.com/GoogleCloudPlatform/microservices-demo).

Stack references: [Argo CD](https://argo-cd.readthedocs.io/) · [Argo Rollouts](https://argo-rollouts.readthedocs.io/) · [Kyverno](https://kyverno.io/) · [External Secrets](https://external-secrets.io/) · [cosign](https://docs.sigstore.dev/) · [Trivy](https://trivy.dev/) · [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
