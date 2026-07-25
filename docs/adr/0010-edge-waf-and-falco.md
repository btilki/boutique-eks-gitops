# ADR-0010: Optional edge WAF + runtime Falco (scaffold)

- **Status:** Accepted (scaffold)  
- **Date:** 2026-07-25  
- **Setup:** Topic 19  

## Context

The pilot edge was ACM + ALB + NetworkPolicy without **AWS WAF** or **runtime detection**. LB Controller IRSA already permits WAFv2 associate/disassociate. Operators rebuilding for longer-lived use need a documented, cost-gated path.

## Decision

1. **WAF:** Terraform module `terraform/modules/waf` creates a REGIONAL WAFv2 Web ACL with AWS Managed Rules when `enable_waf = true` (default **false**). Associate via Ingress annotation `alb.ingress.kubernetes.io/wafv2-acl-arn` (not hard-coded ALB ARNs in Terraform).
2. **Falco:** Helm values and an ApplicationSet **example** ship under GitOps; Falco is **not** in the live `platform-apps` ApplicationSet until explicitly enabled (DaemonSet cost/noise).
3. Prefer **modern-bpf** Falco driver on EKS 1.31.

## Consequences

- **Positive:** Edge and runtime controls ready without paying for WAF/Falco during short rebuilds; annotation association fits multi-ALB Boutique hosts.
- **Negative:** Managed WAF rules can false-positive; Falco needs tuning; WAF CloudWatch metrics add minor cost when enabled.
- **Follow-ups:** Scope WAF to prod hostname only; Falcosidekick → Slack/Alertmanager; IP allowlist on Argo UI as alternative to full WAF.
