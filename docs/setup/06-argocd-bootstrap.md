# 06 — Argo CD bootstrap

Audience: L2 — Implementer  
Estimated time: 1.5–2 hours  
Prerequisites: [05 — Ingress, DNS, TLS](05-ingress-dns-tls.md) complete (**M1** HTTPS path working)  
Creates: Argo CD in `argocd` namespace; UI at `argocd.boutique.biroltilki.art`; root app-of-apps; platform + workload ApplicationSets; env namespace scaffolding under `gitops/envs/*`  
Related ADRs: [0001](../adr/0001-digest-only-gitops.md)  
Pins: Argo CD **v2.14.x** / Helm chart **7.8.14** ([docs/versions.md](../versions.md))

---

## Topic goal

Make **Git the deploy authority**: install Argo CD, connect the GitLab repo, and wire app-of-apps so platform components and env namespaces are reconciled — with **prod manual sync only**.

## Why this topic is required

Topics 07–14 assume Argo reconciles desired state from this repository. Without Argo (and without the prod manual-sync guardrail), digest promotion and CODEOWNERS cannot be enforced operationally.

## Before you begin

- Topic 05 controllers healthy; ACM ARN available.
- This repository is pushed to GitLab on branch `main` (or update `targetRevision` consistently).
- You have a GitLab Project Access Token or Deploy Token with `read_repository` (and `write` only if you choose HTTPS write — read is enough for Argo pull).
- Phase B files for Topic 06 present.

**Idempotent:** Helm upgrade and re-applying Applications are safe. Changing sync policy on prod to automated is **not** allowed.

---

## Step 6.1: Install Argo CD

### Goal

Install Argo CD via Helm using `gitops/bootstrap/argocd/values.yaml` (chart **7.8.14**).

### Why this step is required

Argo is the only cluster reconciler for GitOps (ADR-0001).

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"

export ACM_ARN=$(terraform -chdir=terraform/envs/prod output -raw acm_certificate_arn)
cp gitops/bootstrap/argocd/values.yaml /tmp/argocd-values.yaml
sed -i '' "s|<ACM_CERTIFICATE_ARN>|${ACM_ARN}|g" /tmp/argocd-values.yaml
# Linux: sed -i without ''

! grep -q '<ACM_CERTIFICATE_ARN>' /tmp/argocd-values.yaml

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --version 7.8.14 \
  --values /tmp/argocd-values.yaml \
  --wait

kubectl -n argocd get pods
kubectl -n argocd get ingress
```

Expected duration: 3–8 minutes (pods + ALB for UI).

### GUI instructions (if applicable)

N/A for install.

### Expected output

Pods Ready in `argocd`; Ingress for `argocd.boutique.biroltilki.art` has an ADDRESS (may take several minutes).

### Validation

```bash
kubectl -n argocd rollout status deploy/argocd-server
kubectl -n argocd get ingress -o wide
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Chart version missing | Repo cache | `helm repo update`; confirm 7.8.14 exists or pin nearest 7.8.x with appVersion 2.14.x |
| Ingress no ADDRESS | LB controller | Return to Topic 05 controller health |

### Recovery

`helm upgrade --install` again; check `kubectl -n argocd logs deploy/argocd-server`.

### Best practices

Prefer installing from the substituted `/tmp` values so the committed file can keep the placeholder for new clones — or commit the ARN if org policy allows.

### Security notes

Retrieve initial admin password next; rotate after first login. Never commit the password.

---

## Step 6.2: Expose and open Argo UI

### Goal

Reach https://argocd.boutique.biroltilki.art and log in as `admin`.

### Why this step is required

Operators need UI/CLI access for prod **manual** sync later.

### Commands

```bash
# Wait for DNS
dig +short argocd.boutique.biroltilki.art

kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d; echo

curl -I --max-time 30 https://argocd.boutique.biroltilki.art
```

Optional CLI login:

```bash
argocd login argocd.boutique.biroltilki.art --grpc-web
# username: admin · password: from secret above
```

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | Browser → Argo CD UI |
| Navigation | Open `https://argocd.boutique.biroltilki.art` |
| Permissions | Network path to ALB; admin secret access via kubectl |
| Verification | Login page loads with valid TLS |

| Field | Value | Why |
|-------|-------|-----|
| Username | `admin` | Default local user |
| Password | Value from `argocd-initial-admin-secret` | Bootstrap only |
| After login | **Settings → Accounts** (or CLI) to change password | Security |

### Expected output

HTTPS 200/302 to UI; successful admin login.

### Validation

```bash
curl -fsS -o /dev/null -w "%{http_code}\n" https://argocd.boutique.biroltilki.art
# expect 200 or 302
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| TLS error | ACM / DNS | Confirm external-dns record + ACM on ALB |
| 404/502 | Backend protocol | values use `backend-protocol: HTTP` + `server.insecure` |

### Recovery

Fix Ingress annotations; restart server pods; re-check DNS.

### Best practices

Bookmark the URL; store new admin password in a password manager.

### Security notes

Delete or rotate `argocd-initial-admin-secret` usage after password change. Restrict UI exposure later (IP allow / SSO) if the pilot becomes long-lived.

---

## Step 6.3: Register GitLab repository credential

### Goal

Let Argo CD clone this GitLab repository (HTTPS or SSH) without storing the token in Git.

### Why this step is required

Root app and ApplicationSets cannot sync private repos without credentials.

### Commands

**CLI option (HTTPS):**

```bash
# Create a GitLab Project Access Token: role Reporter+, scopes read_repository
# Store token only in memory / password manager — NEVER in the repo

export GITLAB_REPO_URL="https://gitlab.com/<GROUP>/<PROJECT>.git"
export GITLAB_USER="oauth2"   # or your username for PAT
export GITLAB_TOKEN="<TOKEN>" # not committed

argocd repo add "${GITLAB_REPO_URL}" \
  --username "${GITLAB_USER}" \
  --password "${GITLAB_TOKEN}" \
  --grpc-web
```

Unset token when done: `unset GITLAB_TOKEN`.

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | Argo CD UI |
| Navigation | **Settings** → **Repositories** → **Connect Repo** |
| Permissions | Argo admin |
| Verification | Repository appears **Successful** / Connection OK |

| Field | Value | Why |
|-------|-------|-----|
| Method | VIA HTTPS (or SSH) | Match your GitLab access |
| Project | Git URL of `boutique-eks-gitops` | Same URL used in Application manifests |
| Username | `oauth2` or GitLab username | PAT auth |
| Password | Project Access Token (`read_repository`) | Pull only |
| Name | optional label | Operator clarity |

**Create token in GitLab:**

| Element | Content |
|---------|---------|
| Platform | GitLab |
| Navigation | Project → **Settings** → **Access Tokens** → **Add new token** |
| Permissions | Maintainer to create project tokens |
| Verification | Token shown once; Argo connection Successful |

| Field | Value | Why |
|-------|-------|-----|
| Token name | `argocd-read` | Audit |
| Role | Reporter (or Developer) | Read repo |
| Scopes | `read_repository` | Least privilege |
| Expiration | Short-lived / calendar reminder | Rotate |

### Expected output

Argo lists the repo as connected successfully.

### Validation

```bash
argocd repo list --grpc-web
# or UI: Settings → Repositories → Successful
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Authentication failed | Bad token / URL | Regenerate PAT; use exact HTTPS URL |
| 404 | Wrong project path | Copy clone URL from GitLab UI |

### Recovery

Remove failed repo entry; re-add; rotate leaked tokens immediately.

### Best practices

Prefer project access tokens over personal tokens; document rotation owner.

### Security notes

**Never** commit tokens, `repocreds` manifests with secrets, or put PATs in `values.yaml`.

---

## Step 6.4: Apply root app-of-apps

### Goal

Create the `root` Application that syncs `gitops/apps`.

### Why this step is required

ApplicationSets for platform and workloads are loaded through the root app hierarchy.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"

export GITLAB_REPO_URL="https://gitlab.com/<GROUP>/<PROJECT>.git"

cp gitops/bootstrap/root/application.yaml /tmp/root-app.yaml
sed -i '' "s|<GITLAB_REPO_URL>|${GITLAB_REPO_URL}|g" /tmp/root-app.yaml
# Also substitute in ApplicationSets before they sync (Step 6.5) — do this in Git:

# Recommended: commit substituted URLs to a private fork OR use sed locally and
# push to main so Argo reads the same URL. For pilot, edit files in repo:

# gitops/bootstrap/root/application.yaml
# gitops/apps/platform-apps/applicationset.yaml
# gitops/apps/workload-apps/applicationset.yaml

kubectl apply -f /tmp/root-app.yaml
argocd app get root --grpc-web || kubectl -n argocd get app root
```

**Required:** set `directory.recurse: true` on the root Application so nested ApplicationSets under `gitops/apps/*/ ` are discovered (Argo directory apps do not recurse by default).

Ensure `<GITLAB_REPO_URL>` is replaced **in the Git revision Argo tracks** for ApplicationSets (push to `main`). Then hard-refresh root so it is not stuck on an old commit:

```bash
kubectl -n argocd annotate app root argocd.argoproj.io/refresh=hard --overwrite
kubectl -n argocd get app root -o jsonpath='{.status.sync.revision}{"\n"}'
```

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | Argo CD UI |
| Navigation | **Applications** → find **root** |
| Verification | Sync status progresses to **Synced/Healthy** (or Progressing while children create) |

### Expected output

Application `root` exists; sync succeeds; child ApplicationSets appear.

### Validation

```bash
kubectl -n argocd get application root
kubectl -n argocd get applicationset
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| ComparisonError / repo | Credential missing | Step 6.3 |
| Placeholder URL left | Forgot sed/commit | Replace `<GITLAB_REPO_URL>` in Git |
| Root Synced but no ApplicationSets | Directory not recursive / stale revision | Add `directory.recurse: true`; push; `kubectl annotate app root … refresh=hard`; confirm revision is latest `main` |

### Recovery

Fix URL/credential; `argocd app sync root`.

### Best practices

Keep root automated with prune/selfHeal so ApplicationSets stay defined.

### Security notes

Root only manages Argo CRDs in `argocd` namespace + child apps — still protect who can edit `gitops/apps`.

---

## Step 6.5: Platform + workload ApplicationSets

### Goal

Confirm `platform-apps` and `workload-apps` ApplicationSets generate Applications and sync.

### Why this step is required

Platform Helm releases move under Argo; env namespaces become GitOps-managed.

### Commands

```bash
# After URLs are committed on main:
kubectl -n argocd get applicationset platform-apps workload-apps -o yaml | head -80
kubectl -n argocd get applications

# Expect apps such as:
# aws-load-balancer-controller, external-dns, cert-manager
# boutique-dev, boutique-stage, boutique-prod

argocd app list --grpc-web
```

If ApplicationSets were applied via root but generators failed, inspect:

```bash
kubectl -n argocd describe applicationset platform-apps
kubectl -n argocd describe applicationset workload-apps
```

**Helm ownership note:** First Argo sync may adopt existing Helm releases (Topic 05). If conflict occurs, use `ServerSideApply` (already set) or temporarily `helm uninstall` only after Argo app is ready to recreate — prefer adopt/sync carefully; ask partner if unsure.

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | Argo CD UI |
| Navigation | **Applications** → filter platform / boutique-* |
| Verification | Platform apps Healthy; `boutique-dev`/`stage` Synced; `boutique-prod` may be Unknown/OutOfSync until **manual** sync |

### Expected output

Three platform apps + three boutique env apps listed.

### Validation

```bash
kubectl -n argocd get app aws-load-balancer-controller external-dns cert-manager
kubectl -n argocd get app boutique-dev boutique-stage boutique-prod
kubectl get ns dev stage prod
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Multi-source Helm error | Chart repo / values path | Check ApplicationSet elements; values placeholders from Topic 05 must be filled |
| Env app empty/error | Missing namespace.yaml | Confirm Topic 06 env files exist on `main` |

### Recovery

Fix Git; refresh apps; sync platform first (wave 10), then workloads (wave 40).

### Best practices

Sync platform apps to Healthy before trusting workload namespaces.

### Security notes

Do not add `automated` sync to prod via UI — next step verifies absence.

---

## Step 6.6: Verify prod has no automated sync

### Goal

Prove prod apps lack `syncPolicy.automated` while dev/stage have it.

For this repo’s ApplicationSets that means:
- Workloads: `frontend-prod` (and other `*-prod`) have no automated sync
- Namespace apps: `boutique-prod-ns` has no automated sync (dev/stage ns apps may automate)

### Why this step is required

Locked production safety: CODEOWNERS + manual sync (plan FR-03).

### Commands

```bash
kubectl -n argocd get app boutique-dev -o jsonpath='{.spec.syncPolicy.automated}{"\n"}'
kubectl -n argocd get app boutique-stage -o jsonpath='{.spec.syncPolicy.automated}{"\n"}'
kubectl -n argocd get app boutique-prod -o jsonpath='{.spec.syncPolicy.automated}{"\n"}'
# prod must print empty / null
```

Manually sync prod once for namespace scaffolding:

```bash
argocd app sync boutique-prod --grpc-web
# or UI: Application boutique-prod → SYNC
```

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | Argo CD UI |
| Navigation | **boutique-prod** → **Details** → **Sync Policy** |
| Verification | Automated sync **disabled**; enable button not left on |
| Permissions | Argo admin |

### Expected output

dev/stage show automated prune/selfHeal; prod automated **absent**. Manual sync creates `prod` namespace.

### Validation

```bash
test -z "$(kubectl -n argocd get app boutique-prod -o jsonpath='{.spec.syncPolicy.automated}')" && echo "prod manual: OK"
kubectl get ns prod
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Prod has automated | templatePatch bug / UI toggle | Fix ApplicationSet; hard refresh; disable auto in UI |

### Recovery

Revert any UI enablement of prod auto-sync immediately; fix Git generator.

### Best practices

Screenshot or save jsonpath output as evidence for Topic 13 checklist.

### Security notes

Enabling prod auto-sync is a **severity** incident for this pilot — treat as config error.

---

## Step 6.7: Topic validation (gate to Topic 07)

### Goal

Confirm Argo control plane and GitOps hierarchy are ready for security baseline apps.

### Why this step is required

Topic 07 adds Kyverno/ESO via the same platform ApplicationSet pattern (wave 20).

### Commands

```bash
kubectl -n argocd get pods
curl -fsS -o /dev/null -w "%{http_code}\n" https://argocd.boutique.biroltilki.art
kubectl -n argocd get applicationset
kubectl -n argocd get app
test -f gitops/apps/README.md
```

### GUI instructions (if applicable)

UI shows root + platform + workload apps without persistent Unknown on platform.

### Expected output

Checklist below all pass.

### Validation

- [ ] Argo Helm release installed (6.1)
- [ ] UI HTTPS works; admin password rotated/stored (6.2)
- [ ] GitLab repo credential Successful (6.3)
- [ ] `root` Application Synced (6.4)
- [ ] Platform apps Healthy (6.5)
- [ ] `boutique-dev` / `boutique-stage` automated; **`boutique-prod` manual** (6.6)
- [ ] Namespaces `dev`/`stage`/`prod` exist
- [ ] No GitLab token in Git history

### Common problems

Any failure — fix before Topic 07 policies.

### Recovery

Re-run the failing step; do not add Kyverno on a broken Argo.

### Best practices

Commit ApplicationSet URL substitutions on `main` so clones match cluster.

### Security notes

Confirm CI still has **no** kubeconfig deploy path (ADR-0001).

---

## Topic validation (end-to-end)

Topic 06 is complete when Step 6.7 checklist passes.

**Cost check:** Argo UI ALB shares ingress pattern; no extra NAT. Leave Argo running for subsequent topics.

---

## Topic troubleshooting

| Area | Symptom | Action |
|------|---------|--------|
| AppSet | Invalid Spec | `kubectl describe applicationset` — often URL placeholder or goTemplate |
| Helm adopt | “resource already exists” | Server-side apply / adopt; avoid duplicate Helm+Argo ownership long-term |
| Repo | SSH vs HTTPS mismatch | Use one scheme everywhere (apps + credential) |
| Prod | Accidental auto-sync | Disable immediately; document incident |

---

## Next step

**[07 — Security baseline](07-security-baseline.md)** (Phase B next).

Add Kyverno, External Secrets, and NetworkPolicies under `gitops/platform/` and extend `platform-apps` ApplicationSet (wave **20**).
