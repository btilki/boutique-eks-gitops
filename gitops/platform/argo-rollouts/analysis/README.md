# Argo Rollouts AnalysisTemplates — Setup Topic 18 · ADR-0009

Synced by ApplicationSet `platform-manifests` → `argo-rollouts-analysis` (wave 26).

| Template | Provider | Use |
|----------|----------|-----|
| `frontend-http-smoke` | Job (curl) | Step analysis against canary Service URL |
| `frontend-pod-ready` | Prometheus | Background analysis (Ready pods) |

Enable from env values — see Topic 18 and `gitops/envs/*/values/frontend-analysis.example.yaml`.
