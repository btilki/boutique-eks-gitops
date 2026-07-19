# 10 — Cost model

## Purpose

Financial awareness for a **production pilot** that may run only ~2 days.

## Estimate bands (`eu-central-1`, list-price style)

### Continuous monthly (if left running)

| Resource | Est. monthly | Cost driver | Optimization |
|----------|--------------|-------------|--------------|
| EKS control plane | ~$73 | $0.10/hr | Single cluster |
| 3× `m6i.large` On-Demand | ~$250 | ~$0.115/hr ×3 | ASG max 5; Spot later for nonprod |
| EBS gp3 (~300 GiB) | ~$25–30 | Node disks | 80–100 GiB each; don’t overprovision |
| NAT Gateway ×1 | ~$35+ | Hourly + GB | Single NAT; ECR/S3 endpoints |
| ALB | ~$20–40 | Hourly + LCU | Share ALB where possible |
| ECR / SM / Route53 / state | ~$5–15 | Storage + API | Lifecycle policies on ECR |
| **Total** | **~$350–500** | | Teardown if unused |

### 2-day pilot (48h) with teardown

| Band | Est. |
|------|------|
| Typical | **~$35–45** |
| Lean | ~$28–35 |
| Heavy pulls / extras | ~$50–70 |

## Guardrails

| Guardrail | Setting |
|-----------|---------|
| Node type | `m6i.large` (not larger unless proven need) |
| ASG max | 5 |
| NAT count | 1 |
| Log/metric retention | ≤15 days Prom; ≤7 days Loki |
| No CloudWatch Logs ingestion | On-cluster only |
| ECR endpoints | Enabled to cut NAT GB |
| Always run Phase 11 **immediately after all tests** | Mandatory — no keep-alive |

## Teardown reference

Ordered destroy (details in Setup `14-teardown` / `docs/runbooks/teardown.md`):

1. Stop CI schedules that would recreate load  
2. Prune Argo apps (workloads → platform) to release ALBs  
3. Confirm ELBv2/ENI cleanup  
4. `terraform destroy` foundation  
5. Handle ECR empty/delete  
6. Destroy or retain empty state backend **last**  
7. Verify no EKS cluster / NAT / stray ALBs  

**Do not** destroy Terraform state while resources still exist.

## Cost vs resilience tradeoffs

| Saved money | Accepted risk |
|-------------|---------------|
| Single NAT | Egress SPOF |
| One cluster | Shared blast radius |
| No CW/PD | Self-operated alerts; email only |
| 8 GiB nodes | Possible obs memory pressure |
