# 16 — CI security gates (Checkov, Gitleaks, policy tests)

Audience: L2 — Implementer  
Estimated time: 1–1.5 hours (scaffold now; live gates when CI is re-enabled)  
Prerequisites: Topic [10](10-gitlab-ci-digest.md) files present; Topic [15](15-supply-chain-verify-sbom.md) optional but recommended  
Creates: `.checkov.yaml`, `.gitleaks.toml`, `tests/policy/unit/**`, CI jobs `gitleaks` / `checkov` / `policy_test`; optional `ENABLE_REPO_GATES`  
Related: [`docs/ci.md`](../ci.md) · Topic [07](07-security-baseline.md) policies  
Pins: Gitleaks **8.21.2** · Checkov **3.2.334** · Kyverno CLI **1.13.4** ([docs/versions.md](../versions.md))

---

## Topic goal

Add **repo security gates** in the GitLab `test` stage: secret scanning (**Gitleaks**), Terraform IaC scanning (**Checkov**), and offline **Kyverno CLI** policy unit tests — without changing digest-only deploy rules or requiring a live cluster to *author* the files.

## Why this topic is required

Helm lint alone does not catch leaked secrets, risky Terraform defaults, or broken admission policies before merge. Topic 07 only proves policies live on the cluster; unit tests catch regressions in MRs.

## Before you begin

**Scaffold-only (no AWS):**

- Confirm Creates files exist; run local commands in Step 16.1 if CLIs are installed.

**Apply when CI runs again:**

- Either `ENABLE_PILOT_CI=true` (full pipeline after rebuild), or  
- `ENABLE_REPO_GATES=true` for **MR-only** test-stage jobs **without** AWS/ECR (Topic 16 Step 16.4).

**Idempotent:** Re-running scanners is safe. Checkov ships with `soft_fail: true` until you baseline findings.

---

## Step 16.1: Confirm scaffold files

### Goal

Prove Topic 16 artifacts are in Git.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"

test -f .checkov.yaml
test -f .gitleaks.toml
test -f tests/policy/unit/kyverno-test.yaml
test -f docs/setup/16-ci-security-gates.md
grep -q 'gitleaks:' .gitlab-ci.yml
grep -q 'checkov:' .gitlab-ci.yml
grep -q 'policy_test:' .gitlab-ci.yml
grep -q 'ENABLE_REPO_GATES' .gitlab-ci.yml
```

### Expected output

All commands exit 0.

### Validation

```bash
grep -E 'GITLEAKS_VERSION|CHECKOV_VERSION|KYVERNO_CLI_VERSION' .gitlab-ci.yml
make docs-check
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| File missing | Branch not updated | Pull/merge Topic 16 commit |

---

## Step 16.2: Run gates locally (optional)

### Goal

Exercise the same tools CI will use, without GitLab runners.

### Why this step is required

Faster feedback before enabling pipeline variables.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"

# Gitleaks (if installed)
gitleaks detect --source . --config .gitleaks.toml --verbose --redact

# Checkov (if installed) — soft_fail means exit 0 even with findings
checkov --config-file .checkov.yaml --directory terraform

# Kyverno CLI (if installed)
kyverno test tests/policy/unit
```

### Expected output

- Gitleaks: no leaks (or only allowlisted paths)
- Checkov: report printed; exit 0 while soft_fail is true
- Kyverno: all declared results match (deny latest / missing digest **fail**; digest-pinned **pass**)

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Gitleaks hits docs placeholders | Allowlist gap | Extend `.gitleaks.toml` paths/regexes carefully |
| Kyverno test path error | CWD wrong | Run from repo root |
| Checkov fails hard | soft_fail flipped early | Restore `soft_fail: true` or add skip-check IDs |

### Security notes

Never allowlist real credentials — only placeholders and example paths.

---

## Step 16.3: Understand Checkov soft-fail baseline

### Goal

Know when to harden IaC scanning.

### Why this step is required

Pilot Terraform intentionally trades some CIS controls for cost (single NAT, etc.). Soft-fail avoids blocking Phase 12 scaffolds.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"
grep -A20 'skip-check' .checkov.yaml
grep soft_fail .checkov.yaml
```

### After rebuild (manual)

1. Review `results_json.json` from CI artifacts.
2. Keep only justified `skip-check` entries; document each in architecture/cost notes.
3. Set `soft_fail: false` in `.checkov.yaml` when the baseline is accepted.

---

## Step 16.4: Enable gates in GitLab (no cluster required for MR gates)

> **Apply when you want CI feedback.** Does not require EKS. Full build/sign still needs Topic 04 AWS + `ENABLE_PILOT_CI`.

### Goal

Run `helm_lint`, `gitleaks`, `checkov`, and `policy_test` on merge requests.

### Commands / GUI

| Element | Content |
|---------|---------|
| Platform | GitLab |
| Navigation | **Settings** → **CI/CD** → **Variables** → **Add variable** |
| Permissions | Maintainer |

| Key | Value | Notes |
|-----|-------|-------|
| `ENABLE_REPO_GATES` | `true` | MR pipelines only (workflow rule). No AWS needed. |
| `ENABLE_PILOT_CI` | `true` | After rebuild — full pipeline including build/scan/sign/sbom/gitops |

Open an MR that touches any file; confirm test-stage jobs run.

### Expected output

Pipeline created on MR; four test jobs green (Checkov may show findings but pass while soft_fail).

### Validation

```text
GitLab → CI/CD → Pipelines → MR pipeline → gitleaks / checkov / policy_test / helm_lint = passed
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| No pipeline | Both ENABLE_* unset | Set `ENABLE_REPO_GATES=true` for MR gates |
| Build jobs fail on main | `ENABLE_PILOT_CI` without AWS | Keep pilot CI off until Topic 04 restored |
| policy_test download fail | GitHub rate limit / pin | Retry; confirm `KYVERNO_CLI_VERSION` release exists |

### Security notes

`ENABLE_REPO_GATES` must **not** grant AWS keys. Build jobs still use OIDC only when `ENABLE_PILOT_CI` is on.

---

## Step 16.5: Topic validation (scaffold)

### Goal

Mark Topic 16 complete for in-repo scaffold.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"

test -f docs/setup/16-ci-security-gates.md
test -f .checkov.yaml && test -f .gitleaks.toml
test -f tests/policy/unit/kyverno-test.yaml
grep -q 'policy_test:' .gitlab-ci.yml
grep -q 'Gitleaks' docs/ci.md
make docs-check
```

### Validation checklist

| Check | Scaffold | When CI enabled |
|-------|----------|-----------------|
| Configs + unit tests in Git | Required | — |
| CI jobs defined | Required | Jobs green on MR |
| Checkov soft_fail | Default true | Flip after baseline |
| `ENABLE_REPO_GATES` documented | Required | Optional use |

---

## Topic troubleshooting

| Symptom | Cause | Recovery |
|---------|-------|----------|
| Gitleaks false positive in runbook | Example secret-shaped string | Path/regex allowlist with review |
| Kyverno CLI vs cluster version skew | Pin drift | Align `KYVERNO_CLI_VERSION` toward cluster Kyverno minor when possible |
| Checkov noise | New module | Add skip with comment or fix Terraform |

## Related

- Contract: [`docs/ci.md`](../ci.md)
- Policies under test: [`gitops/platform/kyverno/policies/`](../../gitops/platform/kyverno/policies/)
- Pre-commit: [`.pre-commit-config.yaml`](../../.pre-commit-config.yaml) (gitleaks hook)
- Prior: [10](10-gitlab-ci-digest.md) · [15](15-supply-chain-verify-sbom.md)
