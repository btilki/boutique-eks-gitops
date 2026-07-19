# Charts — Online Boutique (scoped)

Helm charts for the in-scope storefront path. Image contract: **`image.repository` + `image.digest`** (never `:latest`) — [ADR-0001](../docs/adr/0001-digest-only-gitops.md).

**Setup authority:** Topic [09](../docs/setup/09-boutique-charts.md)

## Services (7) + Redis

| Chart | Port | Notes |
|-------|------|-------|
| `frontend` | 8080 | Ingress enabled via env values |
| `productcatalogservice` | 3550 | |
| `cartservice` | 7070 | `REDIS_ADDR=redis:6379` |
| `checkoutservice` | 5050 | |
| `currencyservice` | 7000 | |
| `paymentservice` | 50051 | |
| `shippingservice` | 50051 | |
| `redis` | 6379 | Mirror official Redis into project ECR (Kyverno allowlist) |

## Env overlays

`gitops/envs/{dev,stage,prod}/values/<service>.yaml` — digests + frontend Ingress host/ACM.  
Frontend **stage/prod**: Argo Rollouts canary (`canary.enabled: true`); **dev**: Deployment.

## Argo

ApplicationSet: `gitops/apps/workload-apps/boutique-applicationset.yaml`  
Prod apps: **manual sync only**.
