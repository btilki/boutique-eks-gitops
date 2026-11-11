# Architecture deep dive — boutique-eks-gitops

Production pilot closed. AWS resources from the pilot were destroyed.  
These pages describe design and behavior in the repo. They do not provision infrastructure.

If you skipped the summary: [../ARCHITECTURE.md](../ARCHITECTURE.md) (executive summary, diagram, tradeoffs).

---

## How to use this folder

| I want to… | Read first |
|------------|------------|
| Follow CI → Git → Argo → prod | [05-deployment-flow.md](05-deployment-flow.md) |
| Understand security (IAM, Kyverno, secrets, supply chain) | [07-security-architecture.md](07-security-architecture.md) |
| See metrics, logs, alerts | [09-observability.md](09-observability.md) |
| Judge cost and teardown | [10-cost-model.md](10-cost-model.md) |
| Walk requirements and constraints | [01-requirements.md](01-requirements.md) |

Delivery contracts: [../promotion.md](../promotion.md) · [../rollback.md](../rollback.md) · [../ci.md](../ci.md)  
Evidence without a cluster: [../pilot-claims.md](../pilot-claims.md)

---

## Architecture pages

| Doc | Purpose |
|-----|---------|
| [01-requirements.md](01-requirements.md) | FRs, NFRs, constraints, assumptions |
| [02-system-context.md](02-system-context.md) | Context, actors, environment strategy |
| [03-component-design.md](03-component-design.md) | Component inventory + diagram |
| [04-data-flows.md](04-data-flows.md) | App, GitOps, Terraform, secrets, telemetry |
| [05-deployment-flow.md](05-deployment-flow.md) | CI, promotion, sync waves, rollback |
| [06-network-design.md](06-network-design.md) | VPC, ingress, DNS, NetworkPolicy |
| [07-security-architecture.md](07-security-architecture.md) | Trust zones, IRSA, supply chain |
| [08-resilience-and-dr.md](08-resilience-and-dr.md) | Failures, scale, DR, rebuild |
| [09-observability.md](09-observability.md) | Metrics, logs, email alerts |
| [10-cost-model.md](10-cost-model.md) | Cost drivers, guardrails, teardown |

---

## Architecture Decision Records

| ADR | Decision |
|-----|----------|
| [ADR-0001](../adr/0001-digest-only-gitops.md) | Digest-only GitOps; **CI never deploys** |
| [ADR-0002](../adr/0002-single-cluster-namespaces.md) | Single cluster; namespace environments |
| [ADR-0003](../adr/0003-tls-acm-alb.md) | Public TLS via ACM + ALB |
| [ADR-0004](../adr/0004-dns-hostname-scheme.md) | Locked boutique hostnames |
| [ADR-0005](../adr/0005-observability-on-cluster.md) | Prometheus / Loki / Grafana / Alertmanager → email; no CloudWatch / PagerDuty / OTel |
| [ADR-0006](../adr/0006-cosign-signing-mode.md) | Cosign Sigstore keyless via GitLab OIDC |
| [ADR-0007](../adr/0007-admission-verify-and-sbom.md) | Admission verify + CycloneDX SBOM (Topic 15 scaffold) |
| [ADR-0008](../adr/0008-argocd-appprojects-sso.md) | Argo AppProjects + deferred SSO / notifications (Topic 17 scaffold) |
| [ADR-0009](../adr/0009-canary-analysis-templates.md) | Canary AnalysisTemplates (Topic 18 scaffold) |
| [ADR-0010](../adr/0010-edge-waf-and-falco.md) | Optional WAF + Falco (Topic 19 scaffold) |

---

## Related

- [../README.md](../README.md) — documentation index
- [../implementation/plan.md](../implementation/plan.md) — phase detail (maintainer reference)
- [../../ROADMAP.md](../../ROADMAP.md) — milestones and phase status
- [../setup/README.md](../setup/README.md) — rebuild (topics 01–14)
- [../versions.md](../versions.md) — version pins
