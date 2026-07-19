# ADR-0002: Single cluster with namespace environments

- **Status:** Accepted  
- **Date:** 2026-07-18  
- **Setup:** Topic 02  

## Context

`dev`, `stage`, and `prod` need isolation sufficient for a production **pilot**, under a cost-sensitive short test window (single NAT, one EKS).

## Decision

Run **one** EKS cluster in `eu-central-1`. Environments are **namespaces** plus separate Git paths `gitops/envs/{dev,stage,prod}/`, differentiated by:

- Hostname scheme (ADR-0004)
- Sync policy (prod manual)
- CODEOWNERS on prod digests
- NetworkPolicy baseline

## Consequences

- **Positive:** Lower cost; simpler Terraform; faster pilot teardown.
- **Negative:** Shared blast radius (node/control-plane failure affects all envs); not multi-account isolation.
- **Rejected alternative:** Three clusters — deferred until single-cluster limits are proven painful.
