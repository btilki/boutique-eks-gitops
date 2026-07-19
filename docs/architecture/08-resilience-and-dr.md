# 08 — Resilience, scalability, and DR

## Failure scenarios

| Scenario | Impact | Detection | Mitigation | Recovery |
|----------|--------|-----------|------------|----------|
| Single AZ / node loss | Pods reschedule; brief errors | Node NotReady; Prom alerts | Multi-AZ node group; replicas≥2 on critical frontend prod | Kubernetes reschedule; verify Rollout |
| NAT AZ failure | Egress broken (pulls, SMTP, some AWS API) | Controller errors; failed pulls | Accept for pilot; endpoints reduce ECR need | Recreate NAT / failover (manual) |
| GitOps desync | Drift or stuck OutOfSync | Argo health; UI | Auto-sync lower envs; restrict prod | Refresh/sync; fix Git |
| Bad digest in prod | Broken storefront | Ingress/app alerts email; Grafana | Canary; CODEOWNERS; manual sync | `git revert`; re-sync |
| Terraform state lock/corrupt | No infra changes | TF errors | DynamoDB lock; versioned S3 | Restore state version; unlock carefully |
| Observability down | Blind ops | Argo app unhealthy; manual checks | Keep retention modest; separate NS | Re-sync monitoring app |
| ACM / cert issue | HTTPS fails | Probe / user reports | Monitor cert expiry in ACM | Revalidate DNS; re-issue |
| Kyverno deny storm | Deploys blocked | Policy reports; Argo sync fail | Audit mode first; exclusions | Git revert policy; Audit |

## Scalability

| Concern | Approach |
|---------|----------|
| Horizontal pods | Start replicas=1 nonprod; frontend prod 2; HPA later if needed |
| Cluster capacity | ASG **min 2 / desired 3 / max 5** × `m6i.large` |
| Vertical | Bump to `m6i.xlarge` if Loki/Prom pressure |
| Logs/metrics growth | Loki ~7d; Prom ~7–15d; drop high-cardinality labels |
| Multi-tenancy | Namespaces + quotas (add ResourceQuota in platform phase if contended) |

### Top bottlenecks

1. **Prometheus/Loki memory** on 8 GiB nodes → retention + limits  
2. **Single NAT throughput/cost** → endpoints; later second NAT  
3. **ALB + canary complexity** → validate on stage before prod weight steps  

## Disaster recovery (production pilot)

| Item | Stance |
|------|--------|
| RTO | Hours (rebuild from Git + Terraform), not multi-region minutes |
| RPO | Git history ≈ desired cluster state; TF state versioning for infra |
| Multi-region | **Out of scope** |
| etcd backup | Rely on EKS; rebuild apps from Git if cluster lost |
| Stateful data | Redis ephemeral OK for pilot; no customer DB in scope |
| Grafana dashboards | Prefer Git-provisioned dashboards where possible |
| Rebuild order | Remote state → TF apply → ingress → Argo bootstrap → platform waves → envs → verify DNS/TLS |

**Primary recovery:** Git + Terraform are sources of truth — not AMI bakefiles.

## Teardown vs DR

- **DR:** restore capability after failure while intending to keep running.  
- **Teardown (FR-11):** intentional destroy for cost — see [10-cost-model.md](10-cost-model.md) and Setup topic `14-teardown`.
