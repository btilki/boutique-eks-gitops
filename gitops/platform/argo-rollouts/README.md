# Argo Rollouts — progressive delivery controller

**Setup:** Topic 12 · **Pin:** controller **v1.8.2** · Helm chart **2.39.5**  
**Authority:** [`docs/versions.md`](../../../docs/versions.md) · Guide: [`docs/setup/12-canary-rollouts.md`](../../../docs/setup/12-canary-rollouts.md)

## Layout

| Path | Purpose |
|------|---------|
| `values.yaml` | Helm values for the Rollouts controller |

## Sync

- ApplicationSet `platform-apps` → chart `argo-rollouts` (wave **25**)
- Namespace: `argo-rollouts` (created by sync)

## Workload usage

Boutique **frontend** on **stage** and **prod** uses a `Rollout` with ALB traffic splitting (`charts/frontend`). **dev** keeps a plain `Deployment` (`canary.enabled: false`).

## Optional CLI

```bash
kubectl argo rollouts version   # plugin optional but useful for status/abort
```
