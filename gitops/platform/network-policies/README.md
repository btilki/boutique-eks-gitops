# NetworkPolicy baseline for Boutique env namespaces

**Setup:** Topic 07 · Applied to `dev` / `stage` / `prod`

| Policy | Purpose |
|--------|---------|
| `default-deny-all` | Deny all ingress/egress by default |
| `allow-dns` | DNS to kube-system |
| `allow-same-namespace` | All ports between pods in the same namespace. Frontend and Redis are in this set. |
| `allow-from-vpc-ingress` | Ingress from VPC CIDR `10.0.0.0/16` |
| `allow-egress-https-aws` | Egress TCP 80 and 443 to the internet, except `169.254.169.254/32` |

Other namespaces stay denied. This baseline does not give each Boutique service its own allow-list.

Synced via ApplicationSet `platform-manifests`. Requires a CNI that enforces NetworkPolicy (Amazon VPC CNI supports it when enabled — confirm on EKS 1.31).
