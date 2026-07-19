# Required Files Inventory — Phase A

**Timing tags:** `SETUP_REQUIRED` | `FEATURE_REQUIRED` | `RELEASE_REQUIRED`  
**Rule:** Phase B materializes each topic’s files with the topic guide. No deferral (“later”) without explicit approval — use minimal valid content + `TODO(setup:N.M)` markers if details are incomplete.  
**Already in repo (planning):** marked **EXISTS** — Phase B aligns/updates rather than inventing from scratch.

Owner step IDs refer to [OUTLINES.md](OUTLINES.md).

---

## Topic 01 — Prerequisites

| Path | Timing | Owner step | Minimum content | Status |
|------|--------|------------|-----------------|--------|
| `docs/setup/01-prerequisites.md` | SETUP_REQUIRED | — (guide) | Full topic template; CLI matrix; AWS/GitLab/Route53/SMTP checks | EXISTS (Phase B) |
| `docs/versions.md` | SETUP_REQUIRED | 1.2–1.5; align in 02 | Pin matrix: Terraform ≥1.9, EKS 1.31, kubectl 1.31.x, Helm 3.16.x, Argo CD 2.14.x, Trivy 0.71.0, cosign 2.4.x, region `eu-central-1` | EXISTS (Phase B) |

---

## Topic 02 — Repo foundation

| Path | Timing | Owner step | Minimum content | Status |
|------|--------|------------|-----------------|--------|
| `docs/setup/02-repo-foundation.md` | SETUP_REQUIRED | — | How to create dirs/files; validation | EXISTS (Phase B) |
| `README.md` | SETUP_REQUIRED | 2.1+ | Vision, links, GitOps rules | EXISTS — links aligned |
| `ROADMAP.md` | SETUP_REQUIRED | 2.7 | Phase tracker | EXISTS |
| `CODEOWNERS` | SETUP_REQUIRED | 2.5 | `@btilki` on `gitops/envs/prod/**` | EXISTS (Phase B) |
| `.gitignore` | SETUP_REQUIRED | 2.5 | tfstate, `.terraform/`, secrets, IDE, `backend.hcl` | EXISTS (Phase B) |
| `.pre-commit-config.yaml` | SETUP_REQUIRED | 2.5 | yaml lint, terraform fmt, trailing whitespace | EXISTS (Phase B) |
| `Makefile` | SETUP_REQUIRED | 2.5 | `lint`, `docs-check` only (no install bypass) | EXISTS (Phase B) |
| `SECURITY.md` | SETUP_REQUIRED | 2.6 | Threat model summary + pointers | EXISTS (Phase B) |
| `docs/versions.md` | SETUP_REQUIRED | 2.2 | Full locked pin matrix | EXISTS (Topic 01) |
| `docs/ARCHITECTURE.md` | SETUP_REQUIRED | 2.3 | Topology, DNS, sync, security, obs | EXISTS — Accepted |
| `docs/architecture/README.md` | SETUP_REQUIRED | 2.3 | Index + ADR list | EXISTS — ADR links updated |
| `docs/architecture/01-requirements.md` … `10-cost-model.md` | SETUP_REQUIRED | 2.3 | Deep architecture set | EXISTS |
| `docs/implementation/plan.md` | SETUP_REQUIRED | — | Phases + inventories | EXISTS |
| `docs/adr/0001-digest-only-gitops.md` | SETUP_REQUIRED | 2.4 | Decision + consequences | EXISTS (Phase B) |
| `docs/adr/0002-single-cluster-namespaces.md` | SETUP_REQUIRED | 2.4 | Decision | EXISTS (Phase B) |
| `docs/adr/0003-tls-acm-alb.md` | SETUP_REQUIRED | 2.4 | Decision | EXISTS (Phase B) |
| `docs/adr/0004-dns-hostname-scheme.md` | SETUP_REQUIRED | 2.4 | Decision | EXISTS (Phase B) |
| `docs/adr/0005-observability-on-cluster.md` | SETUP_REQUIRED | 2.4 | No CW/PD/OTel | EXISTS (Phase B) |
| `terraform/README.md` | SETUP_REQUIRED | 2.6 | Module index stub | EXISTS (Phase B) |
| `gitops/README.md` | SETUP_REQUIRED | 2.6 | Layout + sync rules | EXISTS (Phase B) |
| `charts/README.md` | SETUP_REQUIRED | 2.6 | 7 services + Redis note | EXISTS (Phase B) |
| `examples/.gitkeep` | SETUP_REQUIRED | 2.1 | Keep dir | EXISTS (Phase B) |
| `tests/README.md` | SETUP_REQUIRED | 2.1 | Test layout stub | EXISTS (Phase B) |
| Dirs: `terraform/`, `gitops/{bootstrap,apps,platform,envs}`, `charts/`, `docs/adr/`, `docs/runbooks/` | SETUP_REQUIRED | 2.1 | Empty structure + README stubs as needed | EXISTS (Phase B) |

---

## Topic 03 — Remote state

| Path | Timing | Owner step | Minimum content | Status |
|------|--------|------------|-----------------|--------|
| `docs/setup/03-remote-state.md` | SETUP_REQUIRED | — | Exact bootstrap CLI; validation | EXISTS (Phase B) |
| `terraform/backend.hcl.example` | SETUP_REQUIRED | 3.4 | `bucket`, `key`, `region`, `dynamodb_table` placeholders called out | EXISTS (Phase B) |
| `terraform/envs/prod/backend.tf` | SETUP_REQUIRED | 3.4 | S3 + DynamoDB backend block | EXISTS (Phase B) |
| `terraform/envs/prod/versions.tf` | SETUP_REQUIRED | 3.4 | `terraform` ≥1.9; `aws` ~> 5.80 | EXISTS (Phase B) |

---

## Topic 04 — Network, EKS, ECR, IAM

| Path | Timing | Owner step | Minimum content | Status |
|------|--------|------------|-----------------|--------|
| `docs/setup/04-network-eks-ecr-iam.md` | SETUP_REQUIRED | — | Apply order + validations | EXISTS (Phase B) |
| `terraform/modules/network/**` | FEATURE_REQUIRED | 4.3 | VPC, public/private subnets, **1 NAT**, S3/ECR endpoints | EXISTS (Phase B) |
| `terraform/modules/eks/**` | FEATURE_REQUIRED | 4.4 | EKS 1.31, node group `m6i.large` ASG 2–5 | EXISTS (Phase B) |
| `terraform/modules/ecr/**` | FEATURE_REQUIRED | 4.5 | 7 repos, scan-on-push | EXISTS (Phase B) |
| `terraform/modules/dns/**` | FEATURE_REQUIRED | 4.6 | Zone data + ACM for boutique hosts | EXISTS (Phase B) |
| `terraform/modules/iam_gitlab_oidc/**` | FEATURE_REQUIRED | 4.7 | OIDC provider + CI role trust | EXISTS (Phase B) |
| `terraform/modules/irsa/**` | FEATURE_REQUIRED | 4.8 | Reusable IRSA module | EXISTS (Phase B) |
| `terraform/envs/prod/main.tf` | FEATURE_REQUIRED | 4.2 | Module wiring | EXISTS (Phase B) |
| `terraform/envs/prod/variables.tf` | FEATURE_REQUIRED | 4.2 | Typed variables | EXISTS (Phase B) |
| `terraform/envs/prod/outputs.tf` | FEATURE_REQUIRED | 4.2 | Cluster, OIDC, ECR URLs, role ARNs | EXISTS (Phase B) |
| `terraform/envs/prod/terraform.tfvars.example` | FEATURE_REQUIRED | 4.1 | No secrets; `eu-central-1` | EXISTS (Phase B) |
| Each module `README.md` | FEATURE_REQUIRED | 4.1 | Purpose / inputs / outputs / deps | EXISTS (Phase B) |

**ECR repos (7):** `frontend`, `productcatalogservice`, `cartservice`, `checkoutservice`, `currencyservice`, `paymentservice`, `shippingservice`.

---

## Topic 05 — Ingress, DNS, TLS

| Path | Timing | Owner step | Minimum content | Status |
|------|--------|------------|-----------------|--------|
| `docs/setup/05-ingress-dns-tls.md` | SETUP_REQUIRED | — | IRSA, install, smoke HTTPS | EXISTS (Phase B) |
| `docs/dns-and-tls.md` | FEATURE_REQUIRED | 5.5–5.7 | Hostname table + ACM notes | EXISTS (Phase B) |
| `gitops/platform/aws-load-balancer-controller/**` | FEATURE_REQUIRED | 5.2 | Helm values (+ AppSet in Topic 06) | EXISTS (Phase B) |
| `gitops/platform/external-dns/**` | FEATURE_REQUIRED | 5.3 | Route53 via IRSA | EXISTS (Phase B) |
| `gitops/platform/cert-manager/**` | FEATURE_REQUIRED | 5.4 | Install (ACM primary for public TLS) | EXISTS (Phase B) |
| `examples/smoke-ingress.yaml` | FEATURE_REQUIRED | 5.6 | Temporary ACM Ingress | EXISTS (Phase B) |

---

## Topic 06 — Argo CD bootstrap

| Path | Timing | Owner step | Minimum content | Status |
|------|--------|------------|-----------------|--------|
| `docs/setup/06-argocd-bootstrap.md` | SETUP_REQUIRED | — | Bootstrap order; GitLab repo connect GUI | EXISTS (Phase B) |
| `gitops/bootstrap/**` | FEATURE_REQUIRED | 6.1–6.4 | Install + root App | EXISTS (Phase B) |
| `gitops/apps/platform-apps/**` | FEATURE_REQUIRED | 6.5 | ApplicationSet / apps | EXISTS (Phase B) |
| `gitops/apps/workload-apps/**` | FEATURE_REQUIRED | 6.5 | Env ApplicationSet; prod manual | EXISTS (Phase B) |
| `gitops/apps/README.md` | FEATURE_REQUIRED | 6.5 | Sync waves + prod manual rule | EXISTS (Phase B) |

---

## Topic 07 — Security baseline

| Path | Timing | Owner step | Minimum content | Status |
|------|--------|------------|-----------------|--------|
| `docs/setup/07-security-baseline.md` | SETUP_REQUIRED | — | Policy apply + deny test | EXISTS (Phase B) |
| `gitops/platform/kyverno/**` | FEATURE_REQUIRED | 7.1–7.3 | Digest / `:latest` / ECR policies | EXISTS (Phase B) |
| `gitops/platform/external-secrets/**` | FEATURE_REQUIRED | 7.4–7.5 | Operator + ClusterSecretStore | EXISTS (Phase B) |
| `gitops/platform/network-policies/**` | FEATURE_REQUIRED | 7.6 | Default-deny + allows | EXISTS (Phase B) |
| `examples/externalsecret-sample.yaml` | FEATURE_REQUIRED | 7.5 | SM/SSM ref pattern | EXISTS (Phase B) |

---

## Topic 08 — Observability

| Path | Timing | Owner step | Minimum content | Status |
|------|--------|------------|-----------------|--------|
| `docs/setup/08-observability.md` | SETUP_REQUIRED | — | Stack install + email alert test | EXISTS (Phase B) |
| `gitops/platform/monitoring/**` | FEATURE_REQUIRED | 8.1–8.2 | kube-prometheus-stack + Loki values | EXISTS (Phase B) |
| `docs/runbooks/alerting.md` | FEATURE_REQUIRED | 8.4–8.5 | One critical rule; AM **email** | EXISTS (Phase B) |

---

## Topic 09 — Boutique charts

| Path | Timing | Owner step | Minimum content | Status |
|------|--------|------------|-----------------|--------|
| `docs/setup/09-boutique-charts.md` | SETUP_REQUIRED | — | Charts + **bootstrap ECR digests** + dev hostname | EXISTS (Phase B) |
| `charts/frontend/**` | FEATURE_REQUIRED | 9.1 | Chart with `image.repository` + `image.digest` | EXISTS (Phase B) |
| `charts/productcatalogservice/**` | FEATURE_REQUIRED | 9.1 | Same contract | EXISTS (Phase B) |
| `charts/cartservice/**` | FEATURE_REQUIRED | 9.1 | + Redis dependency notes | EXISTS (Phase B) |
| `charts/checkoutservice/**` | FEATURE_REQUIRED | 9.1 | Same contract | EXISTS (Phase B) |
| `charts/currencyservice/**` | FEATURE_REQUIRED | 9.1 | Same contract | EXISTS (Phase B) |
| `charts/paymentservice/**` | FEATURE_REQUIRED | 9.1 | Same contract | EXISTS (Phase B) |
| `charts/shippingservice/**` | FEATURE_REQUIRED | 9.1 | Same contract | EXISTS (Phase B) |
| `charts/redis/**` | FEATURE_REQUIRED | 9.1 | Redis companion chart (ECR-mirrored) | EXISTS (Phase B) |
| `charts/README.md` | FEATURE_REQUIRED | 9.1 | Service map + Redis | EXISTS (Phase B) |
| `gitops/envs/dev/**` | FEATURE_REQUIRED | 9.3 | Digests + ingress host | EXISTS (Phase B) |
| `gitops/envs/stage/**` | FEATURE_REQUIRED | 9.4 | Overlay structure | EXISTS (Phase B) |
| `gitops/envs/prod/**` | FEATURE_REQUIRED | 9.4 | Overlay; manual sync expectation | EXISTS (Phase B) |
| `gitops/apps/workload-apps/boutique-applicationset.yaml` | FEATURE_REQUIRED | 9.5 | Helm AppSet; prod manual | EXISTS (Phase B) |

---

## Topic 10 — GitLab CI digests

| Path | Timing | Owner step | Minimum content | Status |
|------|--------|------------|-----------------|--------|
| `docs/setup/10-gitlab-ci-digest.md` | SETUP_REQUIRED | — | OIDC GUI + pipeline validation | EXISTS (Phase B) |
| `docs/ci.md` | FEATURE_REQUIRED | 10.3 | Contract: digest-only MR; no cluster deploy | EXISTS (Phase B) |
| `.gitlab-ci.yml` | FEATURE_REQUIRED | 10.3 | test→build→scan→sign→gitops MR | EXISTS (Phase B) |
| `docs/adr/0006-cosign-signing-mode.md` | FEATURE_REQUIRED | 10.5 | Sigstore keyless via GitLab OIDC | EXISTS (Phase B) |

---

## Topic 11 — Promotion

| Path | Timing | Owner step | Minimum content | Status |
|------|--------|------------|-----------------|--------|
| `docs/setup/11-promotion.md` | SETUP_REQUIRED | — | MR flow stage/prod | EXISTS (Phase B) |
| `docs/promotion.md` | FEATURE_REQUIRED | 11.1 | Digest-copy rules | EXISTS (Phase B) |
| `docs/rollback.md` | FEATURE_REQUIRED | 11.2 | `git revert` procedure | EXISTS (Phase B) |
| `CODEOWNERS` | FEATURE_REQUIRED | 11.3 | Enforced on prod paths (GitLab settings) | EXISTS — enforce in GitLab (Step 11.3) |

---

## Topic 12 — Canary rollouts

| Path | Timing | Owner step | Minimum content | Status |
|------|--------|------------|-----------------|--------|
| `docs/setup/12-canary-rollouts.md` | SETUP_REQUIRED | — | Rollouts install; ALB steps | EXISTS (Phase B) |
| `gitops/platform/argo-rollouts/**` | FEATURE_REQUIRED | 12.1 | Operator Application/values | EXISTS (Phase B) |
| `charts/frontend` Rollout templates | FEATURE_REQUIRED | 12.2 | Canary spec | EXISTS (Phase B) |
| `gitops/envs/stage/**` canary values | FEATURE_REQUIRED | 12.3 | Weights | EXISTS (Phase B) |
| `gitops/envs/prod/**` canary values | FEATURE_REQUIRED | 12.4 | Weights | EXISTS (Phase B) |

---

## Topic 13 — Production readiness

| Path | Timing | Owner step | Minimum content | Status |
|------|--------|------------|-----------------|--------|
| `docs/setup/13-production-readiness.md` | SETUP_REQUIRED | — | Checklist execution | EXISTS (Phase B) |
| `docs/PRODUCTION_CHECKLIST.md` | RELEASE_REQUIRED | 13.1 | All Must items + evidence fields | EXISTS (Phase B) |
| `docs/runbooks/*.md` | RELEASE_REQUIRED | 13.2 | Ingress, Argo, Kyverno, canary (min set) | EXISTS (Phase B) — alerting from 08; teardown in 14 |
| `ROADMAP.md` | RELEASE_REQUIRED | 13.4 | Phases 1–10 marked ✅ | EXISTS — mark ✅ at live M3 sign-off (Step 13.4) |

---

## Topic 14 — Teardown

| Path | Timing | Owner step | Minimum content | Status |
|------|--------|------------|-----------------|--------|
| `docs/setup/14-teardown.md` | SETUP_REQUIRED | — | Ordered steps; exact commands; validation | EXISTS (Phase B) |
| `docs/runbooks/teardown.md` | RELEASE_REQUIRED | 14.1–14.5 | GitOps prune → ALB check → `terraform destroy` → orphan audit | EXISTS (Phase B) |
| `docs/PRODUCTION_CHECKLIST.md` (teardown appendix) | RELEASE_REQUIRED | 14.6 | Destroy evidence / sign-off | EXISTS (Appendix T; fill at live M4) |

---

## Phase A inventory summary

| Topic | Guide file | SETUP_REQUIRED paths | FEATURE/RELEASE paths | Blockers |
|-------|------------|----------------------|----------------------|----------|
| 01 | MISSING | 2 | 0 | None |
| 02 | EXISTS | Many (docs spine) | 0 | None — architecture + ADRs EXISTS |
| 03 | EXISTS | 3–4 | 0 | None |
| 04 | EXISTS | 1 | Terraform modules + env | None |
| 05 | EXISTS | 1 | Platform ingress + smoke | Needs 04 live |
| 06 | EXISTS | 1 | Bootstrap + apps | Needs 05 |
| 07 | EXISTS | 1 | Kyverno/ESO/NP | Needs 06 |
| 08 | EXISTS | 1 | Monitoring + alerting runbook | Needs 07 |
| 09 | EXISTS | 1 | Charts + envs | Needs 08 |
| 10 | EXISTS | 1 | CI + ADR 0006 | Needs 09 + OIDC |
| 11 | EXISTS | 1 | Promotion/rollback docs | Needs 10 |
| 12 | EXISTS | 1 | Rollouts + canary values | Needs 11 |
| 13 | EXISTS | 1 | Checklist + runbooks | Needs 12 |
| 14 | EXISTS | 1 | Teardown runbook | Needs 13 or abort |

**Phase A file-inventory gate:** complete. No planning blockers. Topic guides and FEATURE files are intentionally **not** created until Phase B.
