# Runbooks — boutique-eks-gitops

**Audience:** L2 — Operator  
**Setup:** Topics 08, 13, 14 · Checklist: [`../PRODUCTION_CHECKLIST.md`](../PRODUCTION_CHECKLIST.md)  
**Day-2 index:** [`../operations/README.md`](../operations/README.md) (deploy, DR, incidents, health)

| Runbook | Symptom | Setup topic |
|---------|---------|-------------|
| [alerting.md](alerting.md) | No email / noisy alerts | 08 |
| [ingress.md](ingress.md) | HTTPS / ALB / DNS down | 05, 09 |
| [argo-sync.md](argo-sync.md) | App OutOfSync / stuck / prod not updating | 06 |
| [kyverno.md](kyverno.md) | Pods blocked by policy | 07 |
| [canary.md](canary.md) | Canary stuck / abort / bad weight | 12 |
| [teardown.md](teardown.md) | Decommission pilot *(Topic 14)* | 14 |

**Related:** [promotion](../promotion.md) · [rollback](../rollback.md) · [dns-and-tls](../dns-and-tls.md) · [operations](../operations/README.md)
