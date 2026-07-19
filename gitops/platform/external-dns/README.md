# external-dns

**Setup:** Topic 05 · **Pin:** **v0.15.x** · Helm chart **1.15.0** (kubernetes-sigs)

## Purpose

Creates/updates Route53 records from Ingress/Service DNS annotations.

## IRSA

ServiceAccount `external-dns/external-dns` →:

```bash
terraform -chdir=terraform/envs/prod output -raw irsa_external_dns_role_arn
```

Namespace must match IRSA trust (`external-dns`).

## Bootstrap install (Topic 05)

```bash
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
helm repo update
kubectl create namespace external-dns --dry-run=client -o yaml | kubectl apply -f -
# Edit values.yaml placeholders first
helm upgrade --install external-dns external-dns/external-dns \
  --namespace external-dns \
  --version 1.15.0 \
  --values gitops/platform/external-dns/values.yaml \
  --wait
```

## GitOps

Owned by ApplicationSet `platform-apps` after Topic 06 (`gitops/apps/platform-apps/applicationset.yaml`).
