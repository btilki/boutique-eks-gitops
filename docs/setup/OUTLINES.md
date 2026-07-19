# Setup topic outlines — Phase A

**Status:** Planning artifact (not executable)  
**Authority for execution:** Full guides authored in Phase B under `docs/setup/NN-*.md`  
**Source inputs:** [ROADMAP.md](../../ROADMAP.md), [plan.md](../implementation/plan.md), [ARCHITECTURE.md](../ARCHITECTURE.md)

Each outline lists intended steps for Phase B authoring. Step IDs (`N.M`) are stable references for TODO markers in repo files.

---

## 01 — Prerequisites

**Goal:** Local tooling, GitLab project, linked local Git remote, and external access ready; no AWS billables from this topic.  
**Depends on:** None  
**Creates:** Confidence that topics 02+ can proceed; GitLab project + first push when starting from a Phase B working tree; consumes `docs/versions.md` once present.

| Step | Title | Concern |
|------|--------|---------|
| 1.1 | Confirm OS / shell and clone (or open) repo | Workspace |
| 1.2 | Install / verify AWS CLI | Auth later |
| 1.3 | Install / verify Terraform ≥ 1.9 | IaC |
| 1.4 | Install / verify kubectl 1.31.x + Helm 3.16.x | Cluster clients |
| 1.5 | Install / verify git, jq, curl; optional cosign/trivy awareness | Supply chain CLIs |
| 1.6 | AWS identity check (`sts get-caller-identity`) | Account access |
| 1.7 | Confirm Route53 zone `biroltilki.art` visible | DNS dependency |
| 1.8 | Create GitLab project (if missing) | Remote home |
| 1.9 | Confirm GitLab project + Maintainer (or equivalent) access | CI later |
| 1.10 | Initialize local Git, set `origin`, first push to `main` | Control-plane VCS |
| 1.11 | Confirm SMTP mailbox available for Alertmanager tests | Obs later |
| 1.12 | Topic validation checklist | Gate to 02 |

**Why required:** Failures later (OIDC, DNS, email) are expensive to diagnose mid-apply; front-load access checks.

---

## 02 — Repo foundation

**Goal:** Materialize documentation spine, version pins, ADRs, empty tree, CODEOWNERS, lint hooks — still no cluster.  
**Depends on:** 01  
**Creates:** Repo skeleton + docs listed in [REQUIRED-FILES.md](REQUIRED-FILES.md) topic 02.

| Step | Title | Concern |
|------|--------|---------|
| 2.1 | Create directory tree (`terraform/`, `gitops/`, `charts/`, `docs/`, `examples/`, `tests/`) | Layout |
| 2.2 | Align/confirm `docs/versions.md` (authored in Topic 01) | Reproducibility |
| 2.3 | Finalize / align `docs/ARCHITECTURE.md` + architecture deep docs | Design SoT |
| 2.4 | Author ADRs 0001–0005 | Decision record |
| 2.5 | Root meta: `.gitignore`, `.pre-commit-config.yaml`, `Makefile` (lint only), `CODEOWNERS` | Hygiene |
| 2.6 | Stub READMEs: `terraform/`, `gitops/`, `charts/`, `SECURITY.md` | Navigation |
| 2.7 | Topic validation (paths exist; versions match locked stack) | Gate to 03 |

**Why required:** GitOps and Terraform need a reviewable control-plane layout before any apply.

---

## 03 — Terraform remote state

**Goal:** S3 + DynamoDB backend ready; local backend config examples in repo.  
**Depends on:** 02  
**Creates:** Backend bootstrap resources + `terraform/backend.hcl.example`, `terraform/envs/prod/backend.tf`.

| Step | Title | Concern |
|------|--------|---------|
| 3.1 | Choose state bucket / lock table names (documented placeholders) | Naming |
| 3.2 | Create S3 bucket (versioning, encryption, public access block) | State durability |
| 3.3 | Create DynamoDB lock table | State locking |
| 3.4 | Wire `backend.tf` + local `backend.hcl` (gitignored secrets/names as needed) | Config |
| 3.5 | `terraform init` against remote backend | Prove wiring |
| 3.6 | Topic validation | Gate to 04 |

**Why required:** Multi-session / multi-engineer applies without remote state risk corruption.  
**Cost:** Low ongoing S3/DynamoDB.

---

## 04 — Network, EKS, ECR, IAM

**Goal:** VPC (1 NAT), EKS 1.31 Ready, ECR for 7 services, GitLab OIDC role, IRSA scaffolding, DNS/ACM data.  
**Depends on:** 03  
**Creates:** `terraform/modules/*`, `terraform/envs/prod/*`.

| Step | Title | Concern |
|------|--------|---------|
| 4.1 | Review module layout and `terraform.tfvars.example` | No secrets in Git |
| 4.2 | `terraform plan` foundation stack | Review blast radius |
| 4.3 | `terraform apply` network module path | VPC / subnets / NAT / endpoints |
| 4.4 | Apply EKS + node group | Cluster control plane + workers |
| 4.5 | Apply ECR repos (7 services) | Registry |
| 4.6 | Apply DNS data + ACM inputs | TLS prep |
| 4.7 | Apply GitLab OIDC provider + CI role | Supply chain IAM |
| 4.8 | Apply IRSA scaffolding outputs | Controllers later |
| 4.9 | Update kubeconfig; validate nodes Ready | Access |
| 4.10 | Topic validation (nodes, ECR, OIDC, state lock) | Gate to 05 |

**Why required:** All platform and app topics need a live cluster and identity plane.  
**Cost impact:** **High** — flag before apply; teardown is topic 14.

---

## 05 — Ingress, DNS, TLS

**Goal:** AWS LB Controller, external-dns, cert-manager; ACM+ALB smoke HTTPS on boutique DNS. **Milestone M1.**  
**Depends on:** 04  
**Creates:** `gitops/platform/{aws-load-balancer-controller,external-dns,cert-manager}/`, `docs/dns-and-tls.md`, `examples/smoke-ingress.yaml`.

| Step | Title | Concern |
|------|--------|---------|
| 5.1 | Annotate / bind IRSA for LB controller + external-dns | Least privilege |
| 5.2 | Install / sync AWS Load Balancer Controller | Ingress class |
| 5.3 | Install / sync external-dns (Route53) | DNS automation |
| 5.4 | Install / sync cert-manager | Platform readiness |
| 5.5 | Request / validate ACM certificate for boutique hosts | TLS |
| 5.6 | Apply temporary smoke Ingress | Prove path |
| 5.7 | `curl -I https://…` validation; document hostname map | M1 proof |
| 5.8 | Topic validation | Gate to 06 |

**Why required:** Without stable HTTPS ingress, Argo/Grafana/Boutique hostnames cannot be proven.

---

## 06 — Argo CD bootstrap

**Goal:** Argo CD installed; app-of-apps + ApplicationSets; prod **manual** sync.  
**Depends on:** 05  
**Creates:** `gitops/bootstrap/**`, `gitops/apps/**`.

| Step | Title | Concern |
|------|--------|---------|
| 6.1 | Install Argo CD (bootstrap manifests/Helm values) | Control plane |
| 6.2 | Expose Argo UI at `argocd.boutique.biroltilki.art` | Access |
| 6.3 | Register GitLab repo credential (GUI/CLI; no token in Git) | Git pull |
| 6.4 | Apply root app-of-apps | Hierarchy |
| 6.5 | Apply platform + workload ApplicationSets | Sync waves |
| 6.6 | Verify `dev`/`stage` auto; **prod automated absent** | Safety |
| 6.7 | Topic validation | Gate to 07 |

**Why required:** Git must become the only deploy authority before apps land.

---

## 07 — Security baseline

**Goal:** Kyverno (digest / no `:latest` / ECR allowlist), External Secrets Operator, NetworkPolicy baseline.  
**Depends on:** 06  
**Creates:** `gitops/platform/{kyverno,external-secrets,network-policies}/`, sample ExternalSecret.

| Step | Title | Concern |
|------|--------|---------|
| 7.1 | Sync Kyverno | Admission |
| 7.2 | Apply cluster policies (audit → enforce as guided) | Policy rollout |
| 7.3 | Prove deny of `:latest` / non-digest | Negative test |
| 7.4 | Sync ESO + ClusterSecretStore (IRSA) | Secrets path |
| 7.5 | Apply sample ExternalSecret; verify Secret materializes | E2E secrets |
| 7.6 | Apply default-deny + allow NetworkPolicies for app namespaces | East-west |
| 7.7 | Topic validation | Gate to 08 |

**Why required:** Digest-only and secret hygiene must exist before Boutique images and SMTP credentials.

---

## 08 — Observability

**Goal:** Prometheus, Loki, Grafana, Alertmanager → **email**; test alert received. **Milestone M2** (with 06–07).  
**Depends on:** 07  
**Creates:** `gitops/platform/monitoring/**`, `docs/runbooks/alerting.md`.

| Step | Title | Concern |
|------|--------|---------|
| 8.1 | Sync kube-prometheus-stack (resource caps) | Metrics / AM / Grafana |
| 8.2 | Sync Loki | Logs |
| 8.3 | Expose Grafana at locked hostname | UI |
| 8.4 | Configure Alertmanager email receiver via ESO (no SMTP secret in Git) | Alert path |
| 8.5 | Fire / route one critical test alert; confirm inbox | Proof |
| 8.6 | Topic validation | Gate to 09 |

**Why required:** Without alerts and dashboards, production readiness is unverifiable.

---

## 09 — Boutique charts

**Goal:** Helm charts for 7 services + Redis; env overlays; **bootstrap ECR digests**; `dev-boutique` reachable.  
**Depends on:** 08  
**Creates:** `charts/<service>/**`, `gitops/envs/{dev,stage,prod}/**`.

| Step | Title | Concern |
|------|--------|---------|
| 9.1 | Author / review charts (`image.repository` + `image.digest`) | Contract |
| 9.2 | One-time bootstrap: build/push images to ECR; record digests | First images |
| 9.3 | Wire `gitops/envs/dev` digests + ingress host | Dev env |
| 9.4 | Scaffold stage/prod overlays (may be inactive until promote) | Env parity |
| 9.5 | Argo sync dev; validate storefront HTTPS | App proof |
| 9.6 | Topic validation | Gate to 10 |

**Why required:** CI digest MRs need chart contract + existing ECR digests to promote.

---

## 10 — GitLab CI digests

**Goal:** Pipeline test → build → Trivy → cosign (keyless) → **digest-only MR**; CI never deploys to cluster.  
**Depends on:** 09; GitLab OIDC role from 04  
**Creates:** `.gitlab-ci.yml`, `docs/ci.md`, ADR 0006 (cosign mode).

| Step | Title | Concern |
|------|--------|---------|
| 10.1 | GitLab OIDC federation GUI (audience/subject → IAM role) | Auth hop |
| 10.2 | Prove OIDC assume-role / ECR push hop | Pre-pipeline |
| 10.3 | Author pipeline stages + variables (no static AWS keys) | CI contract |
| 10.4 | Run pipeline; Trivy CRITICAL gate | Scan |
| 10.5 | Cosign Sigstore keyless sign | Supply chain |
| 10.6 | Auto-open MR patching **only** `image.digest` under `gitops/envs/dev/` | GitOps |
| 10.7 | Confirm no `kubectl` / `argocd sync` in jobs | Hard rule |
| 10.8 | Topic validation | Gate to 11 |

**Why required:** Digest promotion without CI cluster credentials is a core project goal.

---

## 11 — Promotion

**Goal:** Documented digest copy `dev → stage → prod`; CODEOWNERS `@btilki` enforced on prod paths.  
**Depends on:** 10  
**Creates:** `docs/promotion.md`, `docs/rollback.md`; GitLab branch protection alignment.

| Step | Title | Concern |
|------|--------|---------|
| 11.1 | Author promotion rules (digest-only copy) | Process |
| 11.2 | Author rollback via `git revert` | Recovery |
| 11.3 | Enforce CODEOWNERS + approvals on `gitops/envs/prod/**` | Governance |
| 11.4 | Execute promote MR to stage; verify Argo sync | Stage proof |
| 11.5 | Execute promote MR to prod; **manual** Argo sync | Prod proof |
| 11.6 | Topic validation | Gate to 12 |

**Why required:** Uncontrolled prod digests defeat manual-sync and ownership model.

---

## 12 — Canary rollouts

**Goal:** Argo Rollouts installed; frontend canary on **stage and prod**.  
**Depends on:** 11  
**Creates:** `gitops/platform/argo-rollouts/**`, frontend Rollout templates, env canary values.

| Step | Title | Concern |
|------|--------|---------|
| 12.1 | Sync Argo Rollouts controller | Operator |
| 12.2 | Convert / add frontend Rollout (ALB integration steps) | Progressive delivery |
| 12.3 | Enable canary weights on stage; observe analysis | Stage |
| 12.4 | Enable canary on prod (manual sync discipline) | Prod |
| 12.5 | Abort / promote path documented | Recovery |
| 12.6 | Topic validation | Gate to 13 |

**Why required:** FR-09 — canary on stage **and** prod is in scope.

---

## 13 — Production readiness

**Goal:** `PRODUCTION_CHECKLIST` green with evidence; runbooks present. **Milestone M3.**  
**Depends on:** 12  
**Creates:** `docs/PRODUCTION_CHECKLIST.md`, runbooks set; ROADMAP status update.

| Step | Title | Concern |
|------|--------|---------|
| 13.1 | Walk checklist (security, GitOps, DNS, alerts, promote, canary) | Evidence |
| 13.2 | Confirm runbooks linked and usable | Ops |
| 13.3 | Capture demo path digest → promote → prod sync + canary | Proof |
| 13.4 | Topic validation / M3 sign-off | Gate to 14 |

**Why required:** Declares the pilot path proven before teardown.

---

## 14 — Teardown

**Goal:** Ordered decommission; no orphan billables. **Milestone M4.** Runs **immediately after tests**.  
**Depends on:** 13 (or early abort from any later topic)  
**Creates:** Executable teardown procedure in setup + `docs/runbooks/teardown.md`.

| Step | Title | Concern |
|------|--------|---------|
| 14.1 | Prune / delete GitOps apps and Ingresses (ALBs gone) | Cloud leftovers |
| 14.2 | Confirm no stray ALBs / Target Groups / ENIs blocking destroy | Pre-destroy |
| 14.3 | `terraform destroy` foundation (documented order) | Cluster/VPC |
| 14.4 | Optionally empty/delete state bucket/table (guided) | State cleanup |
| 14.5 | Orphan audit (EC2, ELB, NAT, EIP, ECR optional retain policy) | Cost stop |
| 14.6 | Topic validation — **READY for close** / bill stopped | M4 |

**Why required:** Cost and security — pilot must not leave a running control plane unpaid-for.

---

## Outline → Phase B mapping

| When approved | Author next |
|---------------|-------------|
| Phase A | Topic **01** guide + its `SETUP_REQUIRED` files |
| After each topic B approval | Next numeric topic |
| After topic 14 B | Start Phase C at `01` step `1.1` |
