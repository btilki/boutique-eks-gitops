# CI/CD contract — boutique-eks-gitops

**Audience:** L2 — Implementer / Reviewer  
**Setup:** Topic 10 · **ADR:** [0001](adr/0001-digest-only-gitops.md) · [0006](adr/0006-cosign-signing-mode.md)  
**Pipeline:** [`.gitlab-ci.yml`](../.gitlab-ci.yml)

## Hard rules

| Rule | Rationale |
|------|-----------|
| CI **never** runs `kubectl apply`, `helm upgrade` to the cluster, or `argocd sync` | Git is the only deploy authority |
| CI **never** stores static AWS access keys | OIDC → IAM role (ECR only) |
| Successful build opens an MR that changes **only** `image.digest` under `gitops/envs/dev/values/` | Digest-only promotion path |
| Trivy **CRITICAL** findings fail the pipeline | Supply-chain gate (pin **0.71.0**) |
| Images are signed with cosign **Sigstore keyless** | ADR-0006 |

## Stages

```text
test → build → scan → sign → gitops
```

| Stage | What | Fail means |
|-------|------|------------|
| test | Helm lint / chart sanity | Broken charts |
| build | Publish Boutique **v0.10.6** to ECR (OIDC): default retag `:bootstrap`; optional `BOUTIQUE_BUILD_MODE=git` | No artifact |
| scan | Trivy image scan | CRITICAL CVE |
| sign | cosign keyless | Unsigned image |
| gitops | Branch + MR updating digest in **dev** only | No GitOps change |

## Variables (CI/CD settings — not in Git)

| Variable | Purpose |
|----------|---------|
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
