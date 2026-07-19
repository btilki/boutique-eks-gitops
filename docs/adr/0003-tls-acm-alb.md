# ADR-0003: Public TLS via ACM on ALB

- **Status:** Accepted  
- **Date:** 2026-07-18  
- **Setup:** Topic 02  

## Context

Boutique and platform UIs need public HTTPS. cert-manager DNS-01 as the primary issuer adds moving parts (DNS challenge race, issuer CRDs) for little gain when AWS ACM integrates cleanly with ALB.

## Decision

- **Primary public TLS:** ACM certificates attached to Application Load Balancers (via AWS Load Balancer Controller annotations).
- **cert-manager:** Installed for platform readiness / future needs, **not** the primary path for public Boutique/platform hostnames in v1.

## Consequences

- **Positive:** Fewer DNS-01 failure modes; native AWS renewal.
- **Negative:** Dependency on ACM issuance and ALB target health; multi-cloud TLS story not portable.
- **Follow-up:** Topic 05 documents hostname → ACM mapping in `docs/dns-and-tls.md`.
