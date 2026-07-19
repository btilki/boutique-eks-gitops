# ADR-0004: DNS hostname scheme under biroltilki.art

- **Status:** Accepted  
- **Date:** 2026-07-18  
- **Setup:** Topic 02  

## Context

Platform and application endpoints need stable, memorable DNS names for ACM, external-dns, and human ops.

## Decision

Use Route53 zone `biroltilki.art` with this **locked** set:

```text
argocd.boutique.biroltilki.art
grafana.boutique.biroltilki.art
dev-boutique.biroltilki.art
stage-boutique.biroltilki.art
boutique.biroltilki.art
```

`boutique.biroltilki.art` is the **prod** storefront. Platform hosts use the `*.boutique.biroltilki.art` pattern; env storefronts use `{env}-boutique` except prod.

## Consequences

- **Positive:** One mental model; ACM SANs can cover the set; external-dns ownership clear.
- **Negative:** Renames require ACM + Ingress + docs churn — treat as locked for the pilot.
- **Follow-up:** Topic 05 implements records via external-dns.
