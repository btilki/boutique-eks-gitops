# Implementation Plan — boutique-eks-gitops

**Audience:** Implementer during build  
**Public summary:** [ROADMAP.md](../../ROADMAP.md)  
**Architecture (authoritative):** [docs/ARCHITECTURE.md](../ARCHITECTURE.md) — physical file created in Phase 1; decisions below are **approved** from Planning Gate  
**Structure (authoritative):** Preferred layout in Project Prompt — materialized in Phase 1  

**Plan version:** 2026-07-18  
**Status:** Awaiting plan approval before Setup Guide authoring  

---

## 7.1 Executive summary

| Field | Value |
|-------|--------|
| Project | **boutique-eks-gitops** |
| Goal | Production GitOps platform for Online Boutique on one EKS cluster; Git is the only deploy authority; CI only updates image digests |
| Current status | Planning complete; repo empty except this plan + ROADMAP; no AWS resources |
| Phases | **11** (Phase 1–11, including teardown) |
| Overall complexity | **L** (platform breadth); no single XL phase if Phase 2/7/8 stay scoped |
| Definition of done | All Must FRs validated; PRODUCTION_CHECKLIST green; digest → promote → prod manual sync + canary proven; teardown documented and executable |

---

## 7.2 Project goals

| Goal ID | Goal | Success indicator |
|---------|------|-------------------|
| G-01 | Provision AWS foundation with Terraform | VPC, EKS Ready nodes, ECR, IAM OIDC/IRSA, remote state in `eu-central-1` |
| G-02 | Expose platform/apps under boutique DNS | Hostnames resolve via external-dns; HTTPS via ACM+ALB |
| G-03 | GitOps-only delivery | Argo CD app-of-apps + ApplicationSet; CI never `kubectl apply` / `argocd sync` |
| G-04 | Digest-only promotion | MRs patch only `image.digest`; promote dev→stage→prod with CODEOWNERS `@btilki` |
| G-05 | Production security baseline | Kyverno digest/ECR rules; ESO; NetworkPolicy |
| G-06 | On-cluster observability | Prometheus + Loki + Grafana + Alertmanager (**email**) |
| G-07 | Boutique via Helm GitOps | 7 services + Redis reachable on env hostnames |
| G-08 | Supply-chain CI | Trivy CRITICAL gate → cosign sign → digest MR |
| G-09 | Frontend canary | Argo Rollouts on **stage and prod** |
| G-10 | Production readiness | Checklist, runbooks, rollback via git revert tested |
| G-11 | Clean teardown | Documented decommission; AWS resources destroyed; no orphan billables |

---

## 7.3 Business value

- Prove deep GitOps on AWS: digest-only releases and Git-driven promotion without CI deploying to the cluster.
- Deliver a production-quality reference control plane (Terraform + Argo + policy + SRE baseline) reviewable by platform engineers.
- Operate `dev` / `stage` / `prod` under `biroltilki.art` with documented promotion, rollback, and alerting.
- Keep cost suitable for a short pilot (single cluster, single NAT, no CloudWatch/PagerDuty) with a **mandatory teardown path**.
- Encode audit-friendly patterns: Git history, signed images, CODEOWNERS on prod paths.

---

## 7.4 Functional requirements

| ID | Requirement | Priority | Delivered in phase |
|----|-------------|----------|-------------------|
| FR-01 | Terraform: VPC, EKS 1.31, ECR, Route53 data, IAM OIDC/IRSA, S3+DynamoDB state | Must | 2 |
| FR-02 | AWS LB Controller, external-dns, cert-manager; ACM+ALB public HTTPS | Must | 3 |
| FR-03 | Argo CD app-of-apps + ApplicationSet; auto sync lower envs; **manual prod** | Must | 4 |
| FR-04 | Kyverno (digest-only, no `:latest`, ECR allowlist), ESO, NetworkPolicy | Must | 5 |
| FR-05 | Prometheus, Loki, Grafana, Alertmanager → **email** (no CloudWatch/PagerDuty/OTel) | Must | 6 |
| FR-06 | Helm charts for 7 Boutique services + Redis; env overlays; boutique hostnames | Must | 7 |
| FR-07 | GitLab CI: test→build→scan→sign→digest MR; OIDC→IAM; no cluster deploy | Must | 8 |
| FR-08 | Promotion MRs, CODEOWNERS `@btilki` on `gitops/envs/prod/**`, promotion/rollback docs | Must | 9 |
| FR-09 | Argo Rollouts frontend canary on **stage and prod** | Must | 9 |
| FR-10 | PRODUCTION_CHECKLIST, architecture docs, runbooks, full path demo | Must | 10 |
| FR-11 | Teardown runbook + ordered destroy (GitOps apps → EKS/ALB → Terraform → verify no orphans) | Must | 11 |

---

## 7.5 Non-functional requirements

| Category | Requirement | Architecture reference |
|----------|-------------|------------------------|
| Availability | Single-cluster production-minimum; prod changes deliberate (manual sync + approvals) | ARCHITECTURE § sync policies |
| Scalability | One cluster, three app envs + platform; structure allows later multi-cluster | ARCHITECTURE § topology |
| Security | Least-privilege IAM/IRSA; no secrets in Git; OIDC CI; signed images; Kyverno; NP; ESO | ARCHITECTURE § security |
| Observability | Metrics + logs + alerts on-cluster; Alertmanager → **email** | ARCHITECTURE § observability |
| Maintainability | Modular Terraform/Helm; phase delivery; README/runbooks/ADRs | Repo structure |
| Reproducibility | Pinned versions; remote state; digest-pinned workloads | `docs/versions.md` |
| Cost | One EKS; 3× `m6i.large`; single NAT; no CW/PD | ARCHITECTURE § capacity |
| Compliance | Audit-friendly Git + signatures + CODEOWNERS (no formal SOC2 target) | FR-08 |

---

## 7.6 Assumptions

| Assumption | Validate in |
|------------|-------------|
| Admin access to one AWS account | Phase 1–2 |
| Route53 zone `biroltilki.art` manageable | Phase 3 |
| GitLab project + OIDC→IAM federation possible | Phase 1 (docs), Phase 8 (live) |
| Single-cluster namespaces are acceptable blast radius | Phase 1 ADR |
| 7 Boutique services (+ Redis) sufficient for storefront path | Phase 7 |
| Alertmanager delivers alerts by **email** | Phase 6 |
| Cosign uses **Sigstore keyless** via GitLab OIDC (`SIGSTORE_ID_TOKEN`) | Phase 8 |
| Phase 7 includes **one-time bootstrap ECR digest push** before first CI pipeline | Phase 7 |
| After all tests complete, **Phase 11 teardown runs immediately** (no keep-alive) | Phase 11 |

---

## 7.7 Constraints

| Constraint | Planning impact |
|------------|-----------------|
| AWS only; one EKS cluster | No multi-cloud; envs = namespaces |
| Cost-sensitive / short test window | Single NAT; On-Demand `m6i.large` ×3; **Phase 11 teardown mandatory** for short pilots |
| No static AWS keys in Git/CI | OIDC only |
| Digest-only; never `:latest` | Kyverno + chart contract |
| CI must not deploy to cluster | Digest MR only |
| Prod manual Argo sync + CODEOWNERS `@btilki` | ApplicationSet + branch protection |
| No CloudWatch, PagerDuty, OTel in v1 | Loki + Alertmanager instead |
| No learning/demo/lab/portfolio wording | Docs use production/test |
| Human executes cloud/CLI; AI designs/guides | One phase per approval gate |

---

## 7.8 Scope

### In scope

- Terraform modules: network, eks, ecr, dns/ACM data, iam_gitlab_oidc, irsa
- Platform: LB controller, external-dns, cert-manager, Argo CD, Kyverno, ESO, NetworkPolicy, Rollouts
- Observability: kube-prometheus-stack (Prom/Grafana/AM) + Loki
- Apps: frontend, productcatalogservice, cartservice (+ Redis), checkoutservice, currencyservice, paymentservice, shippingservice
- GitLab CI digest path; promotion; stage+prod canary
- Docs: Setup Guide topics, ADRs, promotion/rollback, PRODUCTION_CHECKLIST, **teardown runbook**

### Out of scope (deferred)

| Item | Deferred to |
|------|-------------|
| Multi-region DR / multi-cluster | Future roadmap (ApplicationSet cluster generator) |
| Remaining Boutique services (ads, recommendation, email, …) | Optional later phase |
| Service mesh | Explicitly deferred |
| CloudWatch, PagerDuty, OTel | Deferred unless cost model changes |
| Custom operators / app feature work | Out |
| Second EKS cluster | Only if single-cluster limits proven |

---

## 7.9 Risks

| Risk | Likelihood | Impact | Mitigation | Owner |
|------|------------|--------|------------|-------|
| GitLab OIDC→IAM misconfig blocks ECR push / digest MR | Medium | High | Document subject/audience/role; auth hop test before Phase 8 | Implementer |
| Kyverno breaks Rollouts or Boutique pods | Medium | High | Audit/dry-run first; stage before prod; document exceptions | Architect |
| NAT + ECR pull cost spike during short test | Medium | Medium | ECR/S3 VPC endpoints; single NAT; destroy promptly | Implementer |
| Prod auto-sync left enabled | Low | High | ApplicationSet `automated: null` for prod; checklist | Architect |
| Hostname / TLS mismatch delays cutover | Medium | Medium | Locked DNS scheme; ACM+ALB as primary; validate Phase 3 | Implementer |
| Prometheus/Loki OOM on `m6i.large` ×3 | Medium | Medium | Retention caps; requests/limits; scale to xlarge if needed | Implementer |
| Cosign/Trivy version drift breaks CI | Low | Medium | Pin Trivy `0.71.0`, cosign `2.4.x` in `docs/versions.md` | Architect |
| Alert noise without PagerDuty discipline | Low | Low | One critical ingress-down rule first | Implementer |

---

## 7.10 Dependencies

| Dependency | Type | Blocks | Resolution |
|------------|------|--------|------------|
| AWS account + credentials | External | Phase 2 | Phase 1 prerequisites |
| Route53 `biroltilki.art` | External | Phase 3 | Confirm zone ID Phase 1 |
| GitLab project | External | Phase 8 | Create/configure Phase 1–8 |
| Terraform S3+DynamoDB backend | Internal | Phase 2 apply | Bootstrap `03-remote-state` first |
| EKS Ready | Internal | Phase 3+ | Phase 2 |
| Argo CD healthy | Internal | Phase 5–7 sync | Phase 4 |
| ECR repos + OIDC role | Internal | Phase 8 push | Phase 2 |
| Signed images in ECR | Internal | Phase 7–9 prod path | Phase 8 |
| SMTP / email path for Alertmanager | External | Phase 6 alert test | Configure receiver via ESO (no secrets in Git) |

---

## 7.11 Technology stack

| Layer | Technology | Version | Introduced in phase |
|-------|------------|---------|---------------------|
| Region | AWS `eu-central-1` | — | 2 |
| VCS/CI | GitLab + GitLab CI | project-local | 1 / 8 |
| IaC | Terraform | ≥ 1.9 | 2 |
| AWS provider | hashicorp/aws | ~> 5.80 | 2 |
| Kubernetes | EKS | **1.31** | 2 |
| Nodes | EC2 `m6i.large` ×3 (2–5 ASG) | On-Demand | 2 |
| Helm | Helm | 3.16.x | 3+ |
| kubectl | kubectl | 1.31.x | 2 |
| GitOps | Argo CD | v2.14.x (pin chart) | 4 |
| Progressive delivery | Argo Rollouts | v1.8.x (pin) | 9 |
| Policy | Kyverno | 1.16.x | 5 |
| Secrets | External Secrets Operator | 0.14.x (pin chart) | 5 |
| Ingress | AWS LB Controller | v2.11.x | 3 |
| DNS | external-dns | 0.15.x | 3 |
| TLS | ACM on ALB + cert-manager | cert-manager v1.16.x | 3 |
| Metrics/UI/alerts | kube-prometheus-stack | pin at Phase 6 | 6 |
| Logs | Grafana Loki | 3.x chart pin | 6 |
| Registry | Amazon ECR | scan-on-push | 2 |
| Scan | Trivy | **0.71.0** | 8 |
| Sign | cosign | **2.4.x** Sigstore keyless (GitLab OIDC) | 8 |
| CODEOWNERS | `@btilki` | — | 1 / 9 |

---

## 7.12 High-level architecture

GitLab CI builds and signs images to ECR, then opens MRs that change only `image.digest` under `gitops/envs/*`. Argo CD (app-of-apps + ApplicationSet) reconciles platform sync-waves first, then workloads: auto for `dev`/`stage`, **manual for `prod`**. Public HTTPS uses ACM on ALB; cert-manager is installed for platform readiness. Security uses Kyverno, ESO, and NetworkPolicy. Observability is Prometheus + Loki + Grafana + Alertmanager (**email**). Frontend canaries run on stage and prod via Argo Rollouts. Short pilots end with **Phase 11 ordered teardown**.

**Authoritative detail:** `docs/ARCHITECTURE.md` + `docs/architecture/*` (Phase 1).

### Component-to-phase mapping

| Component | Phase | Repo path |
|-----------|-------|-----------|
| Versions, ADRs, Setup catalog | 1 | `docs/`, `CODEOWNERS`, `.pre-commit-config.yaml` |
| Remote state | 2 | `terraform/envs/prod/backend*`, bootstrap notes |
| VPC / subnets / NAT | 2 | `terraform/modules/network/` |
| EKS + node group | 2 | `terraform/modules/eks/` |
| ECR (7 services) | 2 | `terraform/modules/ecr/` |
| GitLab OIDC IAM | 2 | `terraform/modules/iam_gitlab_oidc/` |
| ACM / Route53 data | 2–3 | `terraform/modules/dns/` |
| LB controller / external-dns / cert-manager | 3 | `gitops/platform/*` |
| Argo CD bootstrap | 4 | `gitops/bootstrap/`, `gitops/apps/` |
| Kyverno / ESO / NP | 5 | `gitops/platform/kyverno|external-secrets|network-policies/` |
| Monitoring + Loki | 6 | `gitops/platform/monitoring/` |
| Boutique charts | 7 | `charts/<service>/` |
| Env digests/values | 7 | `gitops/envs/{dev,stage,prod}/` |
| GitLab CI | 8 | `.gitlab-ci.yml` |
| Promotion docs + CODEOWNERS enforce | 9 | `docs/promotion.md`, `docs/rollback.md` |
| Rollouts canary | 9 | `gitops/platform/argo-rollouts/`, frontend chart |
| Checklist / runbooks | 10 | `docs/PRODUCTION_CHECKLIST.md`, `docs/runbooks/` |

---

## 7.13 Repository organization

**Variant:** Preferred Project Prompt layout (Terraform + gitops + charts + docs).

| Directory | First populated |
|-----------|-----------------|
| `docs/`, root meta files | Phase 1 |
| `terraform/` | Phase 2 |
| `gitops/bootstrap`, `gitops/platform` (ingress) | Phase 3–4 |
| `gitops/platform` (security, monitoring) | Phase 5–6 |
| `charts/`, `gitops/envs/` | Phase 7 |
| `.gitlab-ci.yml` | Phase 8 |
| Rollouts + promotion docs | Phase 9 |
| Checklist / polish | Phase 10 |
| Teardown docs + destroy procedure | Phase 11 |

```text
boutique-eks-gitops/
├── ROADMAP.md
├── README.md
├── CODEOWNERS
├── .gitlab-ci.yml
├── .pre-commit-config.yaml
├── Makefile
├── terraform/
├── gitops/
│   ├── bootstrap/
│   ├── apps/
│   ├── platform/
│   └── envs/{dev,stage,prod}/
├── charts/
├── docs/
│   ├── ARCHITECTURE.md
│   ├── architecture/
│   ├── setup/
│   ├── implementation/plan.md
│   ├── adr/
│   └── runbooks/
└── examples/
```

---

## 7.14 Milestones

| Milestone | Target | Phases | Definition of done |
|-----------|--------|--------|--------------------|
| M1 Cluster reachable | After Phase 3 | 1–3 | Nodes Ready; HTTPS smoke host on boutique DNS |
| M2 Platform complete | After Phase 6 | 4–6 | Argo + security + observability (Alertmanager **email**) validated |
| M3 Production path proven | After Phase 10 | 7–10 | Digest→promote→prod canary; checklist green |
| M4 Clean teardown | After Phase 11 | 11 | Ordered destroy complete; no orphan billable resources |

---

## 7.15 Deliverables

| Deliverable | Type | Phase | Location |
|-------------|------|-------|----------|
| ROADMAP + implementation plan | Docs | 0 (now) | `ROADMAP.md`, `docs/implementation/plan.md` |
| Architecture + ADRs + versions | Docs | 1 | `docs/ARCHITECTURE.md`, `docs/adr/*`, `docs/versions.md` |
| Setup Guide topics | Docs | 1–11 | `docs/setup/*.md` |
| Terraform modules + env | Code | 2 | `terraform/` |
| Ingress platform GitOps | Code | 3 | `gitops/platform/{aws-load-balancer-controller,external-dns,cert-manager}/` |
| Argo bootstrap + apps | Code | 4 | `gitops/bootstrap/`, `gitops/apps/` |
| Security policies | Code | 5 | `gitops/platform/{kyverno,external-secrets,network-policies}/` |
| Monitoring stack | Code | 6 | `gitops/platform/monitoring/` |
| Boutique Helm charts | Code | 7 | `charts/` |
| Env overlays | Code | 7 | `gitops/envs/` |
| GitLab CI | Code | 8 | `.gitlab-ci.yml` |
| Promotion/rollback docs | Docs | 9 | `docs/promotion.md`, `docs/rollback.md` |
| Rollouts | Code | 9 | `gitops/platform/argo-rollouts/` |
| PRODUCTION_CHECKLIST | Docs | 10 | `docs/PRODUCTION_CHECKLIST.md` |
| Teardown runbook | Docs | 11 | `docs/runbooks/teardown.md`, `docs/setup/14-teardown.md` |

---

## 7.16 Implementation phases

---

## Phase 1: Foundation

**Complexity:** S  
**Estimated effort:** 1 session (~2–3 h)  
**Prerequisites:** Plan approved; Setup Guide Phase A/B for topics 01–02  
**Milestone:** toward M1  
**Setup Guide topics:** `docs/setup/01-prerequisites.md`, `docs/setup/02-repo-foundation.md`

### Objectives

- Materialize repo skeleton, documentation spine, pinned versions, ADRs for locked decisions.
- Confirm local/AWS/GitLab prerequisite tooling without provisioning cluster.

### Tasks (with repo files/actions)

- Create directory tree and root `README.md`, `Makefile` (lint/validate only), `.gitignore`, `.pre-commit-config.yaml`, `CODEOWNERS` (`@btilki` on prod paths stub).
- Write `docs/versions.md`, `docs/ARCHITECTURE.md`, `docs/architecture/*` (security, observability, topology, DNS/TLS).
- ADRs: digest-only GitOps; single-cluster namespaces; ACM+ALB; DNS hostname scheme; observability without CW/PD/OTel.
- Setup Guide topics 01–02 content + Required Files Inventory consumption.
- Human: install CLI versions per `docs/versions.md`; confirm AWS identity and Route53 zone.

### Expected outputs

- Repo browseable; architecture readable; no AWS bill yet (except existing Route53 if any).

### Validation criteria

- [ ] `docs/versions.md` lists Trivy `0.71.0`, cosign `2.4.x`, EKS `1.31`, region `eu-central-1`
- [ ] `terraform/`, `gitops/`, `charts/`, `docs/setup/` directories exist
- [ ] `aws sts get-caller-identity` succeeds (human)
- [ ] Route53 zone for `biroltilki.art` identifiable

### Risks for this phase

- Doc drift vs locked Planning Gate — mitigate by copying decision table into ADRs.

### Rollback / cleanup

- Delete files / reset git; no cloud state.

### Approval gate

Wait for confirmation before Phase 2.

---

## Phase 2: AWS foundation (Terraform)

**Complexity:** L  
**Estimated effort:** 2–3 sessions  
**Prerequisites:** Phase 1 complete  
**Milestone:** toward M1  
**Setup Guide topics:** `docs/setup/03-remote-state.md`, `docs/setup/04-network-eks-ecr-iam.md`

### Objectives

- Bootstrap S3+DynamoDB remote state; provision VPC (single NAT), EKS 1.31, 3× `m6i.large`, ECR for 7 services, GitLab OIDC role, IRSA scaffolding, ACM cert validation inputs.

### Tasks

- Modules: `terraform/modules/{network,eks,ecr,dns,iam_gitlab_oidc,irsa}/` with module READMEs.
- Env: `terraform/envs/prod/` (`eu-central-1`, tfvars example without secrets).
- Outputs: cluster name, OIDC issuer, ECR URLs, role ARNs, subnet IDs.
- Human: apply remote state → apply foundation; update kubeconfig; verify nodes.

### Expected outputs

- Live EKS; empty ECR repos; IAM OIDC provider + CI role trust documented.

### Validation criteria

- [ ] `kubectl get nodes` → Ready (3)
- [ ] ECR repos exist for 7 services
- [ ] Terraform state locked in S3/DynamoDB
- [ ] OIDC provider present in IAM

### Risks for this phase

- AZ capacity / instance availability — verify `m6i.large` offerings; fall back `m7i.large` if needed.
- Cost if not destroyed — document destroy runbook early.

### Rollback / cleanup

- `terraform destroy` (order: workloads none yet → cluster → network → state buckets last if empty).

### Approval gate

Wait before Phase 3.

---

## Phase 3: Ingress, DNS, TLS

**Complexity:** M  
**Estimated effort:** 1–2 sessions  
**Prerequisites:** Phase 2  
**Milestone:** **M1**  
**Setup Guide topics:** `docs/setup/05-ingress-dns-tls.md`

### Objectives

- Install AWS LB Controller, external-dns, cert-manager via GitOps-ready manifests/Helm values; ACM cert for boutique hosts; smoke Ingress.

### Tasks

- Platform charts/values under `gitops/platform/{aws-load-balancer-controller,external-dns,cert-manager}/`.
- IRSA roles from Terraform outputs.
- Document DNS:

  - `argocd.boutique.biroltilki.art`
  - `grafana.boutique.biroltilki.art`
  - `dev-boutique.biroltilki.art`
  - `stage-boutique.biroltilki.art`
  - `boutique.biroltilki.art`

- Temporary smoke Ingress + TLS via ACM annotations.
- Docs: `docs/dns-and-tls.md`.

### Expected outputs

- HTTPS 200/302 on smoke host; DNS records created by external-dns.

### Validation criteria

- [ ] Controller pods healthy
- [ ] ACM cert ISSUED
- [ ] `curl -I https://<smoke-host>` succeeds
- [ ] cert-manager pods Running (even if ACM is public TLS path)

### Risks for this phase

- ACM DNS validation lag; IRSA annotation mistakes.

### Rollback / cleanup

- Delete smoke Ingress/ALB; retain controllers or uninstall via Git.

### Approval gate

**M1 FC review** then wait before Phase 4.

---

## Phase 4: Argo CD GitOps bootstrap

**Complexity:** M  
**Estimated effort:** 1–2 sessions  
**Prerequisites:** Phase 3  
**Milestone:** toward M2  
**Setup Guide topics:** `docs/setup/06-argocd-bootstrap.md`

### Objectives

- Bootstrap Argo CD; root app-of-apps; ApplicationSets for platform and workloads; sync waves; prod **manual** sync.

### Tasks

- `gitops/bootstrap/` install + root Application.
- `gitops/apps/platform-apps/`, `gitops/apps/workload-apps/`.
- Ingress for `argocd.boutique.biroltilki.art`.
- Document sync policy matrix (dev/stage auto; prod manual).

### Expected outputs

- Argo UI reachable; platform apps syncing; empty/placeholder workload apps OK.

### Validation criteria

- [ ] Argo CD healthy
- [ ] Root app Synced
- [ ] Prod Application `syncPolicy.automated` absent/null
- [ ] Login via documented method (SSO later optional)

### Risks for this phase

- Git repo credentials / GitLab visibility; sync loops.

### Rollback / cleanup

- Delete Argo apps; uninstall Argo namespace carefully.

### Approval gate

Wait before Phase 5.

---

## Phase 5: Security baseline

**Complexity:** M  
**Estimated effort:** 1–2 sessions  
**Prerequisites:** Phase 4  
**Milestone:** toward M2  
**Setup Guide topics:** `docs/setup/07-security-baseline.md`

### Objectives

- Enforce digest-only / no `:latest` / ECR allowlist; ESO→Secrets Manager/SSM; default-deny NetworkPolicy patterns.

### Tasks

- `gitops/platform/kyverno/` ClusterPolicies.
- `gitops/platform/external-secrets/` operator + ClusterSecretStore example.
- `gitops/platform/network-policies/` per-namespace baselines.
- `examples/` sample ExternalSecret.
- Test: deploy pod with `:latest` → denied.

### Expected outputs

- Policy reports; synced ExternalSecret; NP applied to `dev`/`stage`/`prod`/`platform`.

### Validation criteria

- [ ] `:latest` admission denied in test namespace
- [ ] Digest-pinned test pod allowed (from allowlisted ECR or documented exception for phase)
- [ ] ExternalSecret shows Secret Created
- [ ] Default-deny verified with intentional probe

### Risks for this phase

- Blocking platform controllers — exclude system namespaces carefully.

### Rollback / cleanup

- Set Kyverno policies to Audit; delete failing policies via Git revert.

### Approval gate

Wait before Phase 6.

---

## Phase 6: Observability baseline

**Complexity:** M  
**Estimated effort:** 1–2 sessions  
**Prerequisites:** Phase 5  
**Milestone:** **M2**  
**Setup Guide topics:** `docs/setup/08-observability.md`

### Objectives

- Deploy Prometheus, Grafana, Alertmanager, Loki; Grafana at `grafana.boutique.biroltilki.art`; one critical alert delivered by **email**.

### Tasks

- `gitops/platform/monitoring/` kube-prometheus-stack + Loki values (retention caps).
- Grafana Ingress ACM.
- Alertmanager **email** receiver config via ESO (SMTP credentials in Secrets Manager/SSM — no secrets in Git).
- Runbook: `docs/runbooks/alerting.md`.

### Expected outputs

- Grafana dashboards; Loki queries; test alert received by email.

### Validation criteria

- [ ] Grafana HTTPS login works
- [ ] Prometheus targets up for critical components
- [ ] Loki ingests pod logs
- [ ] Test alert arrives in the configured mailbox

### Risks for this phase

- Memory pressure — reduce retention; add node if needed.

### Rollback / cleanup

- Suspend monitoring Application; reclaim PVCs if used.

### Approval gate

**M2 FC review** then wait before Phase 7.

---

## Phase 7: Boutique Helm charts + env overlays

**Complexity:** L  
**Estimated effort:** 2–3 sessions  
**Prerequisites:** Phase 6  
**Milestone:** toward M3  
**Setup Guide topics:** `docs/setup/09-boutique-charts.md`

### Objectives

- Package 7 services + Redis with `image.repository` + `image.digest`; deploy via ApplicationSet to `dev` (and stage placeholders); frontend hostnames live.

### Tasks

- Charts under `charts/{frontend,productcatalogservice,cartservice,checkoutservice,currencyservice,paymentservice,shippingservice}/` (+ Redis dependency for cart).
- `gitops/envs/{dev,stage,prod}/` values and digest pins.
- **Bootstrap (required before first CI):** one-time build/pull → push of the 7 service images to ECR by digest; record digests in `gitops/envs/dev/` so Argo can sync without waiting for the full GitLab pipeline. Document exact commands in Setup Guide `09`.
- Workload ApplicationSet paths.
- ServiceMonitors where useful.

### Expected outputs

- `dev-boutique.biroltilki.art` serves storefront (browse/cart path).

### Validation criteria

- [ ] All 7 deployments Ready in `dev`
- [ ] Frontend HTTPS OK on `dev-boutique.biroltilki.art`
- [ ] Charts expose only digest-based image refs in rendered manifests
- [ ] `helm lint` / template CI job green (local Makefile)

### Risks for this phase

- Checkout needs payment/shipping wiring — include both charts; fix values/service names.
- Ordering vs CI — **bootstrap ECR digests first** (locked); then Phase 8 takes over ongoing digests.

### Rollback / cleanup

- Git revert env overlays; Argo prune.

### Approval gate

Wait before Phase 8.

---

## Phase 8: GitLab CI digest pipeline

**Complexity:** L  
**Estimated effort:** 2 sessions  
**Prerequisites:** Phase 7 (charts exist); Phase 2 OIDC  
**Milestone:** toward M3  
**Setup Guide topics:** `docs/setup/10-gitlab-ci-digest.md`

### Objectives

- Implement test→build→scan→sign→gitops MR; OIDC to ECR; **never** kubectl/argocd in CI.

### Tasks

- `.gitlab-ci.yml` with pinned Trivy `0.71.0` and cosign `2.4.x`.
- Jobs: unit/lint as applicable; build; Trivy CRITICAL fail; cosign sign; open MR patching `gitops/envs/dev/**` digests only.
- Docs: CI contract in `docs/architecture/` or `docs/ci.md`.
- Signing: **Sigstore keyless** via GitLab OIDC (`id_tokens` / `SIGSTORE_ID_TOKEN`, aud `sigstore`); ADR-0006/0009 records this. Verify with `cosign verify` using GitLab certificate identity claims.

### Expected outputs

- Pipeline green; digest-only MR; Argo auto-syncs `dev` after merge.

### Validation criteria

- [ ] Pipeline has no `kubectl` / `argocd` commands
- [ ] Trivy fails build on planted CRITICAL (test) or documented gate config
- [ ] Cosign verify succeeds on pushed digest
- [ ] MR diff touches only digest fields

### Risks for this phase

- OIDC subject mismatch; ECR auth; MR token permissions.

### Rollback / cleanup

- Disable pipeline schedules; revoke IAM role trust if needed.

### Approval gate

Wait before Phase 9.

---

## Phase 9: Promotion governance + frontend canary

**Complexity:** L  
**Estimated effort:** 2 sessions  
**Prerequisites:** Phase 8  
**Milestone:** toward M3  
**Setup Guide topics:** `docs/setup/11-promotion.md`, `docs/setup/12-canary-rollouts.md`

### Objectives

- Digest-copy promotion to stage/prod with CODEOWNERS `@btilki`; document rollback; Argo Rollouts canary for frontend on **stage and prod** (ALB traffic split); abort via digest revert.

### Tasks

- `docs/promotion.md`, `docs/rollback.md`.
- Protect `main` / prod paths in GitLab; enforce CODEOWNERS.
- Install `gitops/platform/argo-rollouts/`; convert frontend to Rollout; canary steps in stage then prod values.
- Manual prod sync procedure documented.

### Expected outputs

- Successful promote to stage; prod MR requires `@btilki`; canary progresses; revert aborts.

### Validation criteria

- [ ] Stage promotion MR merges; stage hostname updated
- [ ] Prod MR blocked without owner approval (or simulated)
- [ ] Prod Application still manual sync
- [ ] Canary on stage and prod: weight steps observed
- [ ] `git revert` of digest restores previous ReplicaSet/Rollout

### Risks for this phase

- Kyverno vs Rollouts; ALB canary ingress annotations.

### Rollback / cleanup

- Disable canary (full weight stable); Git revert.

### Approval gate

Wait before Phase 10.

---

## Phase 10: Production readiness

**Complexity:** M  
**Estimated effort:** 1–2 sessions  
**Prerequisites:** Phase 9  
**Milestone:** **M3**  
**Setup Guide topics:** `docs/setup/13-production-readiness.md`

### Objectives

- Complete checklist, architecture diagrams (Mermaid), runbooks; full build→prod path demo. Teardown is **Phase 11** (not optional for short pilots).

### Tasks

- `docs/PRODUCTION_CHECKLIST.md`.
- Runbooks: ingress down, Argo sync stuck, Kyverno block, canary abort.
- Verify ECR scan-on-push; no unsigned/`latest` on prod path.
- Update `ROADMAP.md` statuses for phases 1–10.
- Human: end-to-end demo; then **proceed immediately to Phase 11 teardown** (no keep-alive after tests).

### Expected outputs

- Checklist all green; docs consistent; ROADMAP phases 1–10 ✅.

### Validation criteria

- [ ] Checklist items checked with evidence notes
- [ ] `boutique.biroltilki.art` serves prod via manual sync
- [ ] Rollback doc validated once
- [ ] No Must FR (except FR-11 teardown) left unmapped

### Risks for this phase

- Doc debt — fix before calling done.

### Rollback / cleanup

- None in this phase; decommission is Phase 11.

### Approval gate

**M3 FC review** → **Phase 11 teardown immediately** after tests (mandatory; do not leave cluster running).

---

## Phase 11: Teardown

**Complexity:** M  
**Estimated effort:** 1 session (~2–4 h)  
**Prerequisites:** Phase 10 complete (or explicit early abort after any billable phase)  
**Milestone:** **M4**  
**Setup Guide topics:** `docs/setup/14-teardown.md`

### Objectives

- Fully decommission the pilot so AWS charges stop: remove GitOps-managed workloads/ALBs first, then Terraform-managed foundation, then verify no orphans.

### Tasks

- Author `docs/runbooks/teardown.md` and `docs/setup/14-teardown.md` with **ordered** steps.
- Human execute (guide is source of truth):
  1. Disable GitLab schedules / protect against re-pipeline pushes if needed
  2. Delete/prune Argo Applications (workloads → platform → bootstrap) so ALBs/TargetGroups/PVCs release
  3. Confirm Load Balancers and ENIs gone (or note leftovers)
  4. `terraform destroy` in `terraform/envs/prod/` (EKS, nodes, NAT, VPC, IAM roles as coded)
  5. Empty/delete ECR images if repos retained or destroy ECR via Terraform
  6. Decide remote state bucket/table: empty + destroy **last** (or retain empty state intentionally — document choice)
  7. Remove ACM unused certs / confirm Route53 records cleaned by external-dns before destroy
- Update `ROADMAP.md` Phase 11 ✅; note destroy timestamp in checklist appendix.

### Expected outputs

- No EKS cluster; no NAT Gateway; no ALB from this project; nodes terminated.
- Written evidence of empty (or intentionally retained) residual resources.

### Validation criteria

- [ ] `aws eks list-clusters --region eu-central-1` does not list this cluster
- [ ] No NAT Gateway / ELBv2 from this VPC (or VPC deleted)
- [ ] EC2 instances for the node group gone
- [ ] Cost explorer / billing shows no ongoing EKS hourly charge for this cluster (next day check OK)
- [ ] Teardown runbook followed without ad-hoc undocumented steps

### Risks for this phase

- Orphan ALBs/ENIs if apps deleted out of order — always prune GitOps before Terraform.
- Remote state destroy while resources remain — never destroy backend first.
- Route53 records left behind — verify after external-dns shutdown.

### Rollback / cleanup

- Teardown is the cleanup. To rebuild: start again from Phase 2 apply (repo docs remain).

### Approval gate

Project complete for short pilot; or re-apply Phase 2+ if rebuilding.

---

## 7.17 Estimated complexity

| Phase | Title | Complexity | Cumulative risk | Notes |
|-------|--------|------------|-----------------|-------|
| 1 | Foundation | S | Low | Docs only |
| 2 | AWS foundation | L | Medium | First billable apply |
| 3 | Ingress DNS TLS | M | Medium | M1 |
| 4 | Argo bootstrap | M | Medium | |
| 5 | Security | M | Medium | Policy blast radius |
| 6 | Observability | M | Medium | M2; memory |
| 7 | Boutique charts | L | Medium | 7 services |
| 8 | GitLab CI | L | High | OIDC critical path |
| 9 | Promotion + canary | L | High | Prod canary |
| 10 | Production readiness | M | Low | M3 |
| 11 | Teardown | M | Medium | M4; orphan risk if order wrong |

| Rating | Meaning |
|--------|---------|
| S | < 2 h; few moving parts; easily reversible |
| M | 2–6 h; multiple components; some state |
| L | 6–12 h; significant state; debugging likely |
| XL | 12+ h or high blast radius — **none** if Phases 2/7/8 not combined |

---

## 7.18 Success criteria (project-level)

- [ ] Terraform provisions VPC, EKS 1.31, ECR (7), IAM/OIDC, remote state in `eu-central-1`
- [ ] Hostnames live with ACM+ALB; cert-manager installed
- [ ] Argo app-of-apps + ApplicationSet; prod manual sync
- [ ] Kyverno/ESO/NetworkPolicy enforced
- [ ] Prometheus + Loki + Grafana + Alertmanager (**email**) operational
- [ ] 7 Boutique services (+ Redis) on GitOps digests; storefront hostnames work
- [ ] GitLab CI: scan→sign→digest MR only; no cluster deploy from CI
- [ ] Promotion with `@btilki`; rollback via git revert documented and tested
- [ ] Frontend canary on stage **and** prod
- [ ] PRODUCTION_CHECKLIST complete
- [ ] Teardown runbook executed **immediately after tests** (Phase 11 mandatory)

---

## 10. Implementation roadmap (closing)

### 10.1 Progress tracker

| Phase | Title | Status | Setup topic | Key validation |
|-------|--------|--------|-------------|----------------|
| 1 | Foundation | ⬜ | 01, 02 | versions + dirs |
| 2 | AWS foundation | ⬜ | 03, 04 | `kubectl get nodes` |
| 3 | Ingress DNS TLS | ⬜ | 05 | HTTPS smoke |
| 4 | Argo CD | ⬜ | 06 | root app Synced; prod manual |
| 5 | Security | ⬜ | 07 | deny `:latest` |
| 6 | Observability | ⬜ | 08 | Grafana + **email** test alert |
| 7 | Boutique | ⬜ | 09 | dev hostname |
| 8 | GitLab CI | ⬜ | 10 | digest-only MR |
| 9 | Promotion + canary | ⬜ | 11, 12 | canary + CODEOWNERS |
| 10 | Production readiness | ⬜ | 13 | checklist |
| 11 | Teardown | ⬜ | 14 | cluster gone; no orphans |

### 10.2 Incremental value

See [ROADMAP.md](../../ROADMAP.md) — same statements.

### 10.3 Phase deliverable summary

| Phase | Key deliverables |
|-------|------------------|
| 1 | Docs spine, ADRs, versions, empty tree |
| 2 | Live EKS + ECR + OIDC |
| 3 | ACM+ALB platform |
| 4 | Argo CD control plane |
| 5 | Policy + secrets + NP |
| 6 | Metrics/logs/alerts (**email**) |
| 7 | Boutique on GitOps |
| 8 | Digest CI |
| 9 | Promotion + canaries |
| 10 | Checklist + demo |
| 11 | Ordered teardown + cost stop |

---

## 11. Cross-reference map

| Phase | Milestone | Setup topic | Key repo paths | FR IDs |
|-------|-----------|-------------|----------------|--------|
| 1 | — | 01-prerequisites, 02-repo-foundation | `docs/**`, `CODEOWNERS` | — |
| 2 | — | 03-remote-state, 04-network-eks-ecr-iam | `terraform/**` | FR-01 |
| 3 | M1 | 05-ingress-dns-tls | `gitops/platform/{aws-load-balancer-controller,external-dns,cert-manager}/` | FR-02 |
| 4 | — | 06-argocd-bootstrap | `gitops/bootstrap/`, `gitops/apps/` | FR-03 |
| 5 | — | 07-security-baseline | `gitops/platform/{kyverno,external-secrets,network-policies}/` | FR-04 |
| 6 | M2 | 08-observability | `gitops/platform/monitoring/` | FR-05 |
| 7 | — | 09-boutique-charts | `charts/**`, `gitops/envs/**` | FR-06 |
| 8 | — | 10-gitlab-ci-digest | `.gitlab-ci.yml` | FR-07 |
| 9 | — | 11-promotion, 12-canary-rollouts | `docs/promotion.md`, `docs/rollback.md`, `gitops/platform/argo-rollouts/` | FR-08, FR-09 |
| 10 | M3 | 13-production-readiness | `docs/PRODUCTION_CHECKLIST.md`, `docs/runbooks/` | FR-10 |
| 11 | M4 | 14-teardown | `docs/setup/14-teardown.md`, `docs/runbooks/teardown.md` | FR-11 |

---

## 8. Required Files Inventory (per setup topic)

Timing tags: **SETUP_REQUIRED** | **FEATURE_REQUIRED** | **RELEASE_REQUIRED**

### Topic 01 — prerequisites

| Path | Timing | Acceptance | Depends on |
|------|--------|------------|------------|
| `docs/setup/01-prerequisites.md` | SETUP_REQUIRED | CLI list, version pins, AWS/GitLab checks | Plan approved |
| `docs/versions.md` | SETUP_REQUIRED | Full pin matrix | — |

### Topic 02 — repo-foundation

| Path | Timing | Acceptance | Depends on |
|------|--------|------------|------------|
| `README.md` | SETUP_REQUIRED | Vision, quick links, how GitOps works | 01 |
| `CODEOWNERS` | SETUP_REQUIRED | `@btilki` on `gitops/envs/prod/**` | — |
| `.gitignore` | SETUP_REQUIRED | tfstate, secrets, IDE | — |
| `.pre-commit-config.yaml` | SETUP_REQUIRED | yaml/fmt/terraform fmt hooks | — |
| `Makefile` | SETUP_REQUIRED | `lint`, `docs-check` only | — |
| `docs/ARCHITECTURE.md` | SETUP_REQUIRED | Topology, DNS, sync, security, obs summary | Planning Gate |
| `docs/architecture/README.md` | SETUP_REQUIRED | Index + ADR list | — |
| `docs/architecture/01-requirements.md` | SETUP_REQUIRED | FRs/NFRs/constraints/assumptions | — |
| `docs/architecture/02-system-context.md` | SETUP_REQUIRED | Actors, env strategy | — |
| `docs/architecture/03-component-design.md` | SETUP_REQUIRED | Component diagram | — |
| `docs/architecture/04-data-flows.md` | SETUP_REQUIRED | App/GitOps/TF/secrets/telemetry | — |
| `docs/architecture/05-deployment-flow.md` | SETUP_REQUIRED | CI, promote, canary, rollback | — |
| `docs/architecture/06-network-design.md` | SETUP_REQUIRED | VPC, ingress, DNS, NP | — |
| `docs/architecture/07-security-architecture.md` | SETUP_REQUIRED | Trust zones, IRSA, supply chain | — |
| `docs/architecture/08-resilience-and-dr.md` | SETUP_REQUIRED | Failures, scale, DR | — |
| `docs/architecture/09-observability.md` | SETUP_REQUIRED | Prom/Loki/AM email | — |
| `docs/architecture/10-cost-model.md` | SETUP_REQUIRED | Cost + teardown ref | — |
| `docs/adr/0001-digest-only-gitops.md` | SETUP_REQUIRED | Decision + consequences | — |
| `docs/adr/0002-single-cluster-namespaces.md` | SETUP_REQUIRED | Decision | — |
| `docs/adr/0003-tls-acm-alb.md` | SETUP_REQUIRED | Decision | — |
| `docs/adr/0004-dns-hostname-scheme.md` | SETUP_REQUIRED | Decision | — |
| `docs/adr/0005-observability-on-cluster.md` | SETUP_REQUIRED | No CW/PD/OTel | — |
| `docs/setup/02-repo-foundation.md` | SETUP_REQUIRED | How to create dirs/files | 01 |
| `gitops/README.md` | SETUP_REQUIRED | Layout explainer | — |
| `terraform/README.md` | SETUP_REQUIRED | Module index stub | — |
| `charts/README.md` | SETUP_REQUIRED | Service list (7) | — |

### Topic 03 — remote-state

| Path | Timing | Acceptance | Depends on |
|------|--------|------------|------------|
| `docs/setup/03-remote-state.md` | SETUP_REQUIRED | Exact bootstrap commands | Phase 1 |
| `terraform/backend.hcl.example` | SETUP_REQUIRED | bucket/table/region placeholders called out | — |
| `terraform/envs/prod/backend.tf` | SETUP_REQUIRED | S3+DynamoDB backend block | — |

### Topic 04 — network-eks-ecr-iam

| Path | Timing | Acceptance | Depends on |
|------|--------|------------|------------|
| `docs/setup/04-network-eks-ecr-iam.md` | SETUP_REQUIRED | Apply order + validations | 03 |
| `terraform/modules/network/**` | FEATURE_REQUIRED | VPC, public/private subnets, **1 NAT**, endpoints for S3/ECR | 03 |
| `terraform/modules/eks/**` | FEATURE_REQUIRED | EKS 1.31, m6i.large NG 2–5 | network |
| `terraform/modules/ecr/**` | FEATURE_REQUIRED | 7 repos, scan-on-push | — |
| `terraform/modules/dns/**` | FEATURE_REQUIRED | Zone data + ACM cert for hosts | Route53 |
| `terraform/modules/iam_gitlab_oidc/**` | FEATURE_REQUIRED | OIDC provider + CI role | GitLab issuer URL |
| `terraform/modules/irsa/**` | FEATURE_REQUIRED | Reusable IRSA module | EKS OIDC |
| `terraform/envs/prod/main.tf` | FEATURE_REQUIRED | Module wiring | modules |
| `terraform/envs/prod/variables.tf` | FEATURE_REQUIRED | Typed variables | — |
| `terraform/envs/prod/outputs.tf` | FEATURE_REQUIRED | Cluster, roles, ECR URLs | — |
| `terraform/envs/prod/terraform.tfvars.example` | FEATURE_REQUIRED | No secrets; region eu-central-1 | — |
| Each module `README.md` | FEATURE_REQUIRED | Purpose/inputs/outputs/deps/usage | — |

### Topic 05 — ingress-dns-tls

| Path | Timing | Acceptance | Depends on |
|------|--------|------------|------------|
| `docs/setup/05-ingress-dns-tls.md` | SETUP_REQUIRED | IRSA annotate, install, smoke test | Phase 2 |
| `docs/dns-and-tls.md` | FEATURE_REQUIRED | Hostname table + ACM notes | — |
| `gitops/platform/aws-load-balancer-controller/**` | FEATURE_REQUIRED | Helm values + Application | IRSA |
| `gitops/platform/external-dns/**` | FEATURE_REQUIRED | Route53 policy via IRSA | — |
| `gitops/platform/cert-manager/**` | FEATURE_REQUIRED | Install only (ACM primary) | — |
| `examples/smoke-ingress.yaml` | FEATURE_REQUIRED | Temporary ACM Ingress | controllers |

### Topic 06 — argocd-bootstrap

| Path | Timing | Acceptance | Depends on |
|------|--------|------------|------------|
| `docs/setup/06-argocd-bootstrap.md` | SETUP_REQUIRED | Bootstrap order, GitLab repo connect | Phase 3 |
| `gitops/bootstrap/**` | FEATURE_REQUIRED | Install + root App | — |
| `gitops/apps/platform-apps/**` | FEATURE_REQUIRED | ApplicationSet/apps | bootstrap |
| `gitops/apps/workload-apps/**` | FEATURE_REQUIRED | ApplicationSet envs | bootstrap |
| `gitops/apps/README.md` | FEATURE_REQUIRED | Sync wave + prod manual | — |

### Topic 07 — security-baseline

| Path | Timing | Acceptance | Depends on |
|------|--------|------------|------------|
| `docs/setup/07-security-baseline.md` | SETUP_REQUIRED | Policy apply + deny test | Phase 4 |
| `gitops/platform/kyverno/**` | FEATURE_REQUIRED | Digest/latest/ECR policies | Argo |
| `gitops/platform/external-secrets/**` | FEATURE_REQUIRED | Operator + ClusterSecretStore | IRSA |
| `gitops/platform/network-policies/**` | FEATURE_REQUIRED | Default-deny + allows | namespaces |
| `examples/externalsecret-sample.yaml` | FEATURE_REQUIRED | SM/SSM ref pattern | ESO |

### Topic 08 — observability

| Path | Timing | Acceptance | Depends on |
|------|--------|------------|------------|
| `docs/setup/08-observability.md` | SETUP_REQUIRED | Stack install + alert test | Phase 5 |
| `gitops/platform/monitoring/**` | FEATURE_REQUIRED | kube-prometheus-stack + Loki values | — |
| `docs/runbooks/alerting.md` | FEATURE_REQUIRED | One critical rule; Alertmanager **email** | AM |

### Topic 09 — boutique-charts

| Path | Timing | Acceptance | Depends on |
|------|--------|------------|------------|
| `docs/setup/09-boutique-charts.md` | SETUP_REQUIRED | Chart create + **bootstrap ECR digests** before first CI | Phase 6 |
| `charts/<7 services>/**` | FEATURE_REQUIRED | `image.repository` + `image.digest` | — |
| `charts/README.md` | FEATURE_REQUIRED | Service map + Redis note | — |
| `gitops/envs/dev/**` | FEATURE_REQUIRED | Digests + ingress host | charts |
| `gitops/envs/stage/**` | FEATURE_REQUIRED | Overlay structure | charts |
| `gitops/envs/prod/**` | FEATURE_REQUIRED | Overlay; manual sync | charts |

### Topic 10 — gitlab-ci-digest

| Path | Timing | Acceptance | Depends on |
|------|--------|------------|------------|
| `docs/setup/10-gitlab-ci-digest.md` | SETUP_REQUIRED | OIDC config UI + pipeline | Phase 2 IAM, Phase 7 charts |
| `docs/ci.md` | FEATURE_REQUIRED | Contract: digest-only MR | — |
| `.gitlab-ci.yml` | FEATURE_REQUIRED | test→build→scan→sign→gitops | versions |
| `docs/adr/0006-cosign-signing-mode.md` | FEATURE_REQUIRED | **Sigstore keyless** via GitLab OIDC (locked) | — |

### Topic 11 — promotion

| Path | Timing | Acceptance | Depends on |
|------|--------|------------|------------|
| `docs/setup/11-promotion.md` | SETUP_REQUIRED | MR flow stage/prod | Phase 8 |
| `docs/promotion.md` | FEATURE_REQUIRED | Digest-copy rules | — |
| `docs/rollback.md` | FEATURE_REQUIRED | git revert procedure | — |
| `CODEOWNERS` | FEATURE_REQUIRED | Enforced on prod paths | GitLab settings |

### Topic 12 — canary-rollouts

| Path | Timing | Acceptance | Depends on |
|------|--------|------------|------------|
| `docs/setup/12-canary-rollouts.md` | SETUP_REQUIRED | Install Rollouts; ALB steps | Phase 9 start |
| `gitops/platform/argo-rollouts/**` | FEATURE_REQUIRED | Operator | Argo |
| `charts/frontend` Rollout templates | FEATURE_REQUIRED | Canary spec | Rollouts |
| `gitops/envs/stage|prod` canary values | FEATURE_REQUIRED | Weights for stage+prod | — |

### Topic 13 — production-readiness

| Path | Timing | Acceptance | Depends on |
|------|--------|------------|------------|
| `docs/setup/13-production-readiness.md` | SETUP_REQUIRED | Checklist execution | Phase 9 |
| `docs/PRODUCTION_CHECKLIST.md` | RELEASE_REQUIRED | All Must items | — |
| `docs/runbooks/*.md` | RELEASE_REQUIRED | Ingress, Argo, Kyverno, canary | — |
| `ROADMAP.md` status update | RELEASE_REQUIRED | Phases 1–10 ✅ | — |

### Topic 14 — teardown

| Path | Timing | Acceptance | Depends on |
|------|--------|------------|------------|
| `docs/setup/14-teardown.md` | SETUP_REQUIRED | Ordered steps; exact commands; validation | Phase 10 or early abort |
| `docs/runbooks/teardown.md` | RELEASE_REQUIRED | GitOps prune → ALB check → `terraform destroy` → orphan audit | 14 setup |
| `docs/PRODUCTION_CHECKLIST.md` (teardown appendix) | RELEASE_REQUIRED | Destroy evidence / deferral sign-off | Phase 10 checklist |

---

## Planning quality checklist

- [x] Every in-scope FR mapped to a phase
- [x] Every phase has objectives, tasks, outputs, validation
- [x] No phase depends on a later phase
- [x] Complexity ratings honest (no XL; L called out)
- [x] Out-of-scope excluded from phases
- [x] Setup Guide topics align with phases
- [x] Required Files Inventory per setup topic
- [x] Rollback noted for stateful phases
- [x] Approval gate after each phase stated
- [x] Success criteria testable
- [x] Roadmap shows incremental value per phase

---

## Open questions (resolve at named phase)

1. ~~Alertmanager target~~ → **email** (locked)
2. ~~Cosign mode~~ → **Sigstore keyless** via GitLab OIDC (locked)
3. ~~Phase 7 bootstrap images~~ → **yes**, one-time ECR digest push before first CI (locked)
4. ~~After M3~~ → **Phase 11 teardown immediately** after all tests (locked)

No blocking open questions remain for architecture/plan.

---

## Next after plan approval

1. `pi-setup-guide` Phase A — topic catalog (from this cross-reference; includes `14-teardown`)
2. Setup Phase B — author guide + repo files **per topic** together
3. `fc-implementation` Bootstrap for Setup Phase C execution
4. FC reviews at M1 (Phase 3), M2 (Phase 6), M3 (Phase 10); M4 teardown validation after Phase 11
