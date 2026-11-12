# Documentation — boutique-eks-gitops

Production pilot closed. The delivery path was validated, then AWS resources from the pilot were destroyed. These docs describe what was built and how to rebuild it.

If this file disagrees with [`setup/`](setup/README.md) on bootstrap steps, the setup guide wins.

---

## Where to start

| I want to… | Read |
|------------|------|
| Understand the project quickly | [`ARCHITECTURE.md`](ARCHITECTURE.md) · [ADR-0001](adr/0001-digest-only-gitops.md) |
| See pilot proof / lessons | [`evidence/`](evidence/README.md) · [`lessons-learned.md`](lessons-learned.md) · [`pilot-claims.md`](pilot-claims.md) |
| Review design and delivery | [`architecture/`](architecture/README.md) · [`promotion.md`](promotion.md) · [`rollback.md`](rollback.md) · [`ci.md`](ci.md) |
| Rebuild or operate | [`setup/`](setup/README.md) (01–14) · [`versions.md`](versions.md) · [`PRODUCTION_CHECKLIST.md`](PRODUCTION_CHECKLIST.md) · [`runbooks/`](runbooks/README.md) |

---

## Guides by topic

| Topic | Entry |
|-------|--------|
| Architecture summary | [`ARCHITECTURE.md`](ARCHITECTURE.md) |
| Architecture deep dive | [`architecture/README.md`](architecture/README.md) |
| Design decisions | [`adr/`](adr/0001-digest-only-gitops.md) |
| Pilot evidence | [`evidence/README.md`](evidence/README.md) |
| Lessons learned | [`lessons-learned.md`](lessons-learned.md) |
| Bootstrap & teardown | [`setup/README.md`](setup/README.md) |
| Version pins | [`versions.md`](versions.md) |
| Digest promotion / rollback | [`promotion.md`](promotion.md) · [`rollback.md`](rollback.md) |
| CI contract | [`ci.md`](ci.md) |
| Production-pilot checklist | [`PRODUCTION_CHECKLIST.md`](PRODUCTION_CHECKLIST.md) |
| Day-2 operations | [`operations/README.md`](operations/README.md) |
| Symptom runbooks | [`runbooks/README.md`](runbooks/README.md) |
| Implementation / phases | [`implementation/plan.md`](implementation/plan.md) · [`../ROADMAP.md`](../ROADMAP.md) |
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

Authoring inventories (not a reader path): [`setup/OUTLINES.md`](setup/OUTLINES.md) · [`setup/REQUIRED-FILES.md`](setup/REQUIRED-FILES.md)
