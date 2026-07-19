# Roadmap — boutique-eks-gitops

**Vision:** Production-grade GitOps on a single AWS EKS cluster where Git is the only deploy authority. GitLab CI builds, scans, signs, and opens digest-only MRs; Argo CD reconciles. Digests promote `dev → stage → prod` under `biroltilki.art`.

**Status:** Planning complete — implementation not started  
**Detailed plan:** [docs/implementation/plan.md](docs/implementation/plan.md)  
**Architecture:** [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) · [docs/architecture/](docs/architecture/)

---

## Phase overview

| Phase | Title | Complexity | Status | Setup topics |
|-------|--------|------------|--------|--------------|
| 1 | Foundation | S | ⬜ | `01-prerequisites`, `02-repo-foundation` |
| 2 | AWS foundation (Terraform) | L | ⬜ | `03-remote-state`, `04-network-eks-ecr-iam` |
| 3 | Ingress, DNS, TLS | M | ⬜ | `05-ingress-dns-tls` |
| 4 | Argo CD GitOps bootstrap | M | ⬜ | `06-argocd-bootstrap` |
| 5 | Security baseline | M | ⬜ | `07-security-baseline` |
| 6 | Observability baseline | M | ⬜ | `08-observability` |
| 7 | Boutique Helm + GitOps envs | L | ✅ | `09-boutique-charts` |
| 8 | GitLab CI digest pipeline | L | ⬜ | `10-gitlab-ci-digest` |
| 9 | Promotion + frontend canary | L | ⬜ | `11-promotion`, `12-canary-rollouts` |
| 10 | Production readiness | M | ⬜ | `13-production-readiness` |
| 11 | Teardown | M | ⬜ | `14-teardown` |

Status: ⬜ Not started · 🔄 In progress · ✅ Complete · ⏭️ Skipped

---

## Milestones

| Milestone | After phase | Definition of done |
|-----------|-------------|--------------------|
| **M1 — Cluster reachable** | 3 | EKS Ready; ACM+ALB smoke hostname under `*.boutique.biroltilki.art` |
| **M2 — Platform complete** | 6 | Argo + Kyverno/ESO/NP + Prometheus/Loki/Grafana/Alertmanager (email) live |
| **M3 — Production path proven** | 10 | Digest MR → promote → prod manual sync + canary; checklist green |
| **M4 — Clean teardown** | 11 | Workloads removed; `terraform destroy` complete; no orphan billable resources |

FC review prompts run at **M1, M2, M3** (phases 3, 6, 10). **Phase 11 teardown runs immediately after all tests** (mandatory).

---

## Incremental value

| After phase | You can… |
|-------------|----------|
| 1 | Clone a documented repo with pinned versions and Setup Guide catalog |
| 2 | `kubectl get nodes` on EKS in `eu-central-1` provisioned by Terraform |
| 3 | Hit an HTTPS smoke host via ALB + ACM + external-dns |
| 4 | See Argo CD app-of-apps; prod sync remains manual |
| 5 | Prove Kyverno denies `:latest`; ExternalSecret syncs from AWS |
| 6 | Open Grafana; receive a test alert via Alertmanager **email** |
| 7 | Reach Boutique frontends on env hostnames via GitOps digests |
| 8 | Merge a CI digest-only MR that never touches the cluster API |
| 9 | Promote digests with `@btilki` on prod; run frontend canary on stage and prod |
| 10 | Complete `PRODUCTION_CHECKLIST.md` with evidence |
| 11 | Fully decommission AWS resources and confirm the bill stops growing |

---

## Current focus

**Next:** Phase C live bootstrap — Topic 01 Step **1.1** (`docs/setup/` is SoT).

Phase A ✅. Topics 01–14 authored (Topic 01 updated: GitLab create + local Git init).  
Live: mark ROADMAP phases ✅ only during Phase C/D execution (M3/M4 sign-off).
