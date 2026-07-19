# NetworkPolicy baseline for Boutique env namespaces

**Setup:** Topic 07 · Applied to `dev` / `stage` / `prod`

| Policy | Purpose |
|--------|---------|
| `default-deny-all` | Deny all ingress/egress by default |
| `allow-dns` | DNS to kube-system |
| `allow-same-namespace` | East-west within env |
| `allow-from-vpc-ingress` | ALB/node traffic from VPC CIDR `10.0.0.0/16` |
| `allow-egress-https-aws` | HTTPS/HTTP egress (ECR, APIs) |

Synced via ApplicationSet `platform-manifests`. Requires a CNI that enforces NetworkPolicy (Amazon VPC CNI supports it when enabled — confirm on EKS 1.31).
