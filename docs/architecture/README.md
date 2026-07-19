# Architecture documentation index

Deep architecture for **boutique-eks-gitops**. Start with the executive summary: [../ARCHITECTURE.md](../ARCHITECTURE.md).

| Doc | Purpose |
|-----|---------|
| [01-requirements.md](01-requirements.md) | FRs, NFRs, derived requirements, constraints, assumptions |
| [02-system-context.md](02-system-context.md) | Context, actors, environment strategy |
| [03-component-design.md](03-component-design.md) | Component inventory + diagram |
| [04-data-flows.md](04-data-flows.md) | App, GitOps, TF, secrets, telemetry flows |
| [05-deployment-flow.md](05-deployment-flow.md) | CI, promotion, sync waves, rollback |
| [06-network-design.md](06-network-design.md) | VPC, ingress, DNS, NetworkPolicy |
| [07-security-architecture.md](07-security-architecture.md) | Trust zones, IRSA, supply chain |
| [08-resilience-and-dr.md](08-resilience-and-dr.md) | Failures, scale, DR, rebuild |
| [09-observability.md](09-observability.md) | Metrics, logs, alerts (email) |
| [10-cost-model.md](10-cost-model.md) | Cost drivers, guardrails, teardown |

## Architecture Decision Records

| ADR | Decision |
|-----|----------|
| [ADR-0001](../adr/0001-digest-only-gitops.md) | Digest-only GitOps; CI never deploys to cluster |
| [ADR-0002](../adr/0002-single-cluster-namespaces.md) | Single cluster; namespace environments |
| [ADR-0003](../adr/0003-tls-acm-alb.md) | Public TLS via ACM + ALB |
| [ADR-0004](../adr/0004-dns-hostname-scheme.md) | Locked boutique hostnames |
| [ADR-0005](../adr/0005-observability-on-cluster.md) | Prom/Loki/Grafana/AM email; no CW/PD/OTel |
| [ADR-0006](../adr/0006-cosign-signing-mode.md) | Cosign Sigstore keyless via GitLab OIDC |

Additional notes (region `eu-central-1`, node size, no mesh) remain in [../ARCHITECTURE.md](../ARCHITECTURE.md) tradeoffs and [10-cost-model.md](10-cost-model.md).

## Related

- [../implementation/plan.md](../implementation/plan.md)
- [../../ROADMAP.md](../../ROADMAP.md)
- [../setup/README.md](../setup/README.md)
- [../versions.md](../versions.md)
