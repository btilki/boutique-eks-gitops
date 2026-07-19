# 10 — Alerting

**Audience:** L3 — Operator  
**Applies to:** `monitoring`  
**Prerequisites:** SMTP secret via ESO; inbox access  
**Estimated time:** 20 min  
**Risk level:** Low  

## Purpose

Operate Alertmanager → **email** and keep rules honest (no always-firing test noise).

## When to use / When not to use

**Use** when proving email path, silencing carefully, or fixing missing alerts.  
**Do not** leave `AlertmanagerEmailTest` firing in steady state.

## Prerequisites

- [ ] Read [runbooks/alerting](../runbooks/alerting.md)

## Procedure

### Step 1: Confirm pipeline

Follow **[runbooks/alerting](../runbooks/alerting.md)** (Secret, AM config, inbox).

**Validation:** Test email received once historically; test rule `expr: vector(0)`.

### Step 2: Rule inventory

| Alert | File | Notes |
|-------|------|-------|
| `AlertmanagerEmailTest` | `gitops/platform/monitoring/manifests/prometheusrule-boutique.yaml` | Must stay disabled (`vector(0)`) |
| `BoutiqueIngressDown` | same | **Placeholder expr** — replace with blackbox/ALB probe before relying on it |

**Recommended annotation** (add in a follow-up MR):

```yaml
annotations:
  runbook_url: "https://gitlab.com/<group>/boutique-eks-gitops/-/blob/main/docs/operations/17-common-incidents.md"
  summary: "Boutique ingress missing/down (prod)"
```

**Validation:** `kubectl -n monitoring get prometheusrule boutique-alerting -o yaml | head`

**Expected outcome:** Rules loaded by Prometheus.

**Recovery steps:** Sync monitoring app; check AM logs.

**Best practices:** Prefer fix over multi-day silences.

## End-to-end validation

Critical email arrives for a deliberate test, then test rule disabled again.

## Rollback (section-level)

Revert PrometheusRule MR if a noisy rule ships.

## Related alerts and dashboards

| Alert | Dashboard | Log query |
|-------|-----------|-----------|
| Any | AM UI | `kubectl -n monitoring logs statefulset/alertmanager-kube-prometheus-stack-alertmanager --tail=100` |

## Security notes

SMTP password only in AWS Secrets Manager → ESO — never in Git.

## Automation opportunities

Blackbox exporter probe for `https://boutique.biroltilki.art/_healthz` + real `BoutiqueIngressDown` expr.
