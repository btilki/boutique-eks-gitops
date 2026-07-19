# 14 — Certificate rotation

**Audience:** L3 — Operator  
**Applies to:** Public HTTPS hosts  
**Prerequisites:** Route53 + ACM access; kubectl for cert-manager objects  
**Estimated time:** 20–60 min  
**Risk level:** Medium  

## Purpose

Keep TLS valid. **Public boutique/Argo/Grafana hosts use ACM on ALB** ([ADR-0003](../adr/0003-tls-acm-alb.md)); cert-manager is installed for in-cluster needs.

## When to use / When not to use

**Use** before ACM expiry or after DNS changes break validation.  
**Do not** commit private keys to Git.

## Prerequisites

- [ ] [dns-and-tls](../dns-and-tls.md) / [runbooks/ingress](../runbooks/ingress.md)

## Procedure

### Step 1: ACM (primary)

**GUI:** AWS Console → ACM → `eu-central-1` → certificate for `boutique.biroltilki.art` (+ SANs) → check **Status** / **Renewal eligibility**

**Commands:**

```bash
aws acm list-certificates --region eu-central-1 \
  --query 'CertificateSummaryList[].{Domain:DomainName,Arn:CertificateArn}' --output table
```

**Validation:** Status ISSUED; ALB listener uses correct ARN (Ingress annotation).

**Expected outcome:** HTTPS continues without browser warnings.

**Recovery steps:** Re-request validation; fix Route53 CNAMEs; update Ingress `certificate-arn` via Git if ARN changed.

**Best practices:** Include `*.boutique.biroltilki.art` / listed SANs from Terraform DNS module.

### Step 2: cert-manager (secondary)

```bash
kubectl get certificate -A
kubectl describe certificate -n <ns> <name>
```

**Validation:** `READY=True`.

**Recovery steps:** Fix ClusterIssuer DNS-01; see ingress/DNS troubleshooting.

## End-to-end validation

`curl -I https://boutique.biroltilki.art` → 200; cert dates OK.

## Rollback (section-level)

Point Ingress back to previous ACM ARN via Git if a new cert mis-bound.

## Related alerts and dashboards

| Alert | Dashboard | Log query |
|-------|-----------|-----------|
| TLS errors (user report) | — | ALB access logs (if enabled) |

## Security notes

Prefer ACM-managed renewal; no long-lived cert files on disk in-repo.

## Automation opportunities

CloudWatch/ACM expiry metric → email (optional; not in v1 stack).
