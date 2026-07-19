# Runbook — Alerting (Alertmanager → email)

**Audience:** L2 — Operator  
**Setup:** Topic 08 · **ADR:** [0005 on-cluster observability](../adr/0005-observability-on-cluster.md)

## Purpose

Receive critical alerts by email. No PagerDuty in v1.

## Components

| Piece | Location |
|-------|----------|
| Alertmanager | `monitoring` namespace (kube-prometheus-stack) |
| SMTP password | AWS SM `boutique-eks-gitops/alertmanager-smtp` → ESO → Secret `alertmanager-smtp` |
| Test rule | `AlertmanagerEmailTest` in `prometheusrule-boutique.yaml` |
| Prod intent | `BoutiqueIngressDown` (enabled for real probes after Topic 09) |

## First-time email proof (Topic 08 Step 8.5)

1. Confirm Secret exists: `kubectl -n monitoring get secret alertmanager-smtp`
2. Confirm Alertmanager pods mount the secret and config has `smtp_smarthost` set
3. Ensure `AlertmanagerEmailTest` is loaded: Prometheus UI → Alerts
4. Check inbox for `<SMTP_TO>`
5. **Disable** the test rule after success (set `expr: vector(0)` or remove the group; commit + sync)

## Triage — email received

| Check | Command / action |
|-------|------------------|
| What fired? | Read email subject/body `alertname` |
| Still firing? | Grafana Explore / Prometheus `/alerts` |
| Ingress/shop | Topic 09+ hostnames; ALB target health |
| Silence | Alertmanager UI silences (short TTL) — prefer fix over long silence |

## Triage — no email when expected

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| No Secret | ESO / SM missing | Re-run Topic 08 Step 8.4 |
| Auth fail in AM logs | Bad password/user | Rotate SM secret; wait refresh |
| TLS/SMTP blocked | NetworkPolicy / NAT | Allow egress 443/587 from monitoring |
| Route mismatch | severity labels | Confirm `severity=critical` on alert |

```bash
kubectl -n monitoring logs statefulset/alertmanager-kube-prometheus-stack-alertmanager --tail=100
```

## Security

- Never put SMTP passwords in Git or Argo Application values
- Rotate SMTP credentials after the pilot if the mailbox is shared

## Related

- Setup: [`docs/setup/08-observability.md`](../setup/08-observability.md)
- DNS/TLS: [`docs/dns-and-tls.md`](../dns-and-tls.md)
