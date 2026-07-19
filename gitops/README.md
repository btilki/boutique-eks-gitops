# GitOps — boutique-eks-gitops

Argo CD desired state. **Git is the only deploy authority** ([ADR-0001](../docs/adr/0001-digest-only-gitops.md)).

**Setup authority:** Topics 05–09, 12  
**Pins:** [docs/versions.md](../docs/versions.md)

## Layout

```text
gitops/
├── bootstrap/     # Argo CD install + root app (Topic 06)
├── apps/          # app-of-apps / ApplicationSets (Topic 06)
├── platform/      # ingress, security, monitoring, rollouts (Topics 05, 07, 08, 12)
└── envs/
    ├── dev/       # digest pins + values (Topic 09+)
    ├── stage/
    └── prod/      # CODEOWNERS @btilki; manual Argo sync
```

## Sync policy (locked)

| Env | Automated sync | Notes |
|-----|----------------|-------|
| `dev` | Yes | Digest MRs land here first |
| `stage` | Yes (controlled) | Promotion + canary |
| `prod` | **No** — manual sync only | CODEOWNERS on path |

## Rules

- Patch **digests** in env overlays — not tags.
- No raw secrets in this tree — use External Secrets references.
- Platform components use sync waves before workloads.

## Platform notes

- Security baseline (Topic 07): `gitops/platform/kyverno|external-secrets|network-policies` + `platform-manifests` AppSet
- Observability (Topic 08): `gitops/platform/monitoring/` + wave 30/31
- Canary (Topic 12): `gitops/platform/argo-rollouts/` + wave 25; frontend stage/prod Rollouts

## Bootstrap (Topic 06)

| Path | Component |
|------|-----------|
| `gitops/bootstrap/argocd/` | Helm values for Argo CD |
| `gitops/bootstrap/root/` | Root app-of-apps |
| `gitops/apps/platform-apps/` | Platform ApplicationSet |
| `gitops/apps/workload-apps/` | Workload ApplicationSet (prod manual) |

See [`gitops/apps/README.md`](apps/README.md).

## Platform (Topic 05+)

| Path | Component |
|------|-----------|
| `gitops/platform/aws-load-balancer-controller/` | ALB Ingress controller |
| `gitops/platform/external-dns/` | Route53 records |
| `gitops/platform/cert-manager/` | Installed; ACM remains public TLS |
| `gitops/platform/argo-rollouts/` | Progressive delivery controller (Topic 12) |

DNS/TLS reference: [`docs/dns-and-tls.md`](../docs/dns-and-tls.md)
