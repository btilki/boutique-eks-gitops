# Argo Rollouts — progressive delivery controller

**Setup:** Topic 12 · Topic 18 · **Pin:** controller **v1.8.2** · Helm chart **2.39.5**  
**Authority:** [`docs/versions.md`](../../../docs/versions.md) · Guide: [`docs/setup/12-canary-rollouts.md`](../../../docs/setup/12-canary-rollouts.md) · [`docs/setup/18-canary-analysis.md`](../../../docs/setup/18-canary-analysis.md)

## Layout

| Path | Purpose |
|------|---------|
| `values.yaml` | Helm values for the Rollouts controller |
| `analysis/` | ClusterAnalysisTemplates (Topic 18) |

## Sync

- ApplicationSet `platform-apps` → chart `argo-rollouts` (wave **25**)
- ApplicationSet `platform-manifests` → `argo-rollouts-analysis` (wave **26**)
- Namespace: `argo-rollouts` (created by sync)

## Workload usage

Boutique **frontend** on **stage** and **prod** uses a `Rollout` with ALB traffic splitting (`charts/frontend`). **dev** keeps a plain `Deployment` (`canary.enabled: false`).

Analysis is **off** by default (`canary.analysis.enabled: false`). Enable via `gitops/envs/*/values/frontend-analysis.example.yaml` after templates sync (Topic 18).

## Optional CLI

```bash
kubectl argo rollouts version   # plugin optional but useful for status/abort
```
