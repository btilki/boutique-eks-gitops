# 20 — Automation opportunities

**Audience:** L3 — Operator / platform  
**Applies to:** Toil reduction backlog  
**Prerequisites:** Manual runbooks executed once  
**Estimated time:** Planning only  
**Risk level:** Low  

## Purpose

List high-value automations that **do not** replace Setup Guide or these runbooks.

## When to use / When not to use

**Use** when prioritizing Feature-mode work after teardown/rebuild.  
**Do not** ship `fix-prod.sh` as the primary ops interface.

## Prerequisites

- [ ] Manual procedure exists and was executed once

## Procedure

### Step 1: Prioritize backlog

| Opportunity | Cuts toil from | Effort | Notes |
|-------------|----------------|--------|-------|
| Read-only `ops-status` script | Morning [08](08-health-checks.md) | S | Print apps + curl codes |
| `runbook_url` on PrometheusRules | Alert triage | S | See [10](10-alerting.md) |
| Real `BoutiqueIngressDown` probe | Blind prod HTTPS | M | Blackbox / synthetic |
| Tighten GitLab OIDC `sub` to protected refs | SEC-001 | S | Terraform |
| Scope ESO IAM to secret prefix | SEC-004 | S | Terraform |
| ADO/GitLab PR: `make lint` + docs-check | Broken merges | M | CI |
| Smoke scripts fail on empty ns / wrong context | False greens | S | tests |
| Chart `securityContext` defaults | Container hardening | M | Charts |

**Validation:** Each item still points back to a human-readable runbook.

**Expected outcome:** Ordered Feature backlog.

**Recovery steps:** If automation fails, fall back to this docs tree.

**Best practices:** Automate detection/validation before mutating cluster state.

## End-to-end validation

N/A until an item is implemented — then add its ops notes.

## Rollback (section-level)

Disable automation; keep docs.

## Related alerts and dashboards

| Alert | Dashboard | Log query |
|-------|-----------|-----------|
| — | — | — |

## Security notes

No automation may embed long-lived cloud keys.

## Automation opportunities

This document *is* the backlog — update when items ship.
