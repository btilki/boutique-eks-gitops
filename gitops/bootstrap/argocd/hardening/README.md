# Argo CD hardening scaffolds — Setup Topic 17 · ADR-0008

**Pin:** Argo CD **v2.14.x** · chart **7.8.14**

## Layout

| Path | Purpose | Live sync? |
|------|---------|------------|
| `projects/*.yaml` | AppProjects `boutique-platform` + `boutique-workloads` | Yes (wave 5) |
| `sso/values-dex-gitlab.yaml.example` | Dex + GitLab OIDC values | No — merge after IdP ready |
| `notifications/*.example.yaml` | Notifications Helm + CM | No — enable after secrets |
| `rbac/argocd-rbac-cm.example.yaml` | RBAC shape | No — prefer Helm `configs.rbac` |

## Apply order (after rebuild)

1. Topic 06 Argo install (`dex` / `notifications` still **false** in `values.yaml`)
2. Sync AppProjects (this directory via `argocd-hardening` app)
3. ApplicationSets already reference named projects (Topic 17)
4. Optionally enable Dex / notifications per examples

## Related

- Setup: `docs/setup/17-argocd-hardening.md`
- ADR: `docs/adr/0008-argocd-appprojects-sso.md`
