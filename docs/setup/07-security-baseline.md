# 07 — Security baseline

Audience: L2 — Implementer  
Estimated time: 1.5–2 hours  
Prerequisites: [06 — Argo CD bootstrap](06-argocd-bootstrap.md) complete  
Creates: Kyverno + ClusterPolicies; External Secrets Operator + ClusterSecretStore; NetworkPolicies for `dev`/`stage`/`prod`; sample ExternalSecret + deny-test fixture  
Related ADRs: [0001](../adr/0001-digest-only-gitops.md) · [SECURITY.md](../../SECURITY.md)  
Pins: Kyverno chart **3.3.7** · ESO chart **0.14.4** ([docs/versions.md](../versions.md))

---

## Topic goal

Enforce digest-only / ECR-only admission for Boutique namespaces, enable secrets sync from AWS via **ESO (External Secrets Operator)**, and apply default-deny NetworkPolicies — before observability secrets (SMTP) and app images land. Kyverno provides the admission policies.

## Why this topic is required

Without Kyverno, `:latest` and non-ECR images can reach the cluster. Without ESO, Topic 08 cannot deliver SMTP credentials safely. Without NetworkPolicy, east-west isolation is absent on the shared cluster.

## Before you begin

- Argo `platform-apps` ApplicationSet healthy; `<GITLAB_REPO_URL>` already substituted in AppSets.
- Terraform IRSA output `irsa_external_secrets_role_arn` available.
- Ability to create a short-lived secret in AWS Secrets Manager for the ESO demo.
- Phase B Topic 07 files present on `main` (push before sync).

**Idempotent:** Re-syncing Argo apps is safe. Negative kubectl tests are expected to **fail admission**.

---

## Step 7.1: Sync Kyverno operator

### Goal

Deploy Kyverno via ApplicationSet (`wave` 20) using `gitops/platform/kyverno/values.yaml`.

### Why this step is required

ClusterPolicies need the admission webhook running before enforce mode matters.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"

# Confirm ApplicationSet includes kyverno (Topic 07 update)
grep -A2 'name: kyverno' gitops/apps/platform-apps/applicationset.yaml

# Push to main if not already, then refresh Argo
argocd app sync kyverno --grpc-web || kubectl -n argocd get app kyverno
kubectl -n kyverno get pods
kubectl -n kyverno rollout status deploy/kyverno-admission-controller --timeout=180s
```

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | Argo CD UI |
| Navigation | Application **kyverno** → **SYNC** if not auto-synced |
| Verification | Status **Healthy** / **Synced**; pods Ready in `kyverno` |

### Expected output

Kyverno admission/background controllers Running.

### Validation

```bash
kubectl get crd | grep kyverno
kubectl get validatingwebhookconfigurations | grep kyverno
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| App missing | AppSet not refreshed | Sync `root`; confirm generator list includes kyverno |
| Chart pull fail | Network / repo | Check repo-server logs |

### Recovery

Fix Git URL/values; hard-refresh app; re-sync.

### Best practices

Wait until webhooks Ready before applying policies (Step 7.2).

### Security notes

Admission controllers are privileged — limit who can edit Kyverno Helm values.

---

## Step 7.2: Apply ClusterPolicies (enforce)

### Goal

Sync `kyverno-policies` Application (directory `gitops/platform/kyverno/policies`) with Enforce policies.

### Why this step is required

Policies encode ADR-0001: no `:latest`, digest required, ECR allowlist for app namespaces.

### Commands

```bash
# platform-manifests ApplicationSet must exist on main
kubectl -n argocd get applicationset platform-manifests
argocd app sync kyverno-policies --grpc-web

kubectl get clusterpolicy
kubectl get clusterpolicy deny-latest-tag require-image-digest ecr-registry-allowlist -o wide
```

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | Argo CD UI |
| Navigation | **kyverno-policies** → Synced/Healthy |
| Verification | Three ClusterPolicies present |

Optional audit-first (only if enforce breaks platform unexpectedly): temporarily set `validationFailureAction: Audit` in Git, sync, observe, then return to `Enforce`. Prefer staying on Enforce for this pilot once Kyverno is healthy.

### Expected output

Three ClusterPolicies with `validationFailureAction: Enforce`.

### Validation

```bash
kubectl get clusterpolicy -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.validationFailureAction}{"\n"}{end}'
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| CRD not found | Kyverno not ready | Complete Step 7.1 |
| Policy sync error | API version | Use `kyverno.io/v1` as authored |

### Recovery

Delete broken policy app sync; fix YAML; re-sync.

### Best practices

Keep policies scoped to `dev`/`stage`/`prod` (not `kube-system`).

### Security notes

Do not exempt Boutique namespaces from digest rules for convenience.

---

## Step 7.3: Prove deny of `:latest`

### Goal

Apply the negative test Pod and confirm Kyverno **blocks** it.

### Why this step is required

Validates that Enforce mode works before trusting the supply-chain gate.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"

kubectl apply -f tests/policy/deny-latest-pod.yaml
# EXPECTED: Error from server (admission webhook / policy deny)
```

### GUI instructions (if applicable)

N/A.

### Expected output

Admission error mentioning `deny-latest-tag` and/or `require-image-digest` / `ecr-registry-allowlist`. Pod is **not** created.

### Validation

```bash
kubectl -n dev get pod kyverno-deny-latest-test
# expect: NotFound

# Capture the deny message for evidence:
kubectl apply -f tests/policy/deny-latest-pod.yaml 2>&1 | tee /tmp/kyverno-deny.out
grep -iE 'deny|blocked|violat|latest|digest|ecr' /tmp/kyverno-deny.out
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Pod creates successfully | Policies not synced / Audit mode | Sync kyverno-policies; confirm Enforce |
| Denied for wrong reason | Still OK if blocked | Prefer message citing latest/digest/ECR |

### Recovery

If pod exists, delete it; fix policies; re-test.

```bash
kubectl -n dev delete pod kyverno-deny-latest-test --ignore-not-found
```

### Best practices

Keep `tests/policy/deny-latest-pod.yaml` for regression in Topic 13.

### Security notes

Never “fix” a failing test by weakening policies permanently.

---

## Step 7.4: Sync ESO + ClusterSecretStore (IRSA)

### Goal

Install External Secrets Operator with IRSA annotation; sync ClusterSecretStore manifests.

### Why this step is required

Topic 08 Alertmanager email credentials must come from AWS SM/SSM via ESO — not Git.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"

export IRSA_ESO=$(terraform -chdir=terraform/envs/prod output -raw irsa_external_secrets_role_arn)

# Substitute into values (local or commit per org policy)
sed -i '' "s|<IRSA_ROLE_ARN>|${IRSA_ESO}|g" gitops/platform/external-secrets/values.yaml
# Linux: sed -i
! grep -q '<IRSA_ROLE_ARN>' gitops/platform/external-secrets/values.yaml

# Commit/push values if Argo reads from Git, then:
argocd app sync external-secrets --grpc-web
kubectl -n external-secrets get pods
kubectl -n external-secrets get sa external-secrets -o yaml | grep role-arn

argocd app sync external-secrets-config --grpc-web
kubectl get clustersecretstore
```

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | Argo CD UI |
| Navigation | **external-secrets** then **external-secrets-config** |
| Verification | Both Healthy; ClusterSecretStore Ready |

### Expected output

ESO pods Ready; `aws-cluster-secret-store` and `aws-ssm-parameter-store` exist; SA annotated with IRSA role.

### Validation

```bash
kubectl get clustersecretstore aws-cluster-secret-store -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}{"\n"}'
# expect True (may take ~1 minute)
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Store not Ready | IRSA trust / region | Confirm SA name/namespace match Terraform IRSA module |
| values.yaml synced as manifest | AppSet exclude | Confirm `applicationset-manifests` excludes `values.yaml` |

### Recovery

Fix annotation; restart ESO pods; re-check store status.

### Best practices

Scope IAM to secret name prefixes in a follow-up (`TODO(setup:7.4)` in Terraform).

### Security notes

Never put SMTP passwords in Git values — only ExternalSecret references.

---

## Step 7.5: Apply sample ExternalSecret

### Goal

Create an AWS Secrets Manager secret and sync it into namespace `dev` via ExternalSecret.

### Why this step is required

Proves the E2E secrets path used later for Alertmanager.

### Commands

```bash
# Create demo secret in AWS (one-time)
aws secretsmanager create-secret \
  --name boutique-eks-gitops/demo \
  --region eu-central-1 \
  --secret-string '{"demo-key":"demo-value-not-for-prod"}'

kubectl apply -f examples/externalsecret-sample.yaml
kubectl -n dev get externalsecret demo-sm-secret
kubectl -n dev get secret demo-sm-secret -o yaml
# Confirm data key exists (base64) — do not paste secret values into chat
```

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | AWS Console |
| Navigation | **Secrets Manager** → Secrets → `boutique-eks-gitops/demo` |
| Permissions | Create/read secret |
| Verification | Secret exists in `eu-central-1` |

### Expected output

ExternalSecret **SecretSynced**; Kubernetes Secret `demo-sm-secret` present in `dev`.

### Validation

```bash
kubectl -n dev get externalsecret demo-sm-secret -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}{"\n"}'
kubectl -n dev get secret demo-sm-secret
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| AccessDenied | IAM policy too narrow / wrong secret name | Align secret name with policy; broaden temporarily for pilot |
| Invalid key | JSON property mismatch | Ensure property `demo-key` exists |

### Recovery

Fix IAM/secret payload; delete ExternalSecret and re-apply.

### Best practices

Delete the demo secret after Topic 07 validation (or leave for Topic 08 SMTP which uses a different secret).

```bash
# Optional cleanup after success:
kubectl -n dev delete externalsecret demo-sm-secret --ignore-not-found
# aws secretsmanager delete-secret --secret-id boutique-eks-gitops/demo --force-delete-without-recovery
```

### Security notes

Demo value is non-production. Real SMTP secret must be unique and never committed.

---

## Step 7.6: Sync NetworkPolicies

### Goal

Apply default-deny + allow rules to `dev` / `stage` / `prod` via `network-policies` Application.

### Why this step is required

Namespace isolation on a shared cluster depends on NetworkPolicy enforcement.

### Commands

```bash
argocd app sync network-policies --grpc-web
kubectl -n dev get networkpolicy
kubectl -n stage get networkpolicy
kubectl -n prod get networkpolicy
```

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | Argo CD UI |
| Navigation | **network-policies** → Synced |
| Verification | Policies listed in each env namespace |

### Expected output

Each env namespace has `default-deny-all`, `allow-dns`, `allow-same-namespace`, `allow-from-vpc-ingress`, `allow-egress-https-aws`.

### Validation

```bash
for ns in dev stage prod; do
  echo "== $ns =="
  kubectl -n "$ns" get networkpolicy --no-headers | wc -l
done
# expect 5 per namespace
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Policies exist but no effect | CNI NetworkPolicy disabled | Enable VPC CNI Network Policy on EKS if required |
| DNS broken in pods | allow-dns insufficient | Adjust selectors for CoreDNS |

### Recovery

Tune DNS policy; re-sync; test with a digest-pinned debug pod later (Topic 09).

### Best practices

Tighten `allow-from-vpc-ingress` to ALB security group patterns when operationalizing beyond the pilot.

### Security notes

Default-deny without DNS/egress allows will break workloads — keep the allow set reviewed.

---

## Step 7.7: Topic validation (gate to Topic 08)

### Goal

Confirm security baseline checklist for Milestone M2 prerequisites.

### Why this step is required

Topic 08 depends on ESO for SMTP and assumes policies will not block monitoring images incorrectly (monitoring runs outside app namespaces).

### Commands

```bash
kubectl get clusterpolicy
kubectl -n kyverno get pods
kubectl -n external-secrets get pods
kubectl get clustersecretstore
kubectl -n dev get networkpolicy
test -f examples/externalsecret-sample.yaml
test -f tests/policy/deny-latest-pod.yaml
```

### GUI instructions (if applicable)

N/A.

### Expected output

All checklist items pass.

### Validation

- [ ] Kyverno Healthy (7.1)
- [ ] Three ClusterPolicies Enforce (7.2)
- [ ] `:latest` Pod denied (7.3) — evidence saved
- [ ] ESO + ClusterSecretStore Ready (7.4)
- [ ] Sample ExternalSecret synced once (7.5)
- [ ] NetworkPolicies present in dev/stage/prod (7.6)
- [ ] No secrets committed to Git

### Common problems

Any failure — fix before kube-prometheus-stack (Topic 08).

### Recovery

Re-run failing step; do not install monitoring with broken ESO.

### Best practices

Attach deny-test output to session notes for Topic 13 checklist.

### Security notes

Confirm GitLab CI role still cannot deploy to the cluster.

---

## Topic validation (end-to-end)

Topic 07 is complete when Step 7.7 checklist passes.

**Cost check:** Negligible incremental AWS cost (Secrets Manager secret if retained).

---

## Topic troubleshooting

| Area | Symptom | Action |
|------|---------|--------|
| Kyverno | Blocks platform pods | Ensure policies namespace-scoped to boutique envs only |
| ESO | `SecretSyncedError` | IAM + secret name + region |
| NetworkPolicy | Timeout to API | Check egress 443 allow |
| AppSet | `values.yaml` apply error | Exclude non-manifests in `platform-manifests` |

---

## Next step

**[08 — Observability](08-observability.md)** (Phase B next).

Use ESO for Alertmanager SMTP; keep Prometheus/Loki/Grafana in non-app namespaces so Kyverno digest rules do not block chart images.
