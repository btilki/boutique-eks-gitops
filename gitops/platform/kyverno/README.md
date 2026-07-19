# Kyverno — admission policies for digest-only Boutique workloads

**Setup:** Topic 07 · **Pin:** Kyverno **1.16.x** · Helm chart **3.3.7**

## Layout

| Path | Purpose |
|------|---------|
| `values.yaml` | Helm values for operator |
| `policies/` | ClusterPolicies (wave 21) |

## Policies

| Policy | Effect |
|--------|--------|
| `deny-latest-tag` | Blocks `:latest` in app namespaces |
| `require-image-digest` | Requires `@sha256:` digests |
| `ecr-registry-allowlist` | ECR `eu-central-1` only |

## Sync

- Operator: ApplicationSet `platform-apps` (Helm)
- Policies: ApplicationSet `platform-manifests` → `gitops/platform/kyverno/policies`
