# Required Files Inventory — planning

**Maintainer inventory — not a reader path.** Skip for hiring review. Prefer the numbered topic guides under `docs/setup/`.  

**Timing tags:** `SETUP_REQUIRED` | `FEATURE_REQUIRED` | `RELEASE_REQUIRED`  
**Rule:** each topic’s files ship with the topic guide. No deferral (“later”) without explicit approval — use minimal valid content + `TODO(setup:N.M)` markers if details are incomplete.  
**Already in repo:** marked **EXISTS** — align/update rather than inventing from scratch.

Owner step IDs refer to [OUTLINES.md](OUTLINES.md).

---

## Topic 01 — Prerequisites

| Path | Timing | Owner step | Minimum content | Status |
|------|--------|------------|-----------------|--------|
| `docs/setup/01-prerequisites.md` | SETUP_REQUIRED | — (guide) | Full topic template; CLI matrix; AWS/GitLab/Route53/SMTP checks | EXISTS |
| `docs/versions.md` | SETUP_REQUIRED | 1.2–1.5; align in 02 | Pin matrix: Terraform ≥1.9, EKS 1.31, kubectl 1.31.x, Helm 3.16.x, Argo CD 2.14.x, Trivy 0.71.0, cosign 2.4.x, region `eu-central-1` | EXISTS |

---

## Topic 02 — Repo foundation

| Path | Timing | Owner step | Minimum content | Status |
|------|--------|------------|-----------------|--------|
| `docs/setup/02-repo-foundation.md` | SETUP_REQUIRED | — | How to create dirs/files; validation | EXISTS |
| `README.md` | SETUP_REQUIRED | 2.1+ | Vision, links, GitOps rules | EXISTS — links aligned |
| `ROADMAP.md` | SETUP_REQUIRED | 2.7 | Phase tracker | EXISTS |
| `CODEOWNERS` | SETUP_REQUIRED | 2.5 | `@btilki` on `gitops/envs/prod/**` | EXISTS |
| `.gitignore` | SETUP_REQUIRED | 2.5 | tfstate, `.terraform/`, secrets, IDE, `backend.hcl` | EXISTS |
| `.pre-commit-config.yaml` | SETUP_REQUIRED | 2.5 | yaml lint, terraform fmt, trailing whitespace | EXISTS |
| `Makefile` | SETUP_REQUIRED | 2.5 | `lint`, `docs-check` only (no install bypass) | EXISTS |
| `SECURITY.md` | SETUP_REQUIRED | 2.6 | Threat model summary + pointers | EXISTS |
| `docs/versions.md` | SETUP_REQUIRED | 2.2 | Full locked pin matrix | EXISTS (Topic 01) |
| `docs/ARCHITECTURE.md` | SETUP_REQUIRED | 2.3 | Topology, DNS, sync, security, obs | EXISTS — Accepted |
| `docs/architecture/README.md` | SETUP_REQUIRED | 2.3 | Index + ADR list | EXISTS — ADR links updated |
| `docs/architecture/01-requirements.md` … `10-cost-model.md` | SETUP_REQUIRED | 2.3 | Deep architecture set | EXISTS |
| `docs/implementation/plan.md` | SETUP_REQUIRED | — | Phases + inventories | EXISTS |
| `docs/adr/0001-digest-only-gitops.md` | SETUP_REQUIRED | 2.4 | Decision + consequences | EXISTS |
| `docs/adr/0002-single-cluster-namespaces.md` | SETUP_REQUIRED | 2.4 | Decision | EXISTS |
| `docs/adr/0003-tls-acm-alb.md` | SETUP_REQUIRED | 2.4 | Decision | EXISTS |
| `docs/adr/0004-dns-hostname-scheme.md` | SETUP_REQUIRED | 2.4 | Decision | EXISTS |
| `docs/adr/0005-observability-on-cluster.md` | SETUP_REQUIRED | 2.4 | No CW/PD/OTel | EXISTS |
| `terraform/README.md` | SETUP_REQUIRED | 2.6 | Module index stub | EXISTS |
| `gitops/README.md` | SETUP_REQUIRED | 2.6 | Layout + sync rules | EXISTS |
| `charts/README.md` | SETUP_REQUIRED | 2.6 | 7 services + Redis note | EXISTS |
| `examples/.gitkeep` | SETUP_REQUIRED | 2.1 | Keep dir | EXISTS |
| `tests/README.md` | SETUP_REQUIRED | 2.1 | Test layout stub | EXISTS |
| Dirs: `terraform/`, `gitops/{bootstrap,apps,platform,envs}`, `charts/`, `docs/adr/`, `docs/runbooks/` | SETUP_REQUIRED | 2.1 | Empty structure + README stubs as needed | EXISTS |

---

## Topic 03 — Remote state

| Path | Timing | Owner step | Minimum content | Status |
|------|--------|------------|-----------------|--------|
| `docs/setup/03-remote-state.md` | SETUP_REQUIRED | — | Exact bootstrap CLI; validation | EXISTS |
| `terraform/backend.hcl.example` | SETUP_REQUIRED | 3.4 | `bucket`, `key`, `region`, `dynamodb_table` placeholders called out | EXISTS |
| `terraform/envs/prod/backend.tf` | SETUP_REQUIRED | 3.4 | S3 + DynamoDB backend block | EXISTS |
| `terraform/envs/prod/versions.tf` | SETUP_REQUIRED | 3.4 | `terraform` ≥1.9; `aws` ~> 5.80 | EXISTS |

---

## Topic 04 — Network, EKS, ECR, IAM

| Path | Timing | Owner step | Minimum content | Status |
|------|--------|------------|-----------------|--------|
| `docs/setup/04-network-eks-ecr-iam.md` | SETUP_REQUIRED | — | Apply order + validations | EXISTS |
| `terraform/modules/network/**` | FEATURE_REQUIRED | 4.3 | VPC, public/private subnets, **1 NAT**, S3/ECR endpoints | EXISTS |
| `terraform/modules/eks/**` | FEATURE_REQUIRED | 4.4 | EKS 1.31, node group `m6i.large` ASG 2–5 | EXISTS |
| `terraform/modules/ecr/**` | FEATURE_REQUIRED | 4.5 | 7 repos, scan-on-push | EXISTS |
| `terraform/modules/dns/**` | FEATURE_REQUIRED | 4.6 | Zone data + ACM for boutique hosts | EXISTS |
| `terraform/modules/iam_gitlab_oidc/**` | FEATURE_REQUIRED | 4.7 | OIDC provider + CI role trust | EXISTS |
| `terraform/modules/irsa/**` | FEATURE_REQUIRED | 4.8 | Reusable IRSA module | EXISTS |
| `terraform/envs/prod/main.tf` | FEATURE_REQUIRED | 4.2 | Module wiring | EXISTS |
| `terraform/envs/prod/variables.tf` | FEATURE_REQUIRED | 4.2 | Typed variables | EXISTS |
| `terraform/envs/prod/outputs.tf` | FEATURE_REQUIRED | 4.2 | Cluster, OIDC, ECR URLs, role ARNs | EXISTS |
| `terraform/envs/prod/terraform.tfvars.example` | FEATURE_REQUIRED | 4.1 | No secrets; `eu-central-1` | EXISTS |
| Each module `README.md` | FEATURE_REQUIRED | 4.1 | Purpose / inputs / outputs / deps | EXISTS |

**ECR repos (7):** `frontend`, `productcatalogservice`, `cartservice`, `checkoutservice`, `currencyservice`, `paymentservice`, `shippingservice`.

---

## Topic 05 — Ingress, DNS, TLS

| Path | Timing | Owner step | Minimum content | Status |
|------|--------|------------|-----------------|--------|
| `docs/setup/05-ingress-dns-tls.md` | SETUP_REQUIRED | — | IRSA, install, smoke HTTPS | EXISTS |
| `docs/dns-and-tls.md` | FEATURE_REQUIRED | 5.5–5.7 | Hostname table + ACM notes | EXISTS |
| `gitops/platform/aws-load-balancer-controller/**` | FEATURE_REQUIRED | 5.2 | Helm values (+ AppSet in Topic 06) | EXISTS |
| `gitops/platform/external-dns/**` | FEATURE_REQUIRED | 5.3 | Route53 via IRSA | EXISTS |
| `gitops/platform/cert-manager/**` | FEATURE_REQUIRED | 5.4 | Install (ACM primary for public TLS) | EXISTS |
| `examples/smoke-ingress.yaml` | FEATURE_REQUIRED | 5.6 | Temporary ACM Ingress | EXISTS |

---

## Topic 06 — Argo CD bootstrap

| Path | Timing | Owner step | Minimum content | Status |
|------|--------|------------|-----------------|--------|
| `docs/setup/06-argocd-bootstrap.md` | SETUP_REQUIRED | — | Bootstrap order; GitLab repo connect GUI | EXISTS |
| `gitops/bootstrap/**` | FEATURE_REQUIRED | 6.1–6.4 | Install + root App | EXISTS |
| `gitops/apps/platform-apps/**` | FEATURE_REQUIRED | 6.5 | ApplicationSet / apps | EXISTS |
| `gitops/apps/workload-apps/**` | FEATURE_REQUIRED | 6.5 | Env ApplicationSet; prod manual | EXISTS |
| `gitops/apps/README.md` | FEATURE_REQUIRED | 6.5 | Sync waves + prod manual rule | EXISTS |

---

## Topic 07 — Security baseline

| Path | Timing | Owner step | Minimum content | Status |
|------|--------|------------|-----------------|--------|
| `docs/setup/07-security-baseline.md` | SETUP_REQUIRED | — | Policy apply + deny test | EXISTS |
| `gitops/platform/kyverno/**` | FEATURE_REQUIRED | 7.1–7.3 | Digest / `:latest` / ECR policies | EXISTS |
| `gitops/platform/external-secrets/**` | FEATURE_REQUIRED | 7.4–7.5 | Operator + ClusterSecretStore | EXISTS |
| `gitops/platform/network-policies/**` | FEATURE_REQUIRED | 7.6 | Default-deny + allows | EXISTS |
| `examples/externalsecret-sample.yaml` | FEATURE_REQUIRED | 7.5 | SM/SSM ref pattern | EXISTS |

---

## Topic 08 — Observability

| Path | Timing | Owner step | Minimum content | Status |
|------|--------|------------|-----------------|--------|
| `docs/setup/08-observability.md` | SETUP_REQUIRED | — | Stack install + email alert test | EXISTS |
| `gitops/platform/monitoring/**` | FEATURE_REQUIRED | 8.1–8.2 | kube-prometheus-stack + Loki values | EXISTS |
| `docs/runbooks/alerting.md` | FEATURE_REQUIRED | 8.4–8.5 | One critical rule; AM **email** | EXISTS |

---

## Topic 09 — Boutique charts

| Path | Timing | Owner step | Minimum content | Status |
|------|--------|------------|-----------------|--------|
| `docs/setup/09-boutique-charts.md` | SETUP_REQUIRED | — | Charts + **bootstrap ECR digests** + dev hostname | EXISTS |
| `charts/frontend/**` | FEATURE_REQUIRED | 9.1 | Chart with `image.repository` + `image.digest` | EXISTS |
| `charts/productcatalogservice/**` | FEATURE_REQUIRED | 9.1 | Same contract | EXISTS |
| `charts/cartservice/**` | FEATURE_REQUIRED | 9.1 | + Redis dependency notes | EXISTS |
| `charts/checkoutservice/**` | FEATURE_REQUIRED | 9.1 | Same contract | EXISTS |
| `charts/currencyservice/**` | FEATURE_REQUIRED | 9.1 | Same contract | EXISTS |
| `charts/paymentservice/**` | FEATURE_REQUIRED | 9.1 | Same contract | EXISTS |
| `charts/shippingservice/**` | FEATURE_REQUIRED | 9.1 | Same contract | EXISTS |
| `charts/redis/**` | FEATURE_REQUIRED | 9.1 | Redis companion chart (ECR-mirrored) | EXISTS |
| `charts/README.md` | FEATURE_REQUIRED | 9.1 | Service map + Redis | EXISTS |
| `gitops/envs/dev/**` | FEATURE_REQUIRED | 9.3 | Digests + ingress host | EXISTS |
| `gitops/envs/stage/**` | FEATURE_REQUIRED | 9.4 | Overlay structure | EXISTS |
| `gitops/envs/prod/**` | FEATURE_REQUIRED | 9.4 | Overlay; manual sync expectation | EXISTS |
| `gitops/apps/workload-apps/boutique-applicationset.yaml` | FEATURE_REQUIRED | 9.5 | Helm AppSet; prod manual | EXISTS |

---

## Topic 10 — GitLab CI digests

| Path | Timing | Owner step | Minimum content | Status |
|------|--------|------------|-----------------|--------|
| `docs/setup/10-gitlab-ci-digest.md` | SETUP_REQUIRED | — | OIDC GUI + pipeline validation | EXISTS |
| `docs/ci.md` | FEATURE_REQUIRED | 10.3 | Contract: digest-only MR; no cluster deploy | EXISTS |
| `.gitlab-ci.yml` | FEATURE_REQUIRED | 10.3 | test→build→scan→sign→sbom→gitops MR (SBOM Topic 15) | EXISTS (authoring + 12) |
| `docs/adr/0006-cosign-signing-mode.md` | FEATURE_REQUIRED | 10.5 | Sigstore keyless via GitLab OIDC | EXISTS |

---

## Topic 11 — Promotion

| Path | Timing | Owner step | Minimum content | Status |
|------|--------|------------|-----------------|--------|
| `docs/setup/11-promotion.md` | SETUP_REQUIRED | — | MR flow stage/prod | EXISTS |
| `docs/promotion.md` | FEATURE_REQUIRED | 11.1 | Digest-copy rules | EXISTS |
| `docs/rollback.md` | FEATURE_REQUIRED | 11.2 | `git revert` procedure | EXISTS |
| `CODEOWNERS` | FEATURE_REQUIRED | 11.3 | Enforced on prod paths (GitLab settings) | EXISTS — enforce in GitLab (Step 11.3) |

---

## Topic 12 — Canary rollouts

| Path | Timing | Owner step | Minimum content | Status |
|------|--------|------------|-----------------|--------|
| `docs/setup/12-canary-rollouts.md` | SETUP_REQUIRED | — | Rollouts install; ALB steps | EXISTS |
| `gitops/platform/argo-rollouts/**` | FEATURE_REQUIRED | 12.1 | Operator Application/values | EXISTS |
| `charts/frontend` Rollout templates | FEATURE_REQUIRED | 12.2 | Canary spec | EXISTS |
| `gitops/envs/stage/**` canary values | FEATURE_REQUIRED | 12.3 | Weights | EXISTS |
| `gitops/envs/prod/**` canary values | FEATURE_REQUIRED | 12.4 | Weights | EXISTS |

---

## Topic 13 — Production readiness

| Path | Timing | Owner step | Minimum content | Status |
|------|--------|------------|-----------------|--------|
| `docs/setup/13-production-readiness.md` | SETUP_REQUIRED | — | Checklist execution | EXISTS |
| `docs/PRODUCTION_CHECKLIST.md` | RELEASE_REQUIRED | 13.1 | All Must items + evidence fields | EXISTS |
| `docs/runbooks/*.md` | RELEASE_REQUIRED | 13.2 | Ingress, Argo, Kyverno, canary (min set) | EXISTS — alerting from 08; teardown in 14 |
| `ROADMAP.md` | RELEASE_REQUIRED | 13.4 | Phases 1–10 marked ✅ | EXISTS — mark ✅ at live M3 sign-off (Step 13.4) |

---

## Topic 14 — Teardown

| Path | Timing | Owner step | Minimum content | Status |
|------|--------|------------|-----------------|--------|
| `docs/setup/14-teardown.md` | SETUP_REQUIRED | — | Ordered steps; exact commands; validation | EXISTS |
| `docs/runbooks/teardown.md` | RELEASE_REQUIRED | 14.1–14.5 | GitOps prune → ALB check → `terraform destroy` → orphan audit | EXISTS |
| `docs/PRODUCTION_CHECKLIST.md` (teardown appendix) | RELEASE_REQUIRED | 14.6 | Destroy evidence / sign-off | EXISTS (Appendix T; fill at live M4) |

---

## Topic 15 — Supply chain verify + SBOM (Phase 12)

| Path | Timing | Owner step | Minimum content | Status |
|------|--------|------------|-----------------|--------|
| `docs/setup/15-supply-chain-verify-sbom.md` | SETUP_REQUIRED | — | Scaffold + apply-after-rebuild steps | EXISTS (Phase 12) |
| `docs/adr/0007-admission-verify-and-sbom.md` | FEATURE_REQUIRED | 15.1 | Admission Audit→Enforce + CycloneDX | EXISTS (Phase 12) |
| `gitops/platform/kyverno/policies/verify-image-signatures.yaml` | FEATURE_REQUIRED | 15.1 | Keyless verifyImages (Audit) | EXISTS (Phase 12) |
| `gitops/platform/kyverno/policies/verify-sbom-attestation.yaml` | FEATURE_REQUIRED | 15.1 | CycloneDX attest verify (Audit) | EXISTS (Phase 12) |
| `.gitlab-ci.yml` (`sbom` stage) | FEATURE_REQUIRED | 15.3 | Trivy CycloneDX + cosign attest | EXISTS (Phase 12) |
| `tests/policy/unsigned-digest-pod.yaml.example` | FEATURE_REQUIRED | 15.4 | Negative fixture template | EXISTS (Phase 12) |
| `docs/ci.md` (SBOM + verify) | FEATURE_REQUIRED | 15.1 | Contract update | EXISTS (Phase 12) |

---

## Topic 16 — CI security gates (Phase 12)

| Path | Timing | Owner step | Minimum content | Status |
|------|--------|------------|-----------------|--------|
| `docs/setup/16-ci-security-gates.md` | SETUP_REQUIRED | — | Gitleaks/Checkov/policy_test + ENABLE_REPO_GATES | EXISTS (Phase 12) |
| `.checkov.yaml` | FEATURE_REQUIRED | 16.1 | Terraform soft-fail + skip-check baseline | EXISTS (Phase 12) |
| `.gitleaks.toml` | FEATURE_REQUIRED | 16.1 | Allowlist for docs/examples | EXISTS (Phase 12) |
| `tests/policy/unit/**` | FEATURE_REQUIRED | 16.1 | Kyverno CLI unit tests | EXISTS (Phase 12) |
| `.gitlab-ci.yml` (gitleaks/checkov/policy_test) | FEATURE_REQUIRED | 16.4 | test-stage jobs | EXISTS (Phase 12) |
| `.pre-commit-config.yaml` (gitleaks) | FEATURE_REQUIRED | 16.2 | Local secret scan hook | EXISTS (Phase 12) |
| `docs/ci.md` (Topic 16 vars) | FEATURE_REQUIRED | 16.1 | Contract update | EXISTS (Phase 12) |

---

## Topic 17 — Argo CD hardening (Phase 12)

| Path | Timing | Owner step | Minimum content | Status |
|------|--------|------------|-----------------|--------|
| `docs/setup/17-argocd-hardening.md` | SETUP_REQUIRED | — | AppProjects first; SSO/notifications deferred | EXISTS (Phase 12) |
| `docs/adr/0008-argocd-appprojects-sso.md` | FEATURE_REQUIRED | 17.1 | Named projects + deferred Dex/notifications | EXISTS (Phase 12) |
| `gitops/bootstrap/argocd/hardening/projects/*.yaml` | FEATURE_REQUIRED | 17.3 | boutique-platform + boutique-workloads | EXISTS (Phase 12) |
| `gitops/bootstrap/argocd/hardening/sso/*.example` | FEATURE_REQUIRED | 17.4 | Dex GitLab values | EXISTS (Phase 12) |
| `gitops/bootstrap/argocd/hardening/notifications/*.example*` | FEATURE_REQUIRED | 17.5 | Notifications stubs | EXISTS (Phase 12) |
| ApplicationSets `project:` fields | FEATURE_REQUIRED | 17.1 | Named projects on child apps | EXISTS (Phase 12) |

---

## Topic 18 — Canary AnalysisTemplates (Phase 12)

| Path | Timing | Owner step | Minimum content | Status |
|------|--------|------------|-----------------|--------|
| `docs/setup/18-canary-analysis.md` | SETUP_REQUIRED | — | Sync templates; opt-in analysis | EXISTS (Phase 12) |
| `docs/adr/0009-canary-analysis-templates.md` | FEATURE_REQUIRED | 18.1 | Metric/smoke canary gates | EXISTS (Phase 12) |
| `gitops/platform/argo-rollouts/analysis/*.yaml` | FEATURE_REQUIRED | 18.3 | ClusterAnalysisTemplates | EXISTS (Phase 12) |
| `charts/frontend/templates/rollout.yaml` analysis | FEATURE_REQUIRED | 18.1 | Background + analysis.steps | EXISTS (Phase 12) |
| `gitops/envs/*/values/frontend-analysis.example.yaml` | FEATURE_REQUIRED | 18.4 | Stage/prod enable examples | EXISTS (Phase 12) |

---

## Topic 19 — Edge WAF + Falco (Phase 12)

| Path | Timing | Owner step | Minimum content | Status |
|------|--------|------------|-----------------|--------|
| `docs/setup/19-edge-runtime-waf-falco.md` | SETUP_REQUIRED | — | Enable WAF/Falco after rebuild | EXISTS (Phase 12) |
| `docs/adr/0010-edge-waf-and-falco.md` | FEATURE_REQUIRED | 19.1 | Optional WAF + Falco | EXISTS (Phase 12) |
| `terraform/modules/waf/**` | FEATURE_REQUIRED | 19.3 | WAFv2 when enable_waf | EXISTS (Phase 12) |
| `terraform/envs/prod` enable_waf + output | FEATURE_REQUIRED | 19.3 | Default false | EXISTS (Phase 12) |
| `gitops/platform/falco/values.yaml` | FEATURE_REQUIRED | 19.4 | Falco modern-bpf values | EXISTS (Phase 12) |
| `falco-applicationset-snippet.yaml.example` | FEATURE_REQUIRED | 19.4 | Not auto-synced | EXISTS (Phase 12) |
| `examples/waf-ingress-annotation.example.yaml` | FEATURE_REQUIRED | 19.3 | ALB WAF annotation | EXISTS (Phase 12) |

---

## Inventory summary (current)

| Topic | Guide file | Notes |
|-------|------------|--------|
| 01–14 | EXISTS | Reference complete (M3/M4); live AWS destroyed |
| 15–19 | EXISTS | Phase 12 **scaffold** in-repo; enable after rebuild |

**planning historical note:** Early planning treated guides as deferred until authoring. That gate is closed — guides and FEATURE files for Topics 01–19 now exist as listed above.
