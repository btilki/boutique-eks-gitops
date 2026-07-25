# 18 — Canary AnalysisTemplates (metric / smoke gates)

Audience: L2 — Implementer  
Estimated time: 1–1.5 hours (scaffold now; enable after Topic 12 on rebuild)  
Prerequisites: [12 — Canary rollouts](12-canary-rollouts.md) + [08 — Observability](08-observability.md) for Prometheus background analysis  
Creates: ClusterAnalysisTemplates under `gitops/platform/argo-rollouts/analysis/`; chart `canary.analysis` support; stage/prod example overlays; [ADR-0009](../adr/0009-canary-analysis-templates.md)  
Related: [canary runbook](../runbooks/canary.md) · Topic [12](12-canary-rollouts.md)  
Pins: Argo Rollouts **v1.8.2** / chart **2.39.5** ([docs/versions.md](../versions.md))

---

## Topic goal

Add **AnalysisTemplates** so frontend canaries can **auto-abort** on failed HTTP smoke checks and/or Prometheus Ready-pod signals — while keeping timed pauses as the default until you opt in.

## Why this topic is required

Timed `pause` alone never fails a bad digest. Analysis closes the progressive-delivery loop for fuller GitOps delivery.

## Before you begin

**Scaffold-only:**

- Confirm Creates files; stage/prod keep `canary.analysis.enabled: false`.

**Apply after rebuild (after Topics 08 + 12):**

- Rollouts controller healthy; frontend Rollout on stage/prod.
- Prometheus Service reachable at `kube-prometheus-stack-prometheus.monitoring.svc:9090` (for pod-ready template).

**Idempotent:** Syncing ClusterAnalysisTemplates is safe. Enabling analysis changes Rollout steps — test on **stage** first.

---

## Step 18.1: Confirm scaffold files

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"

test -f docs/setup/18-canary-analysis.md
test -f docs/adr/0009-canary-analysis-templates.md
test -f gitops/platform/argo-rollouts/analysis/frontend-http-smoke.yaml
test -f gitops/platform/argo-rollouts/analysis/frontend-pod-ready.yaml
test -f gitops/envs/stage/values/frontend-analysis.example.yaml
test -f gitops/envs/prod/values/frontend-analysis.example.yaml
grep -q 'canary.analysis' charts/frontend/templates/rollout.yaml
grep -q 'argo-rollouts-analysis' gitops/apps/platform-apps/applicationset-manifests.yaml
grep -q 'analysis:' gitops/envs/stage/values/frontend.yaml
```

### Expected output

All checks exit 0. Live stage/prod have `analysis.enabled: false`.

---

## Step 18.2: Understand templates

| Template | Provider | Failure means |
|----------|----------|---------------|
| `frontend-http-smoke` | Job + curl | Canary Service URL not HTTP OK |
| `frontend-pod-ready` | Prometheus | No Ready pods matching prefix |

### Commands

```bash
grep -A5 'kind: ClusterAnalysisTemplate' gitops/platform/argo-rollouts/analysis/*.yaml
```

---

## Step 18.3: Apply after rebuild — sync AnalysisTemplates

> **Apply after cluster rebuild (after Topic 12).**

### Commands

```bash
argocd app sync argo-rollouts-analysis --grpc-web || \
  kubectl get clusteranalysistemplate

kubectl get clusteranalysistemplate frontend-http-smoke frontend-pod-ready
```

### Expected output

Both ClusterAnalysisTemplates present.

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| App missing | AppSet not refreshed | Sync root / platform-manifests generator |
| Chart exclude | Path has only yaml | Confirm `analysis/*.yaml` on main |

---

## Step 18.4: Enable analysis on stage (then prod)

> **Apply after Step 18.3.** Prefer stage before prod.

### Goal

Opt into smoke + background analysis via example overlay.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"

# Review example — namespace in URL must match env
less gitops/envs/stage/values/frontend-analysis.example.yaml

# Merge canary.analysis block into gitops/envs/stage/values/frontend.yaml
# (copy analysis.enabled/background/steps; keep image/ingress from live file)

# After commit + Argo auto-sync on stage:
kubectl -n stage get rollout frontend -o yaml | grep -A30 'strategy:'
kubectl argo rollouts get rollout frontend -n stage   # optional plugin
```

Prod: same using `frontend-analysis.example.yaml` + **manual** Argo sync.

### Validation

Trigger a digest change on stage; confirm AnalysisRuns appear and bad smoke aborts canary:

```bash
kubectl -n stage get analysisrun
kubectl argo rollouts abort frontend -n stage   # only if needed
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Smoke Job DNS fail | Wrong URL / Service name | Use `http://frontend-canary.<ns>.svc:8080/` |
| Prometheus query empty | Metrics delay / wrong address | Check Prom UI; NetworkPolicy egress from analysis Job namespace |
| Background analysis fails always | No Ready pods yet at start | Raise count/interval; ensure Rollout pods Ready |

### Security notes

Smoke Job uses public curl image digest-by-tag for simplicity; pin by digest in locked-down environments if required.

---

## Step 18.5: Topic validation (scaffold)

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"

test -f docs/setup/18-canary-analysis.md
test -f docs/adr/0009-canary-analysis-templates.md
grep -q 'enabled: false' gitops/envs/stage/values/frontend.yaml
grep -q 'enabled: false' gitops/envs/prod/values/frontend.yaml
make docs-check
```

### Validation checklist

| Check | Scaffold | After rebuild |
|-------|----------|---------------|
| ClusterAnalysisTemplates in Git | Required | Synced |
| Chart supports analysis | Required | — |
| Live envs analysis **off** | Required | Enable via example |
| ADR-0009 | Required | — |

---

## Topic troubleshooting

| Symptom | Cause | Recovery |
|---------|-------|----------|
| Canary stuck in Analysis | Smoke failing | Fix app/URL; abort; revert digest |
| Timed canary still used | analysis.enabled false | Expected until Step 18.4 |

## Related

- Templates: [`gitops/platform/argo-rollouts/analysis/`](../../gitops/platform/argo-rollouts/analysis/)
- Runbook: [`docs/runbooks/canary.md`](../runbooks/canary.md)
- Prior: [12](12-canary-rollouts.md)
