# DNS and TLS — boutique-eks-gitops

**Audience:** L2 — Implementer  
**ADRs:** [0003 ACM+ALB](adr/0003-tls-acm-alb.md) · [0004 hostname scheme](adr/0004-dns-hostname-scheme.md)  
**Setup:** Topic 05 · Terraform ACM: Topic 04 `module.dns`

## Locked hostnames

| Hostname | Purpose | TLS |
|----------|---------|-----|
| `argocd.boutique.biroltilki.art` | Argo CD UI | ACM on ALB |
| `grafana.boutique.biroltilki.art` | Grafana | ACM on ALB |
| `dev-boutique.biroltilki.art` | Boutique storefront (dev) | ACM on ALB |
| `stage-boutique.biroltilki.art` | Boutique storefront (stage) | ACM on ALB |
| `boutique.biroltilki.art` | Boutique storefront (prod) | ACM on ALB |
| `smoke.boutique.biroltilki.art` | Temporary M1 smoke (Topic 05) | ACM on ALB |

Zone: **`biroltilki.art`** (Route53 public).

## Certificate inventory

Terraform requests one ACM certificate (region `eu-central-1`) with:

- Primary: `boutique.biroltilki.art`
- SANs: `*.boutique.biroltilki.art`, `dev-boutique.biroltilki.art`, `stage-boutique.biroltilki.art`

```bash
terraform -chdir=terraform/envs/prod output -raw acm_certificate_arn
# Status must be ISSUED (Topic 04 Step 4.6)
```

Attach the ARN to Ingresses via:

```text
alb.ingress.kubernetes.io/certificate-arn: <ACM_CERTIFICATE_ARN>
```

## DNS automation

**external-dns** (IRSA) watches Ingress/Service annotations and upserts records in the hosted zone.

Owner ID: `boutique-eks-gitops` (TXT registry) — do not run a second external-dns with the same owner against this zone.

## cert-manager role

Installed in Topic 05 for platform readiness. **Not** used for public boutique/platform TLS in v1 (ACM is primary). Optional in-cluster issuers may be added later without changing public hostname TLS.

## Ingress annotations (reference)

```yaml
alb.ingress.kubernetes.io/scheme: internet-facing
alb.ingress.kubernetes.io/target-type: ip
alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
alb.ingress.kubernetes.io/certificate-arn: "<ACM_CERTIFICATE_ARN>"
external-dns.alpha.kubernetes.io/hostname: "<HOSTNAME>"
```

IngressClass: `alb` (AWS Load Balancer Controller).

## Milestone M1 proof

```bash
curl -I https://smoke.boutique.biroltilki.art
# Expect HTTP/2 200 (or 302) with a valid public certificate
```

Delete smoke resources after validation (`examples/smoke-ingress.yaml`).
