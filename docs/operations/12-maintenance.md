# 12 — Maintenance

**Audience:** L3 — Operator  
**Applies to:** Nodes / platform  
**Prerequisites:** kubectl drain rights; change note  
**Estimated time:** 30–90 min  
**Risk level:** Medium  

## Purpose

Perform planned node or platform maintenance with minimal shop downtime.

## When to use / When not to use

**Use** for node replacement, AMI refresh, or short freezes.  
**Do not** start long maintenance if the pilot should be torn down — prefer Topic 14.

## Prerequisites

- [ ] Notify stakeholders (even if only you)
- [ ] Confirm ASG can absorb one node drain (min ≥ 2)

## Procedure

### Step 1: Cordon and drain

```bash
kubectl cordon <node>
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data --grace-period=60
```

**Validation:** Pods rescheduled elsewhere; storefront 200.

**Expected outcome:** Node `SchedulingDisabled`, drained.

**Recovery steps:** `kubectl uncordon <node>` if drain aborted early.

**Best practices:** Drain one node at a time; watch Argo health.

### Step 2: Return capacity

Replace/terminate instance per ASG; wait for Ready; `uncordon` if reused.

**Validation:** [08-health-checks](08-health-checks.md).

## End-to-end validation

All nodes Ready; no unexpected OutOfSync Degraded apps.

## Rollback (section-level)

Uncordon; cancel ASG instance refresh.

## Related alerts and dashboards

| Alert | Dashboard | Log query |
|-------|-----------|-----------|
| Node NotReady | Grafana | — |

## Security notes

Drain does not rotate credentials — pair with [15](15-secret-rotation.md) if needed.

## Automation opportunities

None required for pilot.
