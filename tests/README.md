# Tests — boutique-eks-gitops

Validation helpers and fixtures. **Not** a substitute for Setup Guide validation or `docs/PRODUCTION_CHECKLIST.md`.

| Path | Purpose | Status |
|------|---------|--------|
| `tests/policy/` | Sample Kyverno deny fixtures (e.g. `:latest`) | Partial — live policies in `gitops/platform/kyverno/` |
| `tests/helm/` | Reserved for chart fixtures | Empty — use CI `helm_lint` / `helm lint charts/*` |
| `tests/smoke/` | Reserved for scripted smokes | Empty — use Setup Guide Validation + checklist |

## Local / CI entry points

```bash
make lint          # terraform fmt -check + docs/versions.md presence
make docs-check    # required setup/runbook/CI files exist

# Helm (matches GitLab test stage)
helm lint charts/frontend charts/cartservice charts/redis charts/checkoutservice \
  charts/productcatalogservice charts/currencyservice charts/paymentservice charts/shippingservice
```

GitLab CI also runs Trivy CRITICAL, cosign keyless sign, and digest-MR path guards (see [`docs/ci.md`](../docs/ci.md)).

Do not add install-all or cluster-apply scripts here — Setup Guide remains authoritative.
