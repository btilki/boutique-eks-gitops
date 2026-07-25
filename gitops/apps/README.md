# GitOps apps — ApplicationSets and sync rules

**Setup:** Topic 06 · Topic 17 · **ADR:** [0001](../../docs/adr/0001-digest-only-gitops.md) · [0008](../../docs/adr/0008-argocd-appprojects-sso.md)

## Layout

| Path | Role |
|------|------|
| `platform-apps/` | ApplicationSet for shared platform components |
| `workload-apps/` | ApplicationSet for `dev` / `stage` / `prod` namespaces |

Root Application (`gitops/bootstrap/root/application.yaml`) syncs **this directory**.

## AppProjects (Topic 17)

| Project | Used by |
|---------|---------|
| `default` | Root app, ApplicationSets bootstrap, `argocd-hardening` |
| `boutique-platform` | Platform Helm apps + most platform manifests |
| `boutique-workloads` | Boutique Helm apps + env namespace apps |

Sync **`argocd-hardening`** (AppProjects) before other named-project apps on rebuild.

## Sync waves

| Wave | Content | When |
|------|---------|------|
| 5 | Argo AppProjects (`argocd-hardening`) | Topic 17 |
| 10 | Ingress stack (LB controller, external-dns, cert-manager) | Topic 05/06 |
| 20 | Kyverno + External Secrets operators | Topic 07 |
| 21 | Policies, ClusterSecretStores, NetworkPolicies | Topic 07 |
| 25 | Argo Rollouts | Topic 12 |
| 26 | Rollouts AnalysisTemplates | Topic 18 |
| 30 | Observability (kube-prometheus-stack, Loki) | Topic 08 |
| 31 | Monitoring manifests (SMTP ExternalSecret, PrometheusRules) | Topic 08 |
| 35 | Env namespaces | Topic 06/09 |
| 40 | Workloads (Boutique) | Topic 09+ |

ApplicationSets:

- `platform-apps` — Helm operators  
- `platform-manifests` — directory manifests (policies/NP/secret stores)

## Sync policy (locked)

| Env | Automated sync | Notes |
|-----|----------------|-------|
| platform | Yes | Self-heal + prune |
| `dev` | Yes | Digest MRs land here first |
| `stage` | Yes | Promotion + canary later |
| `prod` | **No** — manual sync only | CODEOWNERS `@btilki`; never enable auto-sync |

## REPLACE tokens

Before apply, set `<GITLAB_REPO_URL>` in:

- `gitops/bootstrap/root/application.yaml`
- `gitops/apps/platform-apps/applicationset.yaml`
- `gitops/apps/workload-apps/applicationset.yaml`

Match the credential registered in Argo (Step 6.3).

## Boutique workloads (Topic 09)

| AppSet | Purpose |
|--------|---------|
| `workload-namespaces` | Sync `namespace.yaml` only |
| `boutique-workloads` | Helm apps per service × env (`boutique-applicationset.yaml`) |

Prod service apps: **manual sync** (`autoSync: false`).
