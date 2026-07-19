# 15 — Secret rotation

**Audience:** L3 — Operator  
**Applies to:** SMTP and future SM secrets  
**Prerequisites:** AWS Secrets Manager IAM; ESO healthy  
**Estimated time:** 15–30 min  
**Risk level:** Medium  

## Purpose

Rotate secrets without committing them to Git, via Secrets Manager → External Secrets Operator.

## When to use / When not to use

**Use** on credential leak, SMTP password change, or periodic hygiene.  
**Do not** put new secrets in `gitops/` values or CI variables as long-lived AWS keys.

## Prerequisites

- [ ] Know SM name: `boutique-eks-gitops/alertmanager-smtp` (or current name from setup)
- [ ] [runbooks/alerting](../runbooks/alerting.md)

## Procedure

### Step 1: Update Secrets Manager

**GUI:** AWS Console → Secrets Manager → secret → **Retrieve** / **Store new secret value** (password field)

Or CLI:

```bash
aws secretsmanager put-secret-value \
  --secret-id <SECRET_ID> \
  --secret-string '{"username":"<SMTP_USER>","password":"<NEW_PASSWORD>"}' \
  --region eu-central-1
```

**Validation:** New version `AWSCURRENT`.

**Expected outcome:** SM updated; Git unchanged.

**Recovery steps:** Roll SM to previous version if AM auth fails.

**Best practices:** Rotate Grafana/Argo admin passwords in-cluster Secrets separately (not SM unless you wire them).

### Step 2: Refresh ESO / pods

```bash
kubectl -n monitoring get externalsecret
kubectl -n monitoring annotate externalsecret alertmanager-smtp \
  force-sync="$(date +%s)" --overwrite 2>/dev/null || true
# Restart AM if needed:
kubectl -n monitoring rollout restart statefulset/alertmanager-kube-prometheus-stack-alertmanager
```

**Validation:** Secret keys present; test alert email (temporary) then disable test rule.

**Expected outcome:** AM authenticates to SMTP.

## End-to-end validation

Email alert path works once; test rule back to `vector(0)`.

## Rollback (section-level)

Restore previous SM version; restart AM.

## Related alerts and dashboards

| Alert | Dashboard | Log query |
|-------|-----------|-----------|
| — | — | AM logs mentioning SMTP auth |

## Security notes

Scope ESO IRSA to prefix ARNs when possible (Security finding SEC-004). Never log secret values.

## Automation opportunities

SM rotation Lambda — out of pilot scope.
