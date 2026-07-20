# Setup Guide — boutique-eks-gitops

**Audience:** L2 — Implementer  
**Authority:** This directory is the **single source of truth** for bootstrap. If README, chat, or scripts conflict with `docs/setup/`, **this guide wins**.  
**Last reviewed:** 2026-07-20  
**Related:** [Architecture](../ARCHITECTURE.md) · [Implementation plan](../implementation/plan.md) · [Roadmap](../../ROADMAP.md) · [Topic outlines](OUTLINES.md) · [Required files](REQUIRED-FILES.md)

---

## Overview

| Field | Value |
|-------|--------|
| **End-to-end goal** | Provision one EKS cluster in `eu-central-1`, GitOps platform (Argo CD + security + observability), Online Boutique on digest-pinned Helm, GitLab CI digest MRs, promotion + canary, then **ordered teardown** |
| **Environments** | `dev`, `stage`, `prod` as namespaces on **one** cluster |
| **Estimated calendar time** | ~4–8 working sessions (plan-dependent); teardown is mandatory after tests |
| **Estimated cost** | ~**$35–45** for a ~2-day pilot with teardown; ~**$350–500/mo** if left running — see [cost model](../architecture/10-cost-model.md) |
| **Who executes** | You run every CLI/GUI step; partner designs and authors guides/files |
| **Phase status** | A ✅ · B ✅ · **C:** Topics **01–14** complete (M3 + M4 PASS) · pilot closed · D optional / rebuild |

**Do not** skip topics after an error. **Do not** replace documented steps with install-all scripts unless explicitly requested.

---

## Topic sequence

Status legend: ⬜ Not started · 🔄 In progress · ✅ Complete · ⏭️ Skipped (document risk)

| # | Topic | Guide | Prerequisites | Est. time | Cost impact | Status |
|---|--------|-------|---------------|-----------|-------------|--------|
| 01 | Prerequisites | [01-prerequisites.md](01-prerequisites.md) | None | 45–60 min | None | ✅ |
| 02 | Repo foundation | [02-repo-foundation.md](02-repo-foundation.md) | 01 | 2–3 h | None | ✅ |
| 03 | Terraform remote state | [03-remote-state.md](03-remote-state.md) | 02 | 45–60 min | S3 + DynamoDB (low) | ✅ |
| 04 | Network, EKS, ECR, IAM | [04-network-eks-ecr-iam.md](04-network-eks-ecr-iam.md) | 03 | 2–4 h | **High** (EKS, NAT, nodes) | ✅ |
| 05 | Ingress, DNS, TLS | [05-ingress-dns-tls.md](05-ingress-dns-tls.md) | 04 | 1.5–2.5 h | ALB hours | ✅ |
| 06 | Argo CD bootstrap | [06-argocd-bootstrap.md](06-argocd-bootstrap.md) | 05 | 1.5–2 h | Cluster compute | ✅ |
| 07 | Security baseline | [07-security-baseline.md](07-security-baseline.md) | 06 | 1.5–2 h | Cluster compute | ✅ |
| 08 | Observability | [08-observability.md](08-observability.md) | 07 | 2–3 h | Cluster memory/CPU | ✅ |
| 09 | Boutique charts | [09-boutique-charts.md](09-boutique-charts.md) | 08 | 3–4 h | ECR storage + ALB | ✅ |
| 10 | GitLab CI digests | [10-gitlab-ci-digest.md](10-gitlab-ci-digest.md) | 09 (+ OIDC from 04) | 2–3 h | CI runners + ECR | ✅ |
| 11 | Promotion | [11-promotion.md](11-promotion.md) | 10 | 1–1.5 h | None beyond envs | ✅ |
| 12 | Canary rollouts | [12-canary-rollouts.md](12-canary-rollouts.md) | 11 | 1.5–2.5 h | Extra pods briefly | ✅ |
| 13 | Production readiness | [13-production-readiness.md](13-production-readiness.md) | 12 | 1–2 h | None | ✅ |
| 14 | Teardown | [14-teardown.md](14-teardown.md) | 13 (or early abort) | 1–2 h | **Stops billables** | ✅ |

**Dependency rule:** complete topics in numeric order. Topic 10 additionally requires GitLab OIDC IAM from topic 04. Topic 14 may run early if you abort the pilot — still follow ordered destroy.

**Planning artifacts (Phase A):**

- [OUTLINES.md](OUTLINES.md) — step sketches for topics 01–14
- [REQUIRED-FILES.md](REQUIRED-FILES.md) — file inventory per topic

Topic guides `01`–`14` are authored; live execution through Topic **13** is complete for this pilot.

---

## Conventions

| Convention | Value |
|------------|--------|
| **Shell / OS** | bash or zsh on macOS/Linux; commands shown for Unix. Windows users: WSL2 |
| **AWS region** | `eu-central-1` (locked) |
| **Cluster** | Single EKS **1.31**; nodes **3× `m6i.large`** (ASG 2–5) |
| **DNS zone** | `biroltilki.art` (Route53) |
| **Placeholders** | Guides use `<ACCOUNT_ID>`, `<GITLAB_PROJECT_PATH>`, `<SMOKE_HOST>` — **never commit tokens or SMTP passwords**. Env overlays may pin this pilot’s ECR/ACM account IDs so Argo can sync; redact for a public fork (see [CONTRIBUTING.md](../../CONTRIBUTING.md)). |
| **Local state** | Terraform state in remote S3/DynamoDB after topic 03; kubeconfig via `aws eks update-kubeconfig`; no secrets in Git |
| **Version pins** | Authoritative matrix in `docs/versions.md` (materialized in topic 02 / used from 01) |
| **CODEOWNERS** | `@btilki` on `gitops/envs/prod/**` |
| **TLS** | ACM on ALB primary; cert-manager installed |
| **Alerts** | Alertmanager → **email** |
| **Signing** | Sigstore **keyless** (GitLab OIDC) |
| **First images** | Bootstrap ECR digests in topic **09** before first CI digest MR |
| **After tests** | Topic **14** teardown **immediately** |

### Locked DNS hostnames

```text
argocd.boutique.biroltilki.art
grafana.boutique.biroltilki.art
dev-boutique.biroltilki.art
stage-boutique.biroltilki.art
boutique.biroltilki.art
```

### How to use a topic (Phase C)

1. Confirm prerequisites (prior topics ✅).
2. Execute **one step** (N.M): Goal → Why → Commands/GUI → Expected output → Validation.
3. Report validation output (or error) before the next step.
4. Mark topic ✅ only after **Topic validation** passes.

---

## Getting help

### Troubleshooting

- Per-topic **Common problems** / **Recovery** / **Topic troubleshooting** sections (Phase B).
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

## Workflow phases (A → B → C → D)

| Phase | Scope | Gate |
|-------|--------|------|
| **A** | Catalog, this index, [outlines](OUTLINES.md), [file inventory](REQUIRED-FILES.md) | **Approve before B** |
| **B** | Author one `NN-*.md` + materialize that topic’s repo files | Approve each topic |
| **C** | Live bootstrap: one step per turn (`docs/setup/` is SoT) | Confirm each step |
| **D** | Post-setup verification → **READY** / **NOT READY** | Continue features only if READY |

---

## Next step

**Phase C Topics 01–14 complete (M3 + M4 PASS).** Pilot closed — **AWS cloud stack destroyed** (EKS/VPC/NAT/ALB/ECR, TF backend, Secrets Manager, ACM, Route53 zone). This repo is documentation + rebuild blueprint only.

Rebuild later = Topic 01 (Route53 zone) → Topic 03 remote-state → Topic 04+ from the Setup Guide.
