# 17 — Argo CD hardening (AppProjects, SSO, notifications)

Audience: L2 — Implementer  
Estimated time: 1.5–2 hours (scaffold now; live apply after Topic 06 on rebuild)  
Prerequisites: [06 — Argo CD bootstrap](06-argocd-bootstrap.md) complete on a rebuilt cluster (or scaffold-only in this repo)  
Creates: AppProjects under `gitops/bootstrap/argocd/hardening/projects/`; SSO/notifications/RBAC **examples**; ApplicationSets wired to named projects; [ADR-0008](../adr/0008-argocd-appprojects-sso.md)  
Related ADRs: [0001](../adr/0001-digest-only-gitops.md) · [0008](../adr/0008-argocd-appprojects-sso.md)  
Pins: Argo CD **v2.14.x** / chart **7.8.14** ([docs/versions.md](../versions.md))

---

## Topic goal

Harden Argo CD for a fuller GitOps control plane: separate **AppProjects** for platform vs Boutique workloads, and prepare **SSO (Dex + GitLab)** and **Notifications** as merge-ready examples — without enabling IdP/alerts until secrets exist.

## Why this topic is required

The pilot used `project: default` and local `admin`. Named projects limit where apps can deploy; SSO removes shared passwords; notifications surface sync failures. Scaffolding now avoids re-designing this on the next rebuild.

## Before you begin

**Scaffold-only:**

- Confirm files under Creates exist; Dex/notifications stay **disabled** in `values.yaml`.

**Apply after cluster rebuild (after Topic 06):**

- Argo CD healthy; Git repo registered.
- Ability to `argocd app sync` / kubectl into `argocd` namespace.

**Critical ordering:** AppProjects must exist **before** Applications that reference `boutique-platform` / `boutique-workloads`. Sync waves help but are not a guarantee across apps — follow Step 17.3.

**Idempotent:** Re-syncing AppProjects is safe. Enabling Dex without a valid OAuth app locks users out of SSO (keep local admin until proven).

---

## Step 17.1: Confirm scaffold files

### Goal

Prove Topic 17 artifacts are in Git.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"

test -f docs/setup/17-argocd-hardening.md
test -f docs/adr/0008-argocd-appprojects-sso.md
test -f gitops/bootstrap/argocd/hardening/projects/boutique-platform.yaml
test -f gitops/bootstrap/argocd/hardening/projects/boutique-workloads.yaml
test -f gitops/bootstrap/argocd/hardening/sso/values-dex-gitlab.yaml.example
test -f gitops/bootstrap/argocd/hardening/notifications/values-notifications.yaml.example
grep -q 'boutique-platform' gitops/apps/platform-apps/applicationset.yaml
grep -q 'boutique-workloads' gitops/apps/workload-apps/boutique-applicationset.yaml
grep -q 'argocd-hardening' gitops/apps/platform-apps/applicationset-manifests.yaml
grep -E 'dex:|enabled: false' -A1 gitops/bootstrap/argocd/values.yaml | head -20
```

### Expected output

All `test`/`grep` succeed. Live `values.yaml` still has `dex.enabled: false` and `notifications.enabled: false`.

### Validation

```bash
grep 'project:' gitops/apps/platform-apps/applicationset.yaml \
  gitops/apps/workload-apps/*.yaml \
  gitops/apps/platform-apps/applicationset-manifests.yaml
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Still `project: default` on workloads | Branch outdated | Pull Topic 17 changes |

---

## Step 17.2: Review AppProject boundaries

### Goal

Understand platform vs workload blast-radius limits.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"
grep -A30 'destinations:' gitops/bootstrap/argocd/hardening/projects/boutique-workloads.yaml
grep -A20 'clusterResourceWhitelist' gitops/bootstrap/argocd/hardening/projects/boutique-workloads.yaml
```

### Expected output

Workloads destinations are only `dev` / `stage` / `prod`; `clusterResourceWhitelist` is empty; Rollout kinds allowed.

### Security notes

Do not add `*` cluster resources to `boutique-workloads`. Platform chart installs that need CRDs stay on `boutique-platform`.

---

## Step 17.3: Apply after rebuild — sync AppProjects first

> **Apply after cluster rebuild (after Topic 06).** Skip if no cluster.

### Goal

Create AppProjects before other apps reconcile against them.

### Commands

```bash
# Option A — let ApplicationSet create argocd-hardening (project: default), then sync it first
argocd app sync argocd-hardening --grpc-web
kubectl -n argocd get appprojects

# Option B — kubectl apply directly from Git (break-glass / first boot)
kubectl apply -f gitops/bootstrap/argocd/hardening/projects/

# Then refresh platform + workload apps
argocd app sync platform-apps --grpc-web || true
argocd app list -o wide | head -40
```

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | Argo CD UI |
| Navigation | Settings → **Projects** → confirm **boutique-platform** and **boutique-workloads** |
| Navigation | Applications → filter by project |

### Expected output

```text
NAME                 ...
boutique-platform
boutique-workloads
```

Child apps show `Project` column as named projects (not only `default`).

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Application invalid project | Projects not synced yet | Step 17.3 Option A/B first |
| Workload sync denied kind | Allowlist missing CR | Add kind to `boutique-workloads` via MR |
| Platform app destination denied | Namespace not listed | Extend `boutique-platform` destinations |

### Security notes

Root Application may remain on `default` — that is intentional for bootstrapping.

---

## Step 17.4: SSO (Dex + GitLab) — prepare only

> **Do not enable on first rebuild day** unless OAuth app + secrets are ready.

### Goal

Register IdP pieces and know the merge path.

### GUI instructions

| Element | Content |
|---------|---------|
| Platform | GitLab |
| Navigation | Group/Application → **Applications** → **Add new application** |
| Redirect URI | `https://argocd.boutique.biroltilki.art/api/dex/callback` |
| Scopes | `read_user`, `openid` (and groups if required by your GitLab) |

Store `clientID` / `clientSecret` in `argocd-secret` (keys `dex.gitlab.clientID`, `dex.gitlab.clientSecret`) via kubectl or ExternalSecret — **never commit**.

### Commands (after secrets exist)

```bash
cd "$(git rev-parse --show-toplevel)"

# Review example — edit REPLACE_* and group names
less gitops/bootstrap/argocd/hardening/sso/values-dex-gitlab.yaml.example

# Helm upgrade with extra values file (cluster must be up)
helm upgrade argocd argo/argo-cd -n argocd --version 7.8.14 \
  --values gitops/bootstrap/argocd/values.yaml \
  --values gitops/bootstrap/argocd/hardening/sso/values-dex-gitlab.yaml.example \
  --wait
```

### Validation

Login UI shows **GitLab**; local `admin` still works until you remove password login.

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Dex crashloop | Bad client secret / redirect | Fix Secret; check Dex logs |
| User readonly only | RBAC groups mismatch | Align `policy.csv` with GitLab group claims |

---

## Step 17.5: Notifications — prepare only

### Goal

Know how to enable sync-failure alerts later.

### Commands

```bash
less gitops/bootstrap/argocd/hardening/notifications/values-notifications.yaml.example
less gitops/bootstrap/argocd/hardening/notifications/configmap.example.yaml
```

Enable only after creating `argocd-notifications-secret` (Slack token or SMTP). Prefer starting with **sync failed** triggers only.

### Security notes

Do not commit webhook tokens. Reuse ESO patterns from Topic 07/08 where possible.

---

## Step 17.6: Topic validation (scaffold)

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"

test -f docs/setup/17-argocd-hardening.md
test -f docs/adr/0008-argocd-appprojects-sso.md
test -f gitops/bootstrap/argocd/hardening/projects/boutique-platform.yaml
grep -q 'project: boutique-workloads' gitops/apps/workload-apps/boutique-applicationset.yaml
grep -q 'enabled: false' gitops/bootstrap/argocd/values.yaml
make docs-check
```

### Validation checklist

| Check | Scaffold | After rebuild |
|-------|----------|---------------|
| AppProjects in Git | Required | Synced |
| AppSets use named projects | Required | Apps healthy |
| Dex/notifications disabled in live values | Required | Enable only via examples |
| ADR-0008 | Required | — |

---

## Topic troubleshooting

| Symptom | Cause | Recovery |
|---------|-------|----------|
| Mass app failure after Topic 17 merge | Projects missing on live cluster | kubectl apply projects; sync `argocd-hardening` |
| Cannot sync prod | Expected manual sync | Not an AppProject issue |
| Example RBAC applied by mistake | Synced wrong path | Only `hardening/projects` is directory-synced |

## Related

- Bootstrap: [`gitops/bootstrap/argocd/README.md`](../../gitops/bootstrap/argocd/README.md)
- Hardening index: [`gitops/bootstrap/argocd/hardening/README.md`](../../gitops/bootstrap/argocd/hardening/README.md)
- Prior: [06](06-argocd-bootstrap.md)
