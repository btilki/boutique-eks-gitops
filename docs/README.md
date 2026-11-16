# Documentation — boutique-eks-gitops

Production reference closed. The delivery path was validated, then AWS resources from this reference were destroyed. These docs describe what was built and how to rebuild it.

If this file disagrees with [`setup/`](setup/README.md) on bootstrap steps, the setup guide wins.

---

## Where to start

| I want to… | Read |
|------------|------|
| Review this repo in ~10 minutes | [ADR-0001](adr/0001-digest-only-gitops.md) · [`reference-claims.md`](reference-claims.md) · [`evidence/`](evidence/README.md) |
| Architecture summary | [`ARCHITECTURE.md`](ARCHITECTURE.md) · [`architecture/`](architecture/README.md) |
| Lessons | [`lessons-learned.md`](lessons-learned.md) |
| Design and delivery contracts | [`promotion.md`](promotion.md) · [`rollback.md`](rollback.md) · [`ci.md`](ci.md) |
| Rebuild or operate | [`setup/`](setup/README.md) (01–14) · [`versions.md`](versions.md) · [`PRODUCTION_CHECKLIST.md`](PRODUCTION_CHECKLIST.md) · [`runbooks/`](runbooks/README.md) |

---

## Guides by topic

| Topic | Entry |
|-------|--------|
| Architecture summary | [`ARCHITECTURE.md`](ARCHITECTURE.md) |
| Architecture deep dive | [`architecture/README.md`](architecture/README.md) |
| Design decisions | [`adr/`](adr/0001-digest-only-gitops.md) |
| Reference evidence | [`evidence/README.md`](evidence/README.md) |
| Lessons learned | [`lessons-learned.md`](lessons-learned.md) |
| Bootstrap & teardown | [`setup/README.md`](setup/README.md) |
| Version pins | [`versions.md`](versions.md) |
| Digest promotion / rollback | [`promotion.md`](promotion.md) · [`rollback.md`](rollback.md) |
| CI contract | [`ci.md`](ci.md) |
| Production-reference checklist | [`PRODUCTION_CHECKLIST.md`](PRODUCTION_CHECKLIST.md) |
| Day-2 operations | [`operations/README.md`](operations/README.md) |
| Symptom runbooks | [`runbooks/README.md`](runbooks/README.md) |
| Roadmap / milestones | [`../ROADMAP.md`](../ROADMAP.md) |
| DNS & TLS | [`dns-and-tls.md`](dns-and-tls.md) |
| Cost model | [`architecture/10-cost-model.md`](architecture/10-cost-model.md) |

---

## Repository meta

| File | Purpose |
|------|---------|
| [`../README.md`](../README.md) | Project landing page |
| [`../CONTRIBUTING.md`](../CONTRIBUTING.md) | How to contribute |
| [`../SECURITY.md`](../SECURITY.md) | Security reporting |
| [`../CHANGELOG.md`](../CHANGELOG.md) | Notable changes |

### Maintainer only (not a reader path)

Historical planning inventories — skip for hiring review:

- [`setup/OUTLINES.md`](setup/OUTLINES.md)
- [`setup/REQUIRED-FILES.md`](setup/REQUIRED-FILES.md)
- [`implementation/plan.md`](implementation/plan.md)
