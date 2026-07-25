# Argo CD bootstrap

**Setup:** Topic 06 · **Pin:** Argo CD **v2.14.x** · Helm chart **7.8.14**

## Install (Helm — first time)

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Substitute ACM ARN in values.yaml first (Step 6.1)
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --version 7.8.14 \
  --values gitops/bootstrap/argocd/values.yaml \
  --wait
```

## UI

- URL: https://argocd.boutique.biroltilki.art  
- User: `admin`  
- Password: from `argocd-initial-admin-secret` (rotate after first login)

## Git credential

Register the GitLab repo in Argo (UI or CLI) — **never** commit the token (Step 6.3).

## Next

Apply root app: `gitops/bootstrap/root/application.yaml`

## Hardening (Topic 17)

AppProjects live under [`hardening/projects/`](hardening/projects/). SSO and notifications remain **example-only** until after rebuild — see [`hardening/README.md`](hardening/README.md) and [`docs/setup/17-argocd-hardening.md`](../../../docs/setup/17-argocd-hardening.md).
