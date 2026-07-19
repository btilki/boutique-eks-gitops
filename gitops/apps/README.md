# GitOps apps — ApplicationSets and sync rules

**Setup:** Topic 06 · **ADR:** [0001 digest-only GitOps](../docs/adr/0001-digest-only-gitops.md)

## Layout

| Path | Role |
|------|------|
| `platform-apps/` | ApplicationSet for shared platform components |
| `workload-apps/` | ApplicationSet for `dev` / `stage` / `prod` namespaces |

Root Application (`gitops/bootstrap/root/application.yaml`) syncs **this directory**.

## Sync waves

| Wave | Content | When |
|------|---------|------|
| 10 | Ingress stack (LB controller, external-dns, cert-manager) | Topic 05/06 |
| 20 | Kyverno + External Secrets operators | Topic 07 |
| 21 | Policies, ClusterSecretStores, NetworkPolicies | Topic 07 |
| 30 | Observability (kube-prometheus-stack, Loki) | Topic 08 |
| 31 | Monitoring manifests (SMTP ExternalSecret, PrometheusRules) | Topic 08 |
| 40 | Workloads (Boutique) | Topic 09+ |
| 50 | Argo Rollouts | Topic 12 |

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
