# 05 — Deployment flow

## Branching and promotion

| Path | Trigger | Result |
|------|---------|--------|
| Feature / service change | MR → `main` | May rebuild images |
| CI on successful build | Auto | Digest MR → `gitops/envs/dev/**` only |
| Promote to stage | Human MR copying digests `dev` → `stage` | Argo auto/controlled sync |
| Promote to prod | Human MR `stage` → `prod` + **`@btilki` CODEOWNERS** | Argo **manual** sync |
| Rollback | `git revert` of digest MR | Argo reconciles previous digests |

**Contract:** Promotion MRs change **only** `image.digest` (and explicitly allowed env scalars if documented). No CI `kubectl` / `argocd sync`.

## CI stages (GitLab)

```text
test → build → scan (Trivy 0.71.0) → sign (cosign 2.4.x) → sbom (CycloneDX + attest, Topic 15) → gitops (digest MR)
```

Pinned in `docs/versions.md`. Failure at CRITICAL CVE or sign error blocks the digest MR. Signing is **Sigstore keyless** (GitLab OIDC → Fulcio). Phase 7 performs a **one-time ECR digest bootstrap** so Argo can sync before the first full CI run.

Default `BOUTIQUE_BUILD_MODE` is `ecr-bootstrap`: CI retags that bootstrap image and publishes its digest. `BOUTIQUE_BUILD_MODE=git` builds from the Boutique Git tag. Kyverno signature verify stays **Audit** until that Enforce switch is proven ([ADR-0007](../adr/0007-admission-verify-and-sbom.md)).

## GitOps sync model

| Layer | Mechanism | Sync |
|-------|-----------|------|
| Root | App-of-apps | Automated |
| Platform | Applications / ApplicationSet | Automated + **sync waves** |
| Workloads | ApplicationSet per env | dev/stage automated; **prod manual** |

**Sync waves (conceptual):**

| Wave | Content |
|------|---------|
| 0 | CRDs / Kyverno / ESO operators |
| 1 | Policies, ClusterSecretStores, NetworkPolicies |
| 2 | Ingress stack, monitoring |
| 3 | Boutique workloads |

## Canary (frontend)

- **Stage and prod** use Argo Rollouts + ALB traffic splitting.
- Steps are timed weights (10, 30, 50, 100). `canary.analysis.enabled` is `false` in the env values. The AnalysisTemplate is in Git and does not gate the rollout.
- Abort = Git revert of bad digest (Rollout cancels/returns to stable).
- Prod canary still requires manual Application sync to start reconciliation.

## Rollback matrix

| Layer | Mechanism |
|-------|-----------|
| Application | Git revert digest MR |
| Canary | Rollout abort / revert digest |
| Platform chart | Git revert platform values |
| Infrastructure | Terraform plan/apply prior state; avoid blind destroy in prod keep scenarios |
| Full pilot end | Phase 11 teardown |

## Deployment flowchart

```mermaid
flowchart TD
  A[git push] --> B[GitLab CI test/build]
  B --> C{Trivy CRITICAL pass?}
  C -->|no| X[Fail pipeline]
  C -->|yes| D[cosign sign + ECR push]
  D --> E[Open digest MR to envs/dev]
  E --> F[Human merge]
  F --> G[Argo syncs dev]
  G --> H[Promote MR to stage]
  H --> I[Argo syncs stage + canary]
  I --> J[Promote MR to prod + CODEOWNERS]
  J --> K[Owner approves]
  K --> L[Manual Argo sync prod]
  L --> M[Prod canary → stable]
  M --> N{Bad release?}
  N -->|yes| O[git revert]
  O --> G
  N -->|no| P[Done]
```

**Alt text:** The default-branch pipeline publishes a digest (retag `:bootstrap` unless `BOUTIQUE_BUILD_MODE=git`), gates it with Trivy and cosign, and opens a digest MR for dev. Humans promote through stage and prod with CODEOWNERS and a manual prod sync. A revert rolls back through Git.

## Human gates

1. Merge digest MR to `main` (dev).
2. Merge promotion MR to stage.
3. CODEOWNERS approval for prod path.
4. Manual Argo sync for prod Application.
5. Optional: observe canary before full weight.
