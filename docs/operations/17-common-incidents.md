# 17 — Common incidents

**Audience:** L3 — Operator  
**Applies to:** All envs  
**Prerequisites:** kubectl, git, AWS console access  
**Estimated time:** 10–45 min per playbook  
**Risk level:** Medium  

## Purpose

First-response playbooks for the failure modes this stack actually hits.

## When to use / When not to use

**Use** during triage ([07](07-incident-response.md)).  
**Do not** skip diagnosis and jump to `terraform destroy` unless SEV-1 unrecoverable.

---

## Playbook A — Pod CrashLoopBackOff

**Purpose:** Restore a crashing Boutique/platform pod.

**Diagnosis:**

```bash
kubectl -n <ns> get pods
kubectl -n <ns> describe pod <pod>
kubectl -n <ns> logs <pod> --tail=100
```

**Common fix:** Bad digest/config → [03-rollback](03-rollback.md); Kyverno deny → [runbooks/kyverno](../runbooks/kyverno.md); OOM → raise limits in chart values via Git.

**Validation:** Pod `Running` / `Ready`; storefront curl 200 if frontend.

**Recovery:** Revert last digest/values MR if fix worsens.

**Prevention:** Stage canary before prod; Trivy CRITICAL gate.

---

## Playbook B — GitOps OutOfSync / stuck

**Purpose:** Restore Argo reconciliation.

**Diagnosis / fix:** Follow **[runbooks/argo-sync](../runbooks/argo-sync.md)** (refresh, sync, prune carefully).

```bash
kubectl -n argocd get app <name> -o jsonpath='{.status.sync.status} {.status.health.status}{"\n"}'
```

**Validation:** Sync `Synced` or known canary OutOfSync + Healthy; health `Healthy`.

**Prevention:** Digest-only MRs; avoid kubectl drift.

---

## Playbook C — Certificate / HTTPS failure

**Purpose:** Restore TLS on ALB-backed hosts.

**Diagnosis:**

```bash
curl -vI https://boutique.biroltilki.art 2>&1 | head -40
# ACM (primary for public boutique hosts)
aws acm list-certificates --region eu-central-1
kubectl get certificate -A 2>/dev/null || true
```

**Common fix:** [runbooks/ingress](../runbooks/ingress.md) + [14-certificate-rotation](14-certificate-rotation.md); DNS/ACM validation.

**Validation:** HTTPS 200; cert not expired in browser/`openssl s_client`.

**Prevention:** Monitor ACM expiry; keep Route53 NS correct.

---

## Playbook D — Node NotReady

**Purpose:** Restore capacity.

**Diagnosis:**

```bash
kubectl get nodes
kubectl describe node <node> | tail -40
```

**Common fix:** Wait for AWS repair; cordon/drain if replacing; check ASG in EC2 console; TF node group healthy.

**Validation:** Node Ready; pods rescheduled.

**Recovery:** Scale ASG within 2–5; do not exceed cost envelope without approval.

**Prevention:** Multi-AZ node group (already); keep Loki/Prom memory bounded.

---

## Playbook E — High memory / OOMKilled

**Purpose:** Stop restart loops from memory pressure.

**Diagnosis:**

```bash
kubectl -n <ns> get pod <pod> -o jsonpath='{.status.containerStatuses[*].lastState.terminated.reason}{"\n"}'
kubectl top pods -n <ns> 2>/dev/null || true
```

**Common fix:** Lower Loki/Prom retention/limits via Git values; scale loadgenerator off (if present); bump requests/limits in chart values MR.

**Validation:** No OOM restarts for 15m; `kubectl top` stable.

**Prevention:** Resource caps in monitoring values; ASG max 5.

---

## Playbook F — Terraform state lock

**Purpose:** Unblock infra changes safely.

**Diagnosis:**

```bash
cd terraform/envs/prod
terraform plan
# Error mentions DynamoDB lock ID
```

**Common fix:** Confirm no other apply running; then **cautious** unlock:

```bash
terraform force-unlock <LOCK_ID>
```

**Validation:** `terraform plan` runs without lock error.

**Recovery:** If state corrupt, restore prior S3 object version ([06](06-backup-and-restore.md)).

**Prevention:** One operator apply at a time; never unlock during active apply.

---

## Playbook G — Kyverno admission deny

**Purpose:** Unblock pods rejected for digest/tag/registry.

**Diagnosis / fix:** **[runbooks/kyverno](../runbooks/kyverno.md)**

**Validation:** Pod creates; policy still Enforce for bad images.

---

## Playbook H — Canary stuck / bad traffic split

**Purpose:** Finish or abort progressive delivery.

**Diagnosis / fix:** **[runbooks/canary](../runbooks/canary.md)** + Git revert of digest if needed.

**Validation:** Rollout `Healthy`; single desired digest serving; curl 200.

---

## End-to-end validation

Incident closed only after [08-health-checks](08-health-checks.md) pass for affected env.

## Rollback (section-level)

Prefer Git revert of the change that caused the incident.

## Related alerts and dashboards

| Alert | Dashboard | Log query |
|-------|-----------|-----------|
| BoutiqueIngressDown | Grafana | `{namespace="prod"}` |
| AlertmanagerEmailTest | — | Should stay `vector(0)` |

## Security notes

Do not disable Kyverno Enforce to “get pods up” without a time-boxed exception MR.

## Automation opportunities

Wire `runbook_url` annotations on PrometheusRules to this file’s anchors.
