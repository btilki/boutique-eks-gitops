# ADR-0009: Metric-driven frontend canary (AnalysisTemplates)

- **Status:** Accepted (scaffold)  
- **Date:** 2026-07-25  
- **Setup:** Topic 18  
- **Related:** Topic 12 (timed canary), ADR-0001  

## Context

Topic 12 proved ALB weight steps with timed `pause` only. That does not automatically abort on bad canary pods or failed HTTP checks. Argo Rollouts **AnalysisTemplates** provide job- and Prometheus-based gates.

## Decision

1. Ship **ClusterAnalysisTemplates** in Git (`frontend-http-smoke`, `frontend-pod-ready`) synced at wave 26.
2. Keep stage/prod canary on **timed pauses by default** (`canary.analysis.enabled: false`).
3. Frontend chart supports optional **background analysis** + alternate **analysis.steps** when enabled.
4. Provide **example env overlays** (`frontend-analysis.example.yaml`) for stage/prod — operators copy into live values after rebuild proof.

## Consequences

- **Positive:** Path to auto-abort on smoke/Prometheus failure; still digest-only GitOps.
- **Negative:** Smoke Jobs need cluster DNS to canary Service; Prometheus template needs Topic 08 stack; false failures if metrics lag.
- **Follow-ups:** Add HTTP success-rate once Boutique exports RED metrics / blackbox; AnalysisRun notifications via Topic 17.
