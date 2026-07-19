# AWS Load Balancer Controller

**Setup:** Topic 05 · **Pin:** controller **v2.11.x** · Helm chart **1.11.4** (verify with `helm show chart`)

## Purpose

Provisions AWS ALBs from Kubernetes Ingress resources (public HTTPS via ACM).

## IRSA

ServiceAccount `kube-system/aws-load-balancer-controller` → role from:

```bash
terraform -chdir=terraform/envs/prod output -raw irsa_aws_lb_controller_role_arn
```

## Bootstrap install (before Argo — Topic 05)

```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update
# Edit values.yaml placeholders first (Step 5.1–5.2)
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --version 1.11.4 \
  --values gitops/platform/aws-load-balancer-controller/values.yaml \
  --wait
```

## GitOps

Owned by ApplicationSet `platform-apps` after Topic 06:

`gitops/apps/platform-apps/applicationset.yaml` (Helm multi-source + this `values.yaml`).
