# Production checklist — boutique-eks-gitops

**Audience:** L2 — Implementer / FC reviewer  
**Setup:** Topic 13 · **Milestone:** **M3 — Production path proven**  
**Authority:** Must FRs from [`docs/architecture/01-requirements.md`](architecture/01-requirements.md)  
**Related:** [Setup 13](setup/13-production-readiness.md) · [promotion](promotion.md) · [rollback](rollback.md) · [runbooks](runbooks/)

Fill **Evidence** with MR URLs, command output snippets, screenshots, or timestamps. Leave unchecked until proven live (Phase C).

**Sign-off**

| Field | Value |
|-------|--------|
| Operator | |
| Date (UTC) | |
| M3 result | ⬜ PASS · ⬜ FAIL |
| Notes | |

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
| A1 | EKS **1.31** Ready in `eu-central-1`; nodes Ready | `kubectl get nodes` | ⬜ |
| A2 | Remote state S3 + lock table in use | `terraform -chdir=terraform/envs/prod init` backend | ⬜ |
| A3 | ECR repos exist (7 services + redis); digests pulled | `aws ecr describe-repositories` / Argo Healthy | ⬜ |
| A4 | GitLab OIDC IAM role works (no static AWS keys in CI) | Pipeline job logs show OIDC assume-role | ⬜ |
| A5 | Hostnames HTTPS via ACM+ALB: Argo, Grafana, boutique envs | curl `-I` each host | ⬜ |
| A6 | cert-manager installed (ACM remains public TLS) | `kubectl -n cert-manager get pods` | ⬜ |
| A7 | Argo CD app-of-apps; **prod sync = manual** | App syncPolicy; no auto on `*-prod` | ⬜ |
| A8 | Kyverno denies `:latest` / requires digest / ECR allowlist | Policy test or deny event | ⬜ |
| A9 | ESO ClusterSecretStore Ready; SMTP secret for AM | `kubectl get clustersecretstore` | ⬜ |
| A10 | NetworkPolicies present for `dev`/`stage`/`prod` | `kubectl get netpol -A` | ⬜ |
| A11 | Grafana reachable; Alertmanager **email** proven (then test rule disabled) | Inbox + [`runbooks/alerting.md`](runbooks/alerting.md) | ⬜ |
| A12 | Prometheus + Loki running with resource caps | `kubectl -n monitoring get pods` | ⬜ |

---

## B — Workloads & supply chain (FR-06 … FR-07)

| ID | Must check | Evidence | Done |
|----|------------|----------|------|
| B1 | 7 Boutique services + Redis synced from Git digests | Argo apps Healthy; pods use `@sha256:` | ⬜ |
| B2 | Storefronts: `dev-boutique` / `stage-boutique` / `boutique` | HTTPS 200/302 | ⬜ |
| B3 | Image contract = `repository` + `digest` only (no `:latest` in Git) | `grep -R ':latest' gitops/envs \|\| true` empty | ⬜ |
| B4 | GitLab CI: test→build→scan(Trivy **0.71.0**)→sign→**digest MR only** | Pipeline URL; no kubectl/argocd deploy jobs | ⬜ |
| B5 | Cosign **keyless** sign (Sigstore); ADR-0006 followed | Job log / signature in ECR or Rekor | ⬜ |
| B6 | CI does **not** call cluster API | `.gitlab-ci.yml` review | ⬜ |

---

## C — Promotion, canary, rollback (FR-08 … FR-09)

| ID | Must check | Evidence | Done |
|----|------------|----------|------|
| C1 | Promote digests `dev → stage` via MR (digest-only) | MR URL | ⬜ |
| C2 | Promote `stage → prod` requires **`@btilki` CODEOWNERS** | Protected branch + approval | ⬜ |
| C3 | Prod Application synced **manually** after merge | Argo sync timestamp | ⬜ |
| C4 | Frontend canary on **stage** (ALB weights observed) | Rollout status / describe | ⬜ |
| C5 | Frontend canary on **prod** after manual sync | Rollout status / describe | ⬜ |
| C6 | Rollback via **`git revert`** documented and rehearsed once | Revert MR URL + [`rollback.md`](rollback.md) | ⬜ |
| C7 | Canary abort path known (Rollout abort + Git revert) | [`runbooks/canary.md`](runbooks/canary.md) | ⬜ |

---

## D — Operability artifacts (FR-10)

| ID | Must check | Evidence | Done |
|----|------------|----------|------|
| D1 | Architecture docs Accepted + Mermaid readable | [`ARCHITECTURE.md`](ARCHITECTURE.md) | ⬜ |
| D2 | ADRs 0001–0006 present | `docs/adr/` | ⬜ |
| D3 | Runbooks present: alerting, ingress, argo-sync, kyverno, canary | [`runbooks/README.md`](runbooks/README.md) | ⬜ |
| D4 | Promotion + rollback docs linked from README | Links resolve | ⬜ |
| D5 | Versions pin matrix matches live (EKS, Trivy, Rollouts, …) | [`versions.md`](versions.md) | ⬜ |
| D6 | This checklist completed with evidence (this file) | Sign-off table above | ⬜ |

---

## E — Demo path (required proof)

Record one end-to-end pass:

| Step | Action | Evidence |
|------|--------|----------|
| E1 | CI opens digest MR → `gitops/envs/dev/**` | Pipeline + MR URL |
| E2 | Merge → Argo syncs **dev** | App Healthy |
| E3 | Promote MR → **stage**; canary progresses | MR + Rollout |
| E4 | Promote MR → **prod** + `@btilki`; **manual** sync | MR + sync |
| E5 | Prod canary → stable; `https://boutique.biroltilki.art` OK | curl + Rollout |
| E6 | Optional: abort or revert once to prove recovery | MR / abort log |

Demo owner: _______________ Date: _______________

---

## F — Explicit non-goals / deferred

| Item | Status |
|------|--------|
| FR-11 Teardown executed | **Topic 14** — mandatory immediately after M3 |
| CloudWatch / PagerDuty / OTel | Out of scope (ADR-0005) |
| Multi-cluster / service mesh | Out of scope |

---

## Appendix T — Teardown evidence (Topic 14)

Complete during [`docs/setup/14-teardown.md`](setup/14-teardown.md) / [`docs/runbooks/teardown.md`](runbooks/teardown.md). Do **not** leave the cluster running after tests.

| Field | Value |
|-------|--------|
| Teardown start (UTC) | |
| GitOps prune complete | ⬜ |
| ALBs / TGs gone (or listed leftovers) | ⬜ |
| `terraform destroy` exit 0 | ⬜ |
| State backend retained or deleted (note which) | |
| Orphan audit clean / documented | ⬜ |
| ROADMAP Phase 11 ✅ | ⬜ |
| Destroy evidence links | |
| M4 result | ⬜ PASS · ⬜ FAIL |

---

## M3 gate

**PASS** only if sections A–E are checked with evidence and no Must FR (except FR-11) is open.

Next: **Topic 14 — Teardown** immediately.
