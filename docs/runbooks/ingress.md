# Runbook — Ingress / ALB / DNS down

**Audience:** L2 — Operator  
**Setup:** Topics 05, 09 · **DNS/TLS:** [`../dns-and-tls.md`](../dns-and-tls.md)

## Purpose

Restore public HTTPS for Boutique and platform hostnames behind ACM + ALB.

## Quick triage

```bash
# Replace HOST as needed
HOST=boutique.biroltilki.art   # or stage-boutique / dev-boutique / grafana / argocd

curl -I "https://${HOST}" || true
dig +short "$HOST"
kubectl get ingress -A | grep -E 'frontend|grafana|argocd' || true
```

## Checks (in order)

| # | Check | Command / action |
|---|--------|------------------|
| 1 | DNS points at ALB | `dig +short $HOST` → ALB CNAME/A |
| 2 | Ingress has ADDRESS | `kubectl -n <ns> get ingress -o wide` |
| 3 | ACM on listener | Annotation `certificate-arn`; AWS Console → ALB → Listeners → 443 |
| 4 | Target health | AWS Console → Target Groups → healthy targets |
| 5 | Pods Ready | `kubectl -n <ns> get pods -l app=frontend` (or app label) |
| 6 | LB controller | `kubectl -n kube-system get deploy aws-load-balancer-controller` |
| 7 | external-dns | `kubectl -n external-dns logs deploy/external-dns --tail=50` |

## Common fixes

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| NXDOMAIN | external-dns / hostname annotation | Fix Ingress annotation; wait TTL |
| Timeout | SG / subnet tags | Confirm LB controller IAM + subnet `kubernetes.io/role/elb` |
| SSL error | Wrong/missing ACM | Set `alb.ingress.kubernetes.io/certificate-arn` |
| 502/503 | No healthy targets | Readiness probe; Rollout stuck (see [canary.md](canary.md)) |
| ADDRESS empty | Controller / IAM | Events on Ingress; IRSA role ARN |

## Security

- Do not open NodePorts or change ALB to HTTP-only to “debug”.
- Prefer fixing target health over disabling NetworkPolicies long-term.

## Related

- Setup: [`../setup/05-ingress-dns-tls.md`](../setup/05-ingress-dns-tls.md)
- Alerting: [`alerting.md`](alerting.md)
