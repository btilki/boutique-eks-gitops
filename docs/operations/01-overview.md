# 01 — Operations overview

**Audience:** L3 — Operator  
**Applies to:** `dev` / `stage` / `prod` (namespaces on one EKS cluster)  
**Prerequisites:** Cluster built via [`docs/setup/`](../setup/); AWS + kubectl context for `boutique-eks-gitops`  
**Estimated time:** 10 min read  
**Risk level:** Low  

## Purpose

Define how this pilot is operated day-2: environments, ownership, SLOs (honest), and where to find procedures.

## When to use / When not to use

**Use** when joining on-call, after a rebuild, or before a change window.  
**Do not use** as bootstrap — that is Setup Guide only.

## Prerequisites

- [ ] Read [ARCHITECTURE.md](../ARCHITECTURE.md) trust boundaries
- [ ] Confirm kubeconfig: `kubectl config current-context` mentions `boutique-eks-gitops`
- [ ] Know whether Topic 14 teardown is imminent (cost guardrail)

## Procedure

### Step 1: Operational model

| Fact | Value |
|------|--------|
| Deploy authority | **Git only** — digest MRs; Argo reconciles |
| CI role | Build / scan / sign / digest MR to **dev** — **no** cluster deploy |
| Prod gate | CODEOWNERS `@btilki` + **manual** Argo sync |
| Alerts | Alertmanager → email (no PagerDuty) |
| Blast radius | One cluster = all envs; namespace ≠ account isolation |
| End state | **Teardown** after tests ([runbooks/teardown](../runbooks/teardown.md)) |

**Validation:**

```bash
kubectl get ns | grep -E 'dev|stage|prod|argocd|monitoring'
```

**Expected outcome:** App and platform namespaces present (unless already destroyed).

**Recovery steps:** If missing, rebuild from Setup Topics 03–09 — do not invent live-only state.

**Best practices:** Prefer Git revert over kubectl mutate; treat prod manual sync as the release lever.

### Step 2: Environments

| Env | Namespace | Hostname | Argo sync |
|-----|-----------|----------|-----------|
| dev | `dev` | `dev-boutique.biroltilki.art` | Automated |
| stage | `stage` | `stage-boutique.biroltilki.art` | Automated (+ canary) |
| prod | `prod` | `boutique.biroltilki.art` | **Manual** |

**Validation:** `curl -sI -o /dev/null -w '%{http_code}\n' https://boutique.biroltilki.art`

### Step 3: SLOs / SLAs (pilot-honest)

| Item | Target | Notes |
|------|--------|-------|
| Availability SLO | Best-effort | No contractual SLA |
| RTO | Hours | Rebuild Git + Terraform ([05](05-disaster-recovery.md)) |
| RPO | Git history | TF state versioned in S3; Redis cart ephemeral |
| Alert ack | Email when online | Not 24×7 staffing |

## End-to-end validation

Operator can open [README](README.md) quick links and name the promote/rollback docs without searching chat history.

## Rollback (section-level)

N/A (documentation only).

## Related alerts and dashboards

| Alert | Dashboard | Log query |
|-------|-----------|-----------|
| Any critical email | Grafana home | — |

## Security notes

Single-cluster multi-env is an accepted pilot risk ([SECURITY.md](../../SECURITY.md)).

## Automation opportunities

Ops-status script printing Argo + curl codes — see [20](20-automation-opportunities.md).
