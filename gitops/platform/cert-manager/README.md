# cert-manager

**Setup:** Topic 05 · **Pin:** **v1.16.x** · Helm chart **v1.16.2**

## Purpose

Installed for platform readiness. **Public HTTPS uses ACM on ALB** ([ADR-0003](../../../docs/adr/0003-tls-acm-alb.md)) — not cert-manager DNS-01 for boutique hosts in v1.

## Bootstrap install (Topic 05)

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v1.16.2 \
  --values gitops/platform/cert-manager/values.yaml \
  --wait
```

## GitOps

Owned by ApplicationSet `platform-apps` after Topic 06 (`gitops/apps/platform-apps/applicationset.yaml`).
