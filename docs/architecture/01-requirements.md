# 01 — Requirements, constraints, assumptions

## Functional requirements

| ID | Requirement | Priority | Architectural implication |
|----|-------------|----------|---------------------------|
| FR-01 | Terraform: VPC, EKS 1.31+, ECR, Route53, IAM OIDC/IRSA, S3+DynamoDB state | Must | Modular Terraform; remote state before cluster |
| FR-02 | LB Controller, external-dns, cert-manager; hosts under biroltilki.art; ACM+ALB HTTPS | Must | Platform ingress layer; ACM primary TLS |
| FR-03 | Argo CD app-of-apps + ApplicationSet; auto lower envs; manual prod; sync waves | Must | GitOps control plane; prod syncPolicy null |
| FR-04 | Kyverno digest-only / no `:latest` / ECR allowlist; ESO; NetworkPolicy | Must | Admission + secrets + east-west controls |
| FR-05 | Prometheus, Loki, Grafana, Alertmanager → **email** | Must | On-cluster obs; no CW/PD/OTel |
| FR-06 | 7 Boutique services + Redis as Helm; env overlays; boutique hostnames | Must | `charts/` + `gitops/envs/*` |
| FR-07 | GitLab CI test→build→scan→sign→digest MR; OIDC; never kubectl/argocd | Must | CI touches Git+ECR only |
| FR-08 | Promotion MRs; CODEOWNERS `@btilki` on prod; promotion/rollback docs | Must | Human gate on prod digests |
| FR-09 | Frontend canary stage **and** prod (Argo Rollouts + ALB) | Must | Progressive delivery in both envs |
| FR-10 | PRODUCTION_CHECKLIST, diagrams, runbooks, full path demo | Must | Operability artifacts |
| FR-11 | Ordered teardown; verify no orphan billables | Must | Decommission path for cost control |

## Non-functional requirements

| Category | Requirement | Architectural implication |
|----------|-------------|---------------------------|
| Availability | Production-minimum on one cluster; prod changes deliberate | Manual prod sync; multi-AZ nodes; single NAT risk accepted |
| Scalability | 3 app envs + platform + 7 services; later multi-cluster without rewrite | ApplicationSet; path-based envs |
| Security | Least privilege; no secrets in Git; OIDC; signed images; admission | IRSA, ESO, Kyverno, cosign, Trivy |
| Observability | Metrics + logs + email alerts | Prom/Loki/Grafana/AM |
| Maintainability | Modular TF/Helm; phase delivery; docs | Repo layout + Setup Guide |
| Reproducibility | Pinned versions; digest pins; remote state | `docs/versions.md` |
| Cost | Solo/pilot suitable; teardown mandatory for short tests | 1 NAT; 3× m6i.large; Phase 11 |
| Compliance | Audit-friendly Git + signatures + CODEOWNERS | No formal SOC2 scope |

## Derived requirements

| ID | Derived from | Requirement | Implication |
|----|--------------|-------------|-------------|
| DR-01 | GitOps choice | Desired state must live in Git reviewably | Narrow digest-only promotion contract |
| DR-02 | Digest-only | Charts must expose `image.repository` + `image.digest` | Helm values schema |
| DR-03 | No CI deploy | Argo must have Git credentials / repo access | Bootstrap secrets via ESO/IRSA not long-lived in Git |
| DR-04 | ECR allowlist | Kyverno needs account/registry allow rules | Policy params from TF outputs |
| DR-05 | Alertmanager email | SMTP credentials outside Git | ESO → Secrets Manager |
| DR-06 | Single NAT | Private-subnet egress SPOF | Documented in resilience |
| DR-07 | Canary + ALB | Rollouts needs Ingress/ALB integration annotations | Frontend chart uses Rollout CR |

## Constraints → design impact

| Constraint | Design impact |
|------------|---------------|
| Budget / 2-day tests | Single cluster, single NAT, teardown Phase 11 |
| AWS only | No Azure/GCP paths |
| One EKS cluster | Namespaces + Git paths for envs |
| No static AWS keys | GitLab OIDC → IAM; IRSA for pods |
| Digest-only / no `:latest` | Kyverno + CI contract |
| CI must not deploy | Stages end at digest MR |
| Prod manual + `@btilki` | ApplicationSet + CODEOWNERS + branch protection |
| No CW / PD / OTel | Prom/Loki/AM email only |
| Solo implementer | Phase size 1–3 sessions; no mesh |
| GitLab (not GitHub) | `.gitlab-ci.yml`; GitLab OIDC issuer |

## Assumptions → validation

| Assumption | Validate in Setup |
|------------|-------------------|
| Admin AWS account | `01-prerequisites` — STS identity |
| Route53 zone `biroltilki.art` | `01` / `05` — zone ID |
| GitLab project + OIDC federation | `01` docs; live in `10` |
| SMTP reachable for Alertmanager | `08-observability` |
| Low traffic (pilot) | Implicit; ALB LCU stays low |
| `m6i.large` in eu-central-1 | Confirmed; re-check at `04` apply |
| Namespace isolation acceptable | ADR single-cluster; accept residual risk |
