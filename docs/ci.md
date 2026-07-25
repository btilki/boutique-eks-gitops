# CI/CD contract — boutique-eks-gitops

**Audience:** L2 — Implementer / Reviewer  
**Setup:** Topic 10 · Topic 15 · Topic 16 · **ADR:** [0001](adr/0001-digest-only-gitops.md) · [0006](adr/0006-cosign-signing-mode.md) · [0007](adr/0007-admission-verify-and-sbom.md)  
**Pipeline:** [`.gitlab-ci.yml`](../.gitlab-ci.yml)

## Post-teardown status (current)

**Pipelines are dormant.** After M4 / AWS destroy, CI must not auto-run: build/scan/sign need ECR + OIDC roles that no longer exist (that is why docs commits on `main` showed **Failed**).

To run CI again after a rebuild:

1. Restore Topic 03–04 AWS (ECR + GitLab OIDC role)
2. Set GitLab CI/CD variable `ENABLE_PILOT_CI=true`
3. Confirm `AWS_ROLE_ARN` is set

**Repo gates without AWS (Topic 16):** set `ENABLE_REPO_GATES=true` to create **MR** pipelines for `helm_lint` / `gitleaks` / `checkov` / `policy_test` only (no build/sign).

Without `ENABLE_PILOT_CI=true` and without `ENABLE_REPO_GATES=true`, workflow rules use `when: never` — no pipeline is created (no red Failed badge).

## Hard rules

| Rule | Rationale |
|------|-----------|
| CI **never** runs `kubectl apply`, `helm upgrade` to the cluster, or `argocd sync` | Git is the only deploy authority |
| CI **never** stores static AWS access keys | OIDC → IAM role (ECR only) |
| Successful build opens an MR that changes **only** `image.digest` under `gitops/envs/dev/values/` | Digest-only promotion path |
| Trivy **CRITICAL** findings fail the pipeline | Supply-chain gate (pin **0.71.0**) |
| Images are signed with cosign **Sigstore keyless** | ADR-0006 |
| Images get a **CycloneDX SBOM** + `cosign attest` | ADR-0007 / Topic 15 |
| Kyverno **Audit**s signatures (+ optional SBOM attest); **Enforce** after rebuild proof | ADR-0007 |
| MR/test stage runs **Gitleaks**, **Checkov** (soft-fail), **Kyverno CLI** policy tests | Topic 16 |
| Re-sign of an already-signed digest is OK | ECR tags are **immutable**; CI treats existing signatures as success |

Node services (`currencyservice`, `paymentservice`) apply `ci/docker/patch-protobufjs.Dockerfile` to bump `protobufjs` to **7.5.5** (CVE-2026-41242) before scan.

## Stages

```text
test → build → scan → sign → sbom → gitops
```

| Stage | What | Fail means |
|-------|------|------------|
| test | Helm lint; Gitleaks; Checkov (**soft-fail** until baselined); Kyverno `policy_test` | Broken charts / secrets / policy unit tests (Checkov findings do not fail while soft_fail) |
| build | Publish Boutique **v0.10.6** to ECR (OIDC): default retag `:bootstrap`; optional `BOUTIQUE_BUILD_MODE=git` | No artifact |
| scan | Trivy image scan | CRITICAL CVE |
| sign | cosign keyless | Unsigned image |
| sbom | Trivy CycloneDX + cosign attest | Missing/failed attestation |
| gitops | Branch + MR updating digest in **dev** only | No GitOps change |

## Variables (CI/CD settings — not in Git)

| Variable | Purpose |
|----------|---------|
| `ENABLE_PILOT_CI` | Must be `true` to run full pilot pipeline including build/sign (off by default after teardown) |
| `ENABLE_REPO_GATES` | Optional: `true` to run **MR** test-stage gates without AWS (Topic 16) |
| `AWS_ROLE_ARN` | GitLab OIDC IAM role from Terraform `gitlab_ci_role_arn` |
| `AWS_DEFAULT_REGION` | `eu-central-1` |
| (optional) `BOUTIQUE_BUILD_MODE` | `ecr-bootstrap` (default) or `git` |
| (optional) `BOUTIQUE_GIT_REF` | Git tag when mode=`git` (default `v0.10.6`) |

Protected/masked as appropriate. **No** `AWS_SECRET_ACCESS_KEY`.

## OIDC

- GitLab `id_tokens` for AWS (`GITLAB_OIDC_TOKEN`) and Sigstore (`SIGSTORE_ID_TOKEN`).
- IAM trust conditions must match project path (Topic 04 module + Topic 10 Step 10.1).

## Digest MR shape

```diff
# gitops/envs/dev/values/frontend.yaml
-  digest: "sha256:old…"
+  digest: "sha256:new…"
```

No other files in the CI MR. Promotion to stage/prod is **human** (Topic 11).

## Forbidden in `.gitlab-ci.yml`

- `kubectl`, `argocd`, cluster kubeconfig usage for deploys
- Writing digests directly to `main` without MR (unless explicitly approved later)
- Patching `gitops/envs/prod/**` from CI

## Verify signature (optional operator check)

```bash
cosign verify \
  --certificate-identity-regexp "https://gitlab.com/.+" \
  --certificate-oidc-issuer "https://gitlab.com" \
  "${REGISTRY}/boutique-eks-gitops/frontend@${DIGEST}"
```

Adjust identity regexp to your GitLab project path when tightening.

## Verify SBOM attestation (Topic 15)

```bash
cosign verify-attestation --type cyclonedx \
  --certificate-identity-regexp "https://gitlab.com/.+" \
  --certificate-oidc-issuer "https://gitlab.com" \
  "${REGISTRY}/boutique-eks-gitops/frontend@${DIGEST}"
```

CI also uploads `sbom-<service>.cdx.json` as a job artifact (7-day retention). Admission policies: [`gitops/platform/kyverno/policies/verify-*.yaml`](../gitops/platform/kyverno/policies/) (default **Audit** until Topic 15 Step 15.4).
