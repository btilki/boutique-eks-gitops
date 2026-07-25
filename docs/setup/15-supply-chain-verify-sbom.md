# 15 — Supply chain close-loop (verify + SBOM)

Audience: L2 — Implementer  
Estimated time: 1–2 hours (scaffold now; live apply after rebuild)  
Prerequisites: [07 — Security baseline](07-security-baseline.md) + [10 — GitLab CI digests](10-gitlab-ci-digest.md) on a rebuilt cluster; or scaffold-only on this repo with no live AWS  
Creates: Kyverno `verifyImages` policies (Audit); CI `sbom` stage; [ADR-0007](../adr/0007-admission-verify-and-sbom.md); unsigned-digest test example  
Related ADRs: [0001](../adr/0001-digest-only-gitops.md) · [0006](../adr/0006-cosign-signing-mode.md) · [0007](../adr/0007-admission-verify-and-sbom.md)  
Pins: Trivy **0.71.0** · cosign **2.4.x** · Kyverno chart **3.3.7** ([docs/versions.md](../versions.md))

---

## Topic goal

Close the supply-chain loop: CI still signs images (Topic 10) and now also emits a **SBOM (Software Bill of Materials)** as CycloneDX + `cosign attest`; Kyverno **audits** (then later **enforces**) Sigstore keyless signatures and SBOM attestations at admission — without changing the digest-only GitOps contract.

## Why this topic is required

Signing without admission verify lets unsigned digests run if they pass digest/ECR rules. Without an SBOM, operators lack a machine-readable inventory for vulns/licenses. This topic scaffolds both for a **future rebuild**; it does not require live AWS today.

## Before you begin

**Scaffold-only (current repo state — no cluster):**

- Confirm files listed under [Creates](#topic-goal) exist on the branch.
- Do **not** set `ENABLE_PILOT_CI=true` until Topics 03–04 AWS exist again.

**Apply after cluster rebuild (after Topic 04 → 07 → 09 → 10):**

- Kyverno operator + `kyverno-policies` Application healthy.
- At least one CI-signed digest in ECR for a Boutique service.
- Cluster egress to Fulcio/Rekor (Sigstore) from Kyverno pods (same as cosign verify needs).

**Idempotent:** Re-syncing Audit policies is safe. Flipping to Enforce before signed digests exist will block Boutique pods.

---

## Step 15.1: Confirm scaffold files in Git

### Goal

Prove Topic 15 artifacts are present without touching AWS.

### Why this step is required

Scaffold-first delivery; live steps depend on these paths.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"

test -f gitops/platform/kyverno/policies/verify-image-signatures.yaml
test -f gitops/platform/kyverno/policies/verify-sbom-attestation.yaml
test -f docs/adr/0007-admission-verify-and-sbom.md
test -f tests/policy/unsigned-digest-pod.yaml.example
grep -q 'stage: sbom' .gitlab-ci.yml
grep -q 'verify-image-signatures' gitops/platform/kyverno/policies/verify-image-signatures.yaml
grep -E 'validationFailureAction: Audit' \
  gitops/platform/kyverno/policies/verify-image-signatures.yaml \
  gitops/platform/kyverno/policies/verify-sbom-attestation.yaml
```

### Expected output

All `test`/`grep` commands exit 0. Both ClusterPolicies show **Audit**.

### Validation

```bash
grep -A2 'name: verify-image-signatures' gitops/platform/kyverno/policies/verify-image-signatures.yaml
grep -n 'sbom:' .gitlab-ci.yml | head -5
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| File missing | Branch not updated | Merge/pull Topic 15 commit |
| Enforce already set | Premature edit | Keep Audit until Step 15.4 |

### Security notes

Do not commit Fulcio private material; keyless only (ADR-0006/0007).

---

## Step 15.2: Align GitLab identity in Kyverno policies

### Goal

Ensure `subjectRegExp` matches the GitLab `path_with_namespace` that CI uses for Sigstore identities.

### Why this step is required

Wrong subject → Audit failures forever; Enforce would deny all pods.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"

# Compare to your GitLab project path (example: btilki/boutique-eks-gitops)
grep -n 'subjectRegExp' gitops/platform/kyverno/policies/verify-*.yaml
```

If the path differs, edit both policies:

```yaml
subjectRegExp: "https://gitlab.com/<GROUP>/<PROJECT>//.*"
```

Optional harden after rebuild (protected default branch only):

```yaml
subjectRegExp: "https://gitlab.com/<GROUP>/<PROJECT>//.gitlab-ci.yml@refs/heads/main"
```

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | GitLab |
| Navigation | Project → **Settings** → **General** → note **Project URL** / path |
| Permissions | Maintainer |

### Expected output

`subjectRegExp` contains your exact group/project path.

### Validation

```bash
# After a successful Topic 10+15 pipeline on rebuild, inspect identity from cosign:
# cosign verify --certificate-oidc-issuer https://gitlab.com ...
# then confirm the certificate subject matches subjectRegExp
true
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Reports: subject mismatch | Path typo / fork | Update both YAML files; commit; Argo sync |
| Self-managed GitLab | Issuer not gitlab.com | Change `issuer` + Rekor strategy (out of v1 scope) |

### Security notes

Prefer narrowing to `@refs/heads/main` once Enforce is planned; avoid `.*` forever in production.

---

## Step 15.3: Apply after rebuild — sync policies + run SBOM CI

> **Apply after cluster rebuild (after Topic 04+).** Skip on a torn-down pilot.

### Goal

Load Audit policies via Argo and produce SBOM attestations from CI.

### Why this step is required

Git alone does not admit or attest; rebuild makes the loop real.

### Commands

```bash
# Policies ride ApplicationSet platform-manifests → kyverno-policies (recurse *.yaml)
argocd app sync kyverno-policies --grpc-web || \
  kubectl -n argocd get app kyverno-policies

kubectl get clusterpolicy verify-image-signatures verify-sbom-attestation
kubectl get clusterpolicy verify-image-signatures \
  -o jsonpath='{.spec.validationFailureAction}{"\n"}'

# Re-enable CI only with AWS restored (see docs/ci.md)
# GitLab → Settings → CI/CD → Variables: ENABLE_PILOT_CI=true
# Push/merge to default branch → confirm stages: … → sign → sbom → gitops
```

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | Argo CD |
| Navigation | Application **kyverno-policies** → confirm both verify\* policies synced |
| Platform | GitLab |
| Navigation | **CI/CD** → **Pipelines** → open latest default-branch pipeline → **sbom** jobs green; download `sbom-*.cdx.json` artifacts |

### Expected output

- ClusterPolicies present; action **Audit**
- `sbom` matrix jobs succeed; CycloneDX artifacts non-empty
- Digest MR still only touches `gitops/envs/dev/values/*.yaml`

### Validation

```bash
kubectl get clusterpolicy
# Optional: cosign verify-attestation after rebuild
# cosign verify-attestation --type cyclonedx \
#   --certificate-identity-regexp 'https://gitlab.com/.+' \
#   --certificate-oidc-issuer https://gitlab.com \
#   "${IMAGE}"
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Policy not in cluster | AppSet exclude/path | Confirm file under `gitops/platform/kyverno/policies/*.yaml`; refresh app |
| sbom job fails attest | Sigstore/ECR referrers | Check job log; immutable tag collision treated as OK; network to Rekor |
| Digest MR skipped | No digest change | Expected if digests already current |

### Security notes

CI still must not gain `kubectl` / `argocd` (Topic 10 hard rule).

---

## Step 15.4: Flip signature verify to Enforce (after proof)

> **Apply after cluster rebuild.** Do this only when signed digests are what Argo deploys.

### Goal

Fail closed on unsigned Boutique ECR images.

### Why this step is required

Audit never blocks; Enforce is the real control.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"

# 1) Confirm a running/signed image verifies with cosign (docs/ci.md)
# 2) Edit policy:
#    validationFailureAction: Enforce
#    in gitops/platform/kyverno/policies/verify-image-signatures.yaml
# 3) Merge → Argo sync kyverno-policies

# Leave verify-sbom-attestation on Audit until attestations exist on all env digests,
# then optionally Enforce the same way.
```

### Expected output

Unsigned image creates are denied; signed digest pods admit.

### Validation

```bash
# Use tests/policy/unsigned-digest-pod.yaml.example with a real UNSIGNED digest
# Expect admission error naming verify-image-signatures
kubectl get events -n dev --field-selector reason=PolicyViolation | tail -20
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| All Boutique pods blocked | Bootstrap digests never signed | Run Topic 10+15 pipeline; promote signed digests; or temporarily Audit |
| Rollout stuck | Canary pod unsigned | Same as Deployments — fix digest in Git |

### Security notes

Never delete the ClusterPolicy to unblock prod; fix the image or temporarily Audit with an MR + CODEOWNERS awareness.

---

## Step 15.5: Topic validation (scaffold)

### Goal

Gate Topic 15 complete for **repo scaffold** (live Enforce optional until rebuild).

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"

test -f docs/setup/15-supply-chain-verify-sbom.md
test -f docs/adr/0007-admission-verify-and-sbom.md
test -f gitops/platform/kyverno/policies/verify-image-signatures.yaml
test -f gitops/platform/kyverno/policies/verify-sbom-attestation.yaml
grep -q 'stage: sbom' .gitlab-ci.yml
grep -q 'cyclonedx' .gitlab-ci.yml
grep -q '0007' docs/ci.md
make docs-check
```

### Expected output

All checks pass. `make docs-check` OK.

### Validation checklist

| Check | Scaffold | After rebuild |
|-------|----------|---------------|
| Policies in Git (Audit) | Required | Synced |
| CI `sbom` stage defined | Required | Jobs green |
| ADR-0007 present | Required | — |
| Signature **Enforce** | Deferred | After Step 15.4 |
| SBOM **Enforce** | Deferred | Optional later |

---

## Topic troubleshooting

| Symptom | Cause | Recovery |
|---------|-------|----------|
| Kyverno timeout on admit | No egress to Rekor / slow webhook | Check NP/egress; raise `webhookTimeoutSeconds` carefully |
| Audit noise in reports | Unsigned bootstrap images | Expected until CI digests replace them |
| `cosign attest` immutable collision | Re-attest same digest | Treated as success in CI |

## Related

- Contract: [`docs/ci.md`](../ci.md)
- Runbook: [`docs/runbooks/kyverno.md`](../runbooks/kyverno.md)
- Prior baseline: [07](07-security-baseline.md) · [10](10-gitlab-ci-digest.md)
