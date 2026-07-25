# Kyverno — admission policies for digest-only Boutique workloads

**Setup:** Topic 07 · **Pin:** Kyverno **1.16.x** · Helm chart **3.3.7**

## Layout

| Path | Purpose |
|------|---------|
| `values.yaml` | Helm values for operator |
| `policies/` | ClusterPolicies (wave 21) |

## Policies

| Policy | Effect | Mode |
|--------|--------|------|
| `deny-latest-tag` | Blocks `:latest` in app namespaces | Enforce |
| `require-image-digest` | Requires `@sha256:` digests | Enforce |
| `ecr-registry-allowlist` | ECR `eu-central-1` only | Enforce |
| `verify-image-signatures` | Sigstore keyless cosign verify (Topic 15) | **Audit** → Enforce after rebuild proof |
| `verify-sbom-attestation` | CycloneDX attestation verify (Topic 15) | **Audit** (Enforce optional later) |

## Sync

- Operator: ApplicationSet `platform-apps` (Helm)
- Policies: ApplicationSet `platform-manifests` → `gitops/platform/kyverno/policies`
