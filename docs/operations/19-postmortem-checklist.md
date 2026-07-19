# 19 — Postmortem checklist

**Audience:** L3 — Operator  
**Applies to:** SEV-1 / SEV-2  
**Prerequisites:** Incident resolved or mitigated  
**Estimated time:** 30–90 min  
**Risk level:** Low  

## Purpose

Run a **blameless** postmortem so the same failure is less likely — even on a solo pilot.

## When to use / When not to use

**Use** after SEV-1/2 within ~48 hours.  
**Do not** skip for “just a pilot” if teardown is delayed and lessons apply to the next rebuild.

## Prerequisites

- [ ] Timeline notes from the incident
- [ ] Links to MRs / pipeline IDs / alert emails

## Procedure

### Step 1: Fill template

```markdown
# Postmortem — <title>
Date (UTC):
SEV:
IC:
## Summary
## Impact (users, duration, envs)
## Timeline
| Time UTC | Event |
|----------|-------|
## Root cause
## What went well
## What went poorly
## Action items
| Action | Owner | Due | Tracking |
|--------|-------|-----|----------|
## Detection gaps
## Rollback / DR effectiveness
```

**Validation:** At least one preventive action item filed (GitLab issue or ROADMAP note).

**Expected outcome:** Shared understanding; no blame language.

**Recovery steps:** N/A.

**Best practices:** Separate “trigger” from “root cause”; link Security/Testing follow-ups.

## End-to-end validation

Action items visible in issue tracker or `docs/operations/20` backlog.

## Rollback (section-level)

N/A.

## Related alerts and dashboards

| Alert | Dashboard | Log query |
|-------|-----------|-----------|
| Original alert | — | — |

## Security notes

Strip secrets from timeline paste.

## Automation opportunities

PM issue template in GitLab.
