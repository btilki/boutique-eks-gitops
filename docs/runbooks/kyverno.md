# Runbook — Kyverno policy block

**Audience:** L2 — Operator  
**Setup:** Topic 07 · Policies: [`../../gitops/platform/kyverno/policies/`](../../gitops/platform/kyverno/policies/)

## Purpose

Unblock legitimate workloads blocked by admission policy — without weakening digest-only rules for the pilot.

## Active policies (app namespaces)

| Policy | Effect |
|--------|--------|
| `deny-latest-tag` | Blocks `:latest` |
| `require-image-digest` | Requires `@sha256:…` |
| `ecr-registry-allowlist` | ECR `eu-central-1` only |
| `verify-image-signatures` | Cosign keyless (Topic 15; default **Audit**) |
| `verify-sbom-attestation` | CycloneDX attest (Topic 15; default **Audit**) |

## Quick triage

```bash
kubectl -n kyverno get pods
kubectl get clusterpolicy
kubectl get events -A --field-selector reason=PolicyViolation --sort-by='.lastTimestamp' | tail -30

# If a create/update was denied, inspect the warning/error from kubectl/Argo
kubectl -n <ns> get events --sort-by='.lastTimestamp' | tail -40
```

## Checks (in order)

| # | Check | Action |
|---|--------|--------|
| 1 | Image reference | Must be `ACCOUNT.dkr.ecr.eu-central-1.amazonaws.com/...@sha256:…` |
| 2 | Git values | `image.repository` + `image.digest` — never `tag: latest` |
| 3 | Chart render | `helm template … \| grep image:` |
| 4 | Policy mode | Enforce vs Audit — do not flip to Audit to ship `:latest` |
| 5 | Namespace scope | Confirm policy `Namespace` match includes env |

## Common fixes

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Denied `:latest` | Tag slipped into manifest | Pin digest in `gitops/envs/**` |
| Denied missing digest | Only `image: repo:tag` | Use `@sha256:` contract |
| Denied registry | Public GHCR/Docker Hub | Mirror/push to project ECR |
| Signature / SBOM Audit fails | Unsigned bootstrap or subject mismatch | Run Topic 10+15 CI; fix `subjectRegExp` (Topic 15.2); Enforce only after proof |
| Rollout pods denied | Same as Deployment | Fix Rollout pod template image |
| Policy not loaded | AppSet path | Sync `kyverno-policies` app |

## What not to do

| Anti-pattern | Why |
|--------------|-----|
| Delete ClusterPolicy to unblock | Removes supply-chain gate |
| Add blanket ClusterPolicy exceptions for `*` | Defeats FR-04 |
| `kubectl run` with public `:latest` for debug in app ns | Use disposable ns or digest image |

## Recovery

Fix the image in Git → merge → Argo sync (manual for prod). Re-test with [`tests/policy/deny-latest-pod.yaml`](../../tests/policy/deny-latest-pod.yaml) expecting deny.

## Related

- Setup: [`../setup/07-security-baseline.md`](../setup/07-security-baseline.md) · [`../setup/15-supply-chain-verify-sbom.md`](../setup/15-supply-chain-verify-sbom.md)
- CI: [`../ci.md`](../ci.md)
