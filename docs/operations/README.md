# Operations — boutique-eks-gitops

**Audience:** L2–L3 Operator / on-call (solo maintainer: **You**)  
**Maturity:** Production **pilot** — not enterprise multi-region on-call  
**Authority:** Day-2 procedures. Bootstrap remains [`docs/setup/`](../setup/). Symptom playbooks remain [`docs/runbooks/`](../runbooks/).  
**Last reviewed:** 2026-07-19

Operations assume Topics **01–13** succeeded at least once. If the cluster is gone, rebuild via Setup Guide, then return here.

---

## On-call quick links

| Situation | Runbook | First command |
|-----------|---------|---------------|
| Shop / HTTPS down | [17](17-common-incidents.md) · [ingress](../runbooks/ingress.md) | `curl -sI -o /dev/null -w '%{http_code}\n' https://boutique.biroltilki.art` |
| Bad digest / failed promote | [03](03-rollback.md) · [rollback](../rollback.md) | `git log --oneline -- gitops/envs/prod/values \| head` |
| Failed / stuck deploy | [02](02-deployment.md) · [argo-sync](../runbooks/argo-sync.md) | `kubectl -n argocd get app \| grep -E 'prod\|stage\|frontend'` |
| Canary stuck / abort | [canary](../runbooks/canary.md) | `kubectl -n prod get rollout frontend -o wide` |
| Kyverno deny | [kyverno](../runbooks/kyverno.md) | `kubectl get clusterpolicy` |
| No alert email | [alerting](../runbooks/alerting.md) | `kubectl -n monitoring get secret alertmanager-smtp` |
| Node NotReady | [17](17-common-incidents.md) | `kubectl get nodes -o wide` |
| End pilot / stop cost | [teardown](../runbooks/teardown.md) | Follow Topic 14 **immediately** |

---

## Service catalog

| Component | Namespace / resource | Owner | Dashboard / UI | Primary alert |
|-----------|----------------------|-------|----------------|---------------|
| EKS `boutique-eks-gitops` | AWS `eu-central-1` | You | `kubectl get nodes` | Node NotReady (kube-prometheus defaults) |
| Boutique frontend | `dev` / `stage` / `prod` | You | Storefront hosts below | `BoutiqueIngressDown` *(expr still placeholder — see [10](10-alerting.md))* |
| Other Boutique services | same envs | You | Grafana Explore | CrashLoop / absent metrics |
| Argo CD | `argocd` | You | https://argocd.boutique.biroltilki.art | App Degraded / Unknown |
| Grafana / Prom / AM / Loki | `monitoring` | You | https://grafana.boutique.biroltilki.art | Monitoring stack unhealthy |
| GitLab CI → ECR | GitLab + ECR | You | GitLab → CI/CD → Pipelines | Pipeline failed / Trivy CRITICAL |
| External Secrets / SMTP | `external-secrets` / `monitoring` | You | `kubectl get externalsecret -A` | SecretSynced false |

**Hostnames:** `argocd` · `grafana` · `dev-boutique` · `stage-boutique` · `boutique` — all under `*.biroltilki.art` (see [dns-and-tls](../dns-and-tls.md)).

---

## Escalation (solo pilot)

| Level | Role | When |
|-------|------|------|
| L1 | You (on-call) | First response to alert or user report |
| L2 | You (platform) | > 30 min without mitigation, or data/IAM risk |
| L3 | AWS account admin (You) | Billing lockout, account IAM break-glass, unable to destroy |

There is **no** PagerDuty. Alertmanager → **email** only ([ADR-0005](../adr/0005-observability-on-cluster.md)).

---

## Section index

| # | Doc | Required | Summary |
|---|-----|----------|---------|
| 01 | [Overview](01-overview.md) | Yes | Model, envs, SLOs (honest), doc map |
| 02 | [Deployment](02-deployment.md) | Yes | Digest promote + prod manual sync |
| 03 | [Rollback](03-rollback.md) | Yes | `git revert` + Argo + canary abort |
| 04 | [Scaling](04-scaling.md) | Yes | ASG / replicas; HPA not enabled |
| 05 | [Disaster recovery](05-disaster-recovery.md) | Yes | Rebuild-from-Git+TF; RTO hours |
| 06 | [Backup and restore](06-backup-and-restore.md) | Yes | TF state + Git; Redis ephemeral |
| 07 | [Incident response](07-incident-response.md) | Yes | SEV levels + workflow |
| 08 | [Health checks](08-health-checks.md) | Yes | Morning / post-change checks |
| 09 | [Monitoring](09-monitoring.md) | Yes | Grafana / Prom / golden signals |
| 10 | [Alerting](10-alerting.md) | Yes | Email path + rule inventory |
| 11 | [Logging](11-logging.md) | Yes | Loki queries |
| 12 | [Maintenance](12-maintenance.md) | Yes | Drain/cordon; prefer teardown if ending |
| 13 | [Upgrades](13-upgrades.md) | Yes | Pin-ordered upgrades |
| 14 | [Certificate rotation](14-certificate-rotation.md) | Yes | ACM (+ cert-manager) |
| 15 | [Secret rotation](15-secret-rotation.md) | Yes | SMTP / SM via ESO |
| 16 | [Troubleshooting](16-troubleshooting.md) | Yes | Flow → runbooks |
| 17 | [Common incidents](17-common-incidents.md) | Yes | Playbooks |
| 18 | [Recovery procedures](18-recovery-procedures.md) | Yes | Ordered recovery |
| 19 | [Postmortem checklist](19-postmortem-checklist.md) | Yes | Blameless PM |
| 20 | [Automation opportunities](20-automation-opportunities.md) | Yes | Toil backlog |

**Symptom playbooks (do not duplicate here):** [docs/runbooks/](../runbooks/)

---

## Related

- [ARCHITECTURE.md](../ARCHITECTURE.md) · [08-resilience-and-dr](../architecture/08-resilience-and-dr.md)
- [PRODUCTION_CHECKLIST.md](../PRODUCTION_CHECKLIST.md)
- [versions.md](../versions.md) · [CONTRIBUTING.md](../../CONTRIBUTING.md)
