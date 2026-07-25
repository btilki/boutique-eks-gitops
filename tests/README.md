# Tests — boutique-eks-gitops

Validation helpers and fixtures. **Not** a substitute for Setup Guide validation or `docs/PRODUCTION_CHECKLIST.md`.

| Path | Purpose | Status |
|------|---------|--------|
| `tests/policy/` | Kyverno fixtures + `unit/` CLI tests (Topic 16) | Partial — live policies in `gitops/platform/kyverno/` |
| `tests/helm/` | Reserved for chart fixtures | Empty — use CI `helm_lint` / `helm lint charts/*` |
| `tests/smoke/` | Reserved for scripted smokes | Empty — use Setup Guide Validation + checklist |

## Local / CI entry points

```bash
make lint          # terraform fmt -check + docs/versions.md presence
make docs-check    # required setup/runbook/CI files exist

# Helm (matches GitLab test stage)
helm lint charts/frontend charts/cartservice charts/redis charts/checkoutservice \
  charts/productcatalogservice charts/currencyservice charts/paymentservice charts/shippingservice

# Topic 16 — offline policy unit tests (requires kyverno CLI)
kyverno test tests/policy/unit
```

GitLab CI also runs Gitleaks, Checkov (soft-fail), Kyverno `policy_test`, Trivy CRITICAL, cosign keyless sign, CycloneDX SBOM attest, and digest-MR path guards (see [`docs/ci.md`](../docs/ci.md)).

Do not add install-all or cluster-apply scripts here — Setup Guide remains authoritative.
