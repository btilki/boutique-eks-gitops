# Production checklist — boutique-eks-gitops

**Audience:** L2 — Implementer / FC reviewer  
**Setup:** Topic 13 · **Milestone:** **M3 — Production path proven**  
**Authority:** Must FRs from [`docs/architecture/01-requirements.md`](architecture/01-requirements.md)  
**Related:** [Setup 13](setup/13-production-readiness.md) · [promotion](promotion.md) · [rollback](rollback.md) · [runbooks](runbooks/)

Filled **2026-07-19** during Phase C Topic 13.1 evidence walk.

**Sign-off**

| Field | Value |
|-------|--------|
| Operator | Birol Tilki (`@btilki`) |
| Date (UTC) | 2026-07-19 |
| M3 result | ✅ **PASS** · ⬜ FAIL |
| Notes | Path proven end-to-end. Stage realigned via !13 (`365c59d`); stage=prod `563ebf12…`; canary Healthy; HTTPS 200. C6=!12. Ignore red CI on digest MRs. |

---

## How to use

1. Walk sections top to bottom during Topic 13.
2. For each Must item: run the check, paste evidence, tick the box.
3. Complete **Demo path** (digest → promote → prod sync + canary).
4. Confirm runbooks are linked and usable.
5. On PASS: update [`ROADMAP.md`](../ROADMAP.md) phases **1–10** to ✅; proceed **immediately** to Topic 14 teardown (no keep-alive).

---

## A — Foundation & platform (FR-01 … FR-05)

| ID | Must check | Evidence | Done |
|----|------------|----------|------|
| A1 | EKS **1.31** Ready in `eu-central-1`; nodes Ready | 3 nodes Ready, `v1.31.14-eks-8f14419` (2026-07-19) | ✅ |
| A2 | Remote state S3 + lock table in use | `terraform/envs/prod/backend.tf` S3 backend + `backend.hcl` (Topic 03) | ✅ |
| A3 | ECR repos exist (7 services + redis); digests pulled | 8 repos `boutique-eks-gitops/*`; prod pods `@sha256:` | ✅ |
| A4 | GitLab OIDC IAM role works (no static AWS keys in CI) | Pipelines assume `boutique-eks-gitops-gitlab-ci` via OIDC (`AWS_ROLE_ARN`); e.g. build jobs on `main` | ✅ |
| A5 | Hostnames HTTPS via ACM+ALB: Argo, Grafana, boutique envs | `boutique`/`stage`/`dev` HTTPS **200**; `grafana.boutique…` **302** (2026-07-19) | ✅ |
| A6 | cert-manager installed (ACM remains public TLS) | `cert-manager` ns: controller/cainjector/webhook Running | ✅ |
| A7 | Argo CD app-of-apps; **prod sync = manual** | ~40 apps; `frontend-prod` `syncPolicy.automated` empty | ✅ |
| A8 | Kyverno denies `:latest` / requires digest / ECR allowlist | ClusterPolicies Ready: `deny-latest-tag`, `require-image-digest`, `ecr-registry-allowlist` | ✅ |
| A9 | ESO ClusterSecretStore Ready; SMTP secret for AM | `aws-cluster-secret-store` Valid/Ready; `alertmanager-smtp` SecretSynced | ✅ |
| A10 | NetworkPolicies present for `dev`/`stage`/`prod` | 5 netpol each in `dev`/`stage`/`prod` | ✅ |
| A11 | Grafana reachable; Alertmanager **email** proven (then test rule disabled) | Grafana 302; Topic 08 email received then rule set to `vector(0)` (`840c9f6`) | ✅ |
| A12 | Prometheus + Loki running with resource caps | `monitoring` ns: 10 pods Running (kube-prom + Loki) | ✅ |

---

## B — Workloads & supply chain (FR-06 … FR-07)

| ID | Must check | Evidence | Done |
|----|------------|----------|------|
| B1 | 7 Boutique services + Redis synced from Git digests | `prod` 8 pods Running, all images `…@sha256:…` | ✅ |
| B2 | Storefronts: `dev-boutique` / `stage-boutique` / `boutique` | All three HTTPS **200** (2026-07-19) | ✅ |
| B3 | Image contract = `repository` + `digest` only (no `:latest` in Git) | `grep -R ':latest' gitops/envs` → empty | ✅ |
| B4 | GitLab CI: test→build→scan(Trivy **0.71.0**)→sign→**digest MR only** | `.gitlab-ci.yml` stages; digest MR e.g. merge `8551a31` / `2adaea8`; Trivy pin `0.71.0` | ✅ |
| B5 | Cosign **keyless** sign (Sigstore); ADR-0006 followed | Sign jobs green on `main`; ECR `.sig` / keyless via `SIGSTORE_ID_TOKEN` | ✅ |
| B6 | CI does **not** call cluster API | `.gitlab-ci.yml`: no deploy kubectl/argocd; FORBIDDEN guards in gitops job | ✅ |

---

## C — Promotion, canary, rollback (FR-08 … FR-09)

| ID | Must check | Evidence | Done |
|----|------------|----------|------|
| C1 | Promote digests `dev → stage` via MR (digest-only) | `80e1fa7` / merge `d1a4ad3` `promote/stage-20260719` | ✅ |
| C2 | Promote `stage → prod` requires **`@btilki` CODEOWNERS** | CODEOWNERS + protected branch code-owner approval; merges `ccd3f8f`, `108f0bf` (!11) | ✅ |
| C3 | Prod Application synced **manually** after merge | Manual sync `frontend-prod` after !11 (2026-07-19 ~21:08Z) | ✅ |
| C4 | Frontend canary on **stage** (ALB weights observed) | Rollout Progressing→Paused→Healthy; 2 pods then promote (`1b75586` / `7c83613`) | ✅ |
| C5 | Frontend canary on **prod** after manual sync | Progressing/Paused dual-pod then Healthy on `563ebf12…` (`108f0bf`) | ✅ |
| C6 | Rollback via **`git revert`** documented and rehearsed once | [`rollback.md`](rollback.md); live digest restore MR **!12** (`a2bbfa2`, 2026-07-19) | ✅ |
| C7 | Canary abort path known (Rollout abort + Git revert) | Topic 12.5 + [`runbooks/canary.md`](runbooks/canary.md) / Step 12.5 | ✅ |

---

## D — Operability artifacts (FR-10)

| ID | Must check | Evidence | Done |
|----|------------|----------|------|
| D1 | Architecture docs Accepted + Mermaid readable | [`ARCHITECTURE.md`](ARCHITECTURE.md) | ✅ |
| D2 | ADRs 0001–0006 present | `docs/adr/0001`…`0006` listed | ✅ |
| D3 | Runbooks present: alerting, ingress, argo-sync, kyverno, canary | All five + README (+ teardown stub) | ✅ |
| D4 | Promotion + rollback docs linked from README | README + this checklist Related links | ✅ |
| D5 | Versions pin matrix matches live (EKS, Trivy, Rollouts, …) | EKS 1.31 live; Trivy/cosign/Rollouts pins in CI/AppSet (`docs/versions.md`) | ✅ |
| D6 | This checklist completed with evidence (this file) | Evidence filled 2026-07-19; C6 closed via !12 | ✅ |

---

## E — Demo path (required proof)

Record one end-to-end pass:

| Step | Action | Evidence |
|------|--------|----------|
| E1 | CI opens digest MR → `gitops/envs/dev/**` | e.g. MR merged as `8551a31` / later `e746f51` digest MRs |
| E2 | Merge → Argo syncs **dev** | `*-dev` apps Synced/Healthy |
| E3 | Promote MR → **stage**; canary progresses | `d1a4ad3` + stage canary `7c83613` |
| E4 | Promote MR → **prod** + `@btilki`; **manual** sync | `108f0bf` (!11) + manual `frontend-prod` sync |
| E5 | Prod canary → stable; `https://boutique.biroltilki.art` OK | Healthy + HTTPS 200 on `563ebf12…` |
| E6 | Optional: abort or revert once to prove recovery | MR **!12** rollback; cleanup **!13** realign stage→prod (`365c59d`, canary Healthy) |

Demo owner: Birol Tilki Date: 2026-07-19

---

## F — Explicit non-goals / deferred

| Item | Status |
|------|--------|
| FR-11 Teardown executed | ✅ Topic 14 / M4 PASS 2026-07-19 (Appendix T) |
| CloudWatch / PagerDuty / OTel | Out of scope (ADR-0005) |
| Multi-cluster / service mesh | Out of scope |

---

## Appendix T — Teardown evidence (Topic 14)

Complete during [`docs/setup/14-teardown.md`](setup/14-teardown.md) / [`docs/runbooks/teardown.md`](runbooks/teardown.md). Do **not** leave the cluster running after tests.

| Field | Value |
|-------|--------|
| Teardown start (UTC) | 2026-07-19 ~22:46 (approve → Step 14.1) |
| GitOps prune complete | ✅ Controllers scaled to 0; AppSets/apps deleted; Ingress finalizers cleared |
| ALBs / TGs gone (or listed leftovers) | ✅ ELBv2 count **0**; orphan `k8s-*` SGs deleted before VPC destroy |
| `terraform destroy` exit 0 | ✅ EKS+VPC destroyed; ECR force-deleted; second apply `Destroy complete! Resources: 0` (exit 0, ~23:13Z) |
| State backend retained or deleted (note which) | **Deleted (Option B)** 2026-07-20: S3 `boutique-eks-gitops-tfstate-868480224481` + DDB `boutique-eks-gitops-tf-locks` |
| Orphan audit clean / documented | ✅ Full wipe 2026-07-20: EKS/ELB/NAT/ECR/S3/DDB/SM/ACM/R53 = 0. Also deleted leftover launch templates, `/aws/eks/boutique-eks-gitops/cluster` log group, IAM `microservice-policy`. No boutique IAM roles. Account scaffolding left (default VPC, IAM login/`admin-user`, AWS service-linked roles) |
| ROADMAP Phase 11 ✅ | ✅ |
| Destroy evidence links | Local `terraform/envs/prod/destroy.tfplan`; CLI orphan audit 2026-07-19/20 |
| M4 result | ✅ **PASS** · ⬜ FAIL |

**Friction notes (for future rebuilds):** stop Argo controllers (or delete `root`) before AppSet delete or they recreate; strip `ingress.k8s.aws/resources` finalizers if LB controller already gone; delete leftover `k8s-*` SGs before VPC; ECR needs force delete when images present.

---

## M3 gate

**PASS** only if sections A–E are checked with evidence and no Must FR (except FR-11) is open.

**Current:** **M3 PASS** + **M4 PASS** (Topic 14 / Phase 11). Pilot **closed** — billable stack, TF backend, SM secrets, ACM, and Route53 zone removed. Rebuild = Topic 01 zone + Topic 03 remote-state first.
