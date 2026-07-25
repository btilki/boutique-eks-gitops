# 01 — Prerequisites

Audience: L2 — Implementer  
Estimated time: 60–90 minutes  
Prerequisites: None  
Creates: Verified local toolchain; GitLab project (created if missing); local Git repo linked to that remote; confirmed AWS / Route53 / SMTP access (no new AWS billables from this topic). Repo file: [`docs/versions.md`](../versions.md)  
Related ADRs: None yet (authored in Topic 02)

---

## Topic goal

Prove that your workstation and cloud/SaaS access are ready before any repository foundation or Terraform apply. After this topic you can install CLIs to the pinned versions, authenticate to AWS, confirm **DNS (Domain Name System)** via the Route53 zone `biroltilki.art`, have a GitLab project with a linked local Git repository, and know an **SMTP (Simple Mail Transfer Protocol)** mailbox exists for later Alertmanager tests.

## Why this topic is required

OIDC, DNS, and email failures surface late (Topics 04, 05, 08, 10) and waste paid cluster time. Front-loading access and version checks keeps Topics 02+ deterministic and avoids “works on my machine” drift against [`docs/versions.md`](../versions.md).

## Before you begin

- Use macOS or Linux (or Windows **WSL2**). Commands below assume bash/zsh.
- You need permission to install CLI tools on your machine (Homebrew, package manager, or corporate-approved binaries).
- Have credentials ready for: AWS (admin or equivalent for later VPC/EKS/IAM), GitLab (ability to **create** a project in your group/namespace, or Maintainer/Owner on an existing one), and access to the Route53 zone `biroltilki.art`.
- **Do not** run `terraform apply`, create EKS, or spend on NAT/ALB in this topic.
- Keep secrets out of the repo: no AWS keys, GitLab tokens, or SMTP passwords committed.
- If you only have a local working tree (Phase B files, no `.git/` and no GitLab project yet), that is expected: Steps **1.8** and **1.10** create them.

**Idempotent:** Re-running verification commands is safe. Skip create/init substeps when the project or `.git/` already exists.

---

## Step 1.1: Confirm OS / shell and open the repository

### Goal

Confirm a supported shell and that you are working inside the `boutique-eks-gitops` repository.

### Why this step is required

Later steps assume Unix paths and that relative docs paths (`docs/setup/…`) resolve from the repo root.

### Commands

```bash
uname -s
echo "$SHELL"
pwd
ls -la
test -f docs/setup/README.md && echo "setup index: OK"
test -f docs/versions.md && echo "versions: OK"
```

**Path A — GitLab remote already exists:** clone (or open) it:

```bash
git clone <GITLAB_REPO_HTTPS_OR_SSH_URL> boutique-eks-gitops
cd boutique-eks-gitops
```

Replace `<GITLAB_REPO_HTTPS_OR_SSH_URL>` with your project clone URL. Do not invent a public URL.

**Path B — No remote and/or no local Git yet (common after Phase B authoring):** stay in the working tree that already contains `docs/setup/` and `docs/versions.md`. Create the GitLab project in **Step 1.8**; run `git init` and first push in **Step 1.10**. Do not invent a clone URL here.

### GUI instructions (if applicable)

N/A for local shell. For clone via GitLab UI (Path A only):

| Element | Value |
|---------|--------|
| Platform | GitLab |
| Navigation | Project → **Clone** button → copy HTTPS or SSH URL |
| Permissions | Guest can clone public; private needs at least Reporter |
| Verification | Clone URL appears; `git clone` succeeds |

### Expected output

- `uname` shows `Darwin` or `Linux`
- `setup index: OK` and `versions: OK`
- Repo root contains `README.md`, `ROADMAP.md`, `docs/`

### Validation

```bash
test -f ROADMAP.md && test -f docs/ARCHITECTURE.md && echo "repo spine: OK"
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `versions: OK` missing | Topic 01 files not present | Ensure Phase B Topic 01 was merged/copied into your working tree |
| Wrong directory | Nested clone path | `cd` to directory that contains `docs/setup/` |

### Recovery

Re-clone or `cd` to the correct root. No cloud rollback needed.

### Best practices

Always run Setup Guide commands from the **repository root** unless a step says otherwise.

### Security notes

Prefer SSH clone with a passphrase-protected key, or HTTPS with a short-lived token — never paste PATs into tracked files.

---

## Step 1.2: Install / verify AWS CLI

### Goal

Install AWS CLI v2 and confirm it runs.

### Why this step is required

Topics 03–14 use AWS CLI for identity, EKS kubeconfig, ECR, and orphan audits.

### Commands

**macOS (Homebrew):**

```bash
brew install awscli
aws --version
```

**Linux (official installer pattern):**

```bash
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -o /tmp/awscliv2.zip -d /tmp
sudo /tmp/aws/install --update
aws --version
```

For ARM Linux, use the aarch64 package from AWS docs instead of `x86_64`.

### GUI instructions (if applicable)

N/A.

### Expected output

Version string starting with `aws-cli/2.…` (v2.x).

### Validation

```bash
aws --version | head -1
```

Must report **aws-cli/2**.

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `aws-cli/1.…` | Old v1 install ahead on `PATH` | Install v2; ensure `which aws` points to v2 |
| `command not found` | Install failed / PATH | Restart shell; verify `/usr/local/bin` or brew prefix |

### Recovery

Reinstall v2; remove conflicting v1 packages per your OS.

### Best practices

Use named profiles (`AWS_PROFILE`) rather than exporting long-lived keys in shell rc files when possible.

### Security notes

Do not commit `~/.aws/credentials`. Prefer SSO / IAM Identity Center if your org supports it.

---

## Step 1.3: Install / verify Terraform ≥ 1.9

### Goal

Install Terraform and prove version ≥ 1.9.

### Why this step is required

Foundation modules and the S3 backend assume Terraform 1.9+ ([`docs/versions.md`](../versions.md)).

### Commands

**macOS (Homebrew):**

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
terraform version
```

**tfenv (any OS with tfenv):**

```bash
tfenv install 1.9.8
tfenv use 1.9.8
terraform version
```

Pick any **1.9.x** or newer 1.x that is ≥ 1.9.0. Record the exact version you use in your session notes.

### GUI instructions (if applicable)

N/A.

### Expected output

`Terraform v1.9.…` or higher (e.g. `v1.10.x`).

### Validation

```bash
terraform version -json | jq -r '.terraform_version'
```

Confirm the printed version is **≥ 1.9.0**.

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `v1.5.x` / `< 1.9` | Old binary | Upgrade via brew/tfenv |
| `jq: command not found` | jq not installed yet | Install jq in Step 1.5, or visually read `terraform version` |

### Recovery

Uninstall old binary; reinstall ≥ 1.9; re-open terminal.

### Best practices

Pin the same minor in CI later; workstation can be 1.9.x while modules declare `>= 1.9`.

### Security notes

Install Terraform only from HashiCorp-distributed channels (brew tap, official zip, tfenv checksums).

---

## Step 1.4: Install / verify kubectl 1.31.x and Helm 3.16.x

### Goal

Install cluster clients matching the pin matrix: kubectl **1.31.x**, Helm **3.16.x**.

### Why this step is required

kubectl should stay within one minor of EKS **1.31**. Helm 3.16.x matches platform chart workflows in later topics.

### Commands

**macOS (Homebrew) — kubectl:**

```bash
brew install kubectl@1.31
# or: brew install kubernetes and verify version is 1.31.x
kubectl version --client
```

If brew does not offer `kubectl@1.31`, download the 1.31.x binary from Kubernetes release artifacts for your OS/arch and place it on `PATH`.

**macOS (Homebrew) — Helm:**

```bash
brew install helm
helm version
```

If Helm is newer than 3.16.x and your org requires exact minor, install 3.16.x via official Helm release tarball:

```bash
# Example pattern — replace ARCH with darwin-arm64 or darwin-amd64
curl -fsSL -o /tmp/helm.tgz https://get.helm.sh/helm-v3.16.4-darwin-arm64.tar.gz
tar -xzf /tmp/helm.tgz -C /tmp
sudo mv /tmp/darwin-arm64/helm /usr/local/bin/helm
helm version
```

Adjust OS/arch and patch version within **3.16.x**.

**Linux:** use distribution packages or official release binaries for kubectl 1.31.x and Helm 3.16.x.

### GUI instructions (if applicable)

N/A.

### Expected output

- kubectl client: `v1.31.…`
- Helm: `v3.16.…`

### Validation

```bash
kubectl version --client -o yaml | grep -E 'gitVersion:'
helm version --short
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| kubectl `v1.30` / `v1.32` only | Default brew package drift | Install explicit 1.31.x binary |
| Helm `v3.17+` | Brew latest | Accept if team agrees, or pin 3.16.x tarball; document deviation |

### Recovery

Replace binaries on `PATH`; verify with validation commands.

### Best practices

Match kubectl minor to EKS; patch-level differences are fine.

### Security notes

Download kubectl/Helm only from official Kubernetes/Helm release URLs; verify checksums when your org requires it.

---

## Step 1.5: Install / verify git, jq, curl (and optional Trivy/cosign)

### Goal

Ensure baseline utilities exist; optionally install Trivy **0.71.0** and cosign **2.4.x** for local experiments (CI will pin them in Topic 10).

### Why this step is required

Validation snippets and smoke curls depend on git/jq/curl. Supply-chain CLIs are optional locally but must match pins if you install them now.

### Commands

**macOS:**

```bash
brew install git jq curl
git --version
jq --version
curl --version | head -1
```

**Optional — Trivy 0.71.0:**

```bash
# Example: verify after install method of choice
trivy version
# Expect Version: 0.71.0
```

**Optional — cosign 2.4.x:**

```bash
cosign version
# Expect v2.4.x
```

If optional tools are skipped, note that in your confirmation message — Topic 10 installs them in CI regardless.

### GUI instructions (if applicable)

N/A.

### Expected output

git, jq, and curl print versions without error.

### Validation

```bash
command -v git && command -v jq && command -v curl && echo "utils: OK"
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Ancient system git | PATH order | Prefer brew git |

### Recovery

Reinstall via package manager.

### Best practices

Skip local Trivy/cosign if you only need CI — reduces version skew.

### Security notes

Do not embed registry credentials in shell history demos; use short-lived auth.

---

## Step 1.6: AWS identity check

### Goal

Authenticate to the target AWS account and print caller identity.

### Why this step is required

Topics 03–04 create state buckets, VPC, and EKS in this account. Wrong account = wasted spend and security incidents.

### Commands

Configure credentials using your org’s method (SSO example):

```bash
aws configure sso
# follow prompts: SSO start URL, region eu-central-1, account, role
aws sts get-caller-identity
aws configure get region || true
export AWS_REGION=eu-central-1
export AWS_DEFAULT_REGION=eu-central-1
aws sts get-caller-identity --region eu-central-1
```

**Access key profile (if SSO unavailable):**

```bash
aws configure --profile boutique-pilot
# enter Access Key ID, Secret, region eu-central-1, output json
AWS_PROFILE=boutique-pilot aws sts get-caller-identity
```

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | AWS IAM Identity Center (SSO) **or** IAM console |
| Navigation (SSO) | Your org SSO portal → AWS account → role → **Command line or programmatic access** → copy env vars / profile instructions |
| Navigation (keys) | IAM → Users → Security credentials → Create access key (**emergency only**) |
| Permissions | Permission to view account and later create VPC/EKS/IAM (admin recommended for pilot) |
| Verification | `get-caller-identity` returns `Account`, `Arn`, `UserId` |

| Field (SSO configure) | Value | Why |
|-----------------------|-------|-----|
| SSO session / start URL | Your org URL | IdP entry |
| SSO region | As provided by org | Token endpoint |
| CLI default region | `eu-central-1` | Locked project region |
| CLI profile name | e.g. `boutique-pilot` | Stable local reference |

### Expected output

JSON similar to:

```json
{
  "UserId": "…",
  "Account": "123456789012",
  "Arn": "arn:aws:iam::123456789012:user/… or assumed-role/…"
}
```

Record the **Account** ID privately (password manager / notes). **Do not commit** it to Git.

### Validation

```bash
aws sts get-caller-identity --query Account --output text
aws sts get-caller-identity --query Arn --output text
```

Both must return non-empty values for the **intended** pilot account.

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `Unable to locate credentials` | No profile / env | Configure SSO or keys; export `AWS_PROFILE` |
| `ExpiredToken` | SSO session expired | `aws sso login --profile …` |
| Wrong account ID | Multiple profiles | Switch `AWS_PROFILE`; re-check |

### Recovery

`aws sso login` or rotate keys; re-run validation. No infrastructure to destroy.

### Best practices

Use a dedicated pilot account if available; tag resources later with project name.

### Security notes

Least privilege long-term; pilot often uses admin. Never commit access keys. Prefer SSO over long-lived IAM user keys.

---

## Step 1.7: Confirm Route53 zone `biroltilki.art`

### Goal

Prove the hosted zone exists and your principal can list it (read access minimum).

### Why this step is required

Topic 05 (external-dns, ACM validation) and Boutique hostnames depend on this zone. Discovering missing DNS mid-ingress wastes ALB hours.

### Commands

```bash
export AWS_REGION=eu-central-1
aws route53 list-hosted-zones-by-name --dns-name biroltilki.art --query 'HostedZones[*].[Name,Id]' --output table
```

Note the hosted zone ID (right-hand `/hostedzone/Z…` form) in private notes for Topics 04–05.

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | AWS Console |
| Navigation | Services → **Route 53** → **Hosted zones** → select `biroltilki.art` |
| Permissions | `route53:ListHostedZones`, eventually change records (or IRSA for external-dns later) |
| Verification | Zone name shows `biroltilki.art.`; type Public (expected for this pilot) |
| Screenshot (optional) | Capture Route53 hosted zone in AWS Console if useful; no committed screenshot required for Phase B |

| Field | Expected | Why |
|-------|----------|-----|
| Domain name | `biroltilki.art` | Locked DNS |
| Type | Public hosted zone | Internet hostnames for ALB |

### Expected output

Table row containing `biroltilki.art.` and a `/hostedzone/Z…` id.

### Validation

```bash
aws route53 list-hosted-zones-by-name --dns-name biroltilki.art \
  --query "HostedZones[?Name=='biroltilki.art.'].Id" --output text | grep hostedzone
```

Must print a hosted zone id.

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Empty result | Zone in another account | Use correct account / request zone access |
| AccessDenied | Missing IAM | Ask admin for Route53 read (and later write for external-dns role) |

### Recovery

Fix IAM or account selection; do not create a second conflicting public zone without DNS delegation planning.

### Best practices

One public zone for the pilot; record zone ID for Terraform `dns` module inputs (Topic 04).

### Security notes

Zone ID is not secret but treat account inventory as sensitive; do not commit account-specific IDs if your org forbids it — use tfvars locally.

---

## Step 1.8: Create GitLab project (if missing)

### Goal

Ensure a private GitLab project exists to host this control-plane repo and (later) CI.

### Why this step is required

Topics 02 (MR), 06 (Argo repo credential), and 10 (OIDC / pipelines) all need a real project URL. Confirming access alone fails when the project was never created.

### Commands

If `glab` is installed and you prefer CLI:

```bash
# Replace <GROUP_OR_NAMESPACE> with your GitLab group or personal namespace
glab auth status
glab repo create <GROUP_OR_NAMESPACE>/boutique-eks-gitops \
  --private \
  --description "Boutique EKS GitOps control plane" \
  --defaultBranch main
```

If the project already exists, skip create and continue to Step 1.9:

```bash
glab repo view <GROUP_OR_NAMESPACE>/boutique-eks-gitops -F json | jq -r '.web_url, .visibility, .default_branch'
```

If you are not using `glab`, use the GUI path only.

### GUI instructions (if applicable)

**Create project (skip if it already exists):**

| Element | Content |
|---------|---------|
| Platform | GitLab |
| Navigation | GitLab home → **New project** / **Create new project** → **Create blank project** |
| Project name | `boutique-eks-gitops` |
| Project URL / namespace | Your group or personal namespace (record privately) |
| Visibility | **Private** (recommended) |
| Initialize with README | **Unchecked** (local Phase B tree is the source of truth) |
| Default branch | `main` (set under Settings → Repository if the UI offers it) |
| Permissions | Ability to create projects in that namespace |
| Verification | Project overview opens; **Clone** shows HTTPS and SSH URLs |

Record privately (do not commit):

- Project web URL
- HTTPS clone URL
- SSH clone URL
- `path_with_namespace` (e.g. `mygroup/boutique-eks-gitops`)

### Expected output

- Blank private project exists (or you confirmed an existing one)
- Clone URLs available from the **Clone** button
- Default branch intended to be `main`

### Validation

Manual checklist:

- [ ] Project URL recorded privately
- [ ] Visibility is Private (or org-approved equivalent)
- [ ] Initialize-with-README was **not** used (avoids divergent first commit)
- [ ] You can open **Settings → General** (Maintainer/Owner) or will request that role in Step 1.9

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Cannot create project | No create permission in namespace | Ask group Owner for permission or create under personal namespace |
| Project name taken | Collision in namespace | Choose allowed name; keep `boutique-eks-gitops` if possible for docs consistency |
| README already present | Initialize-with-README was checked | Prefer empty project; if README exists, Step 1.10 will need a pull/rebase before push |

### Recovery

Delete an accidental empty test project only if you own it and nothing depends on it; recreate with Initialize README **off**.

### Best practices

One control-plane project per pilot; do not mix with unrelated application source repos.

### Security notes

Prefer private visibility. Do not paste PATs or deploy tokens into the repo or chat logs.

---

## Step 1.9: Confirm GitLab project access

### Goal

Confirm you can administer the GitLab project that will host this repo and run CI (Maintainer or Owner recommended).

### Why this step is required

Topic 10 configures OIDC and pipelines; Topic 06 registers the repo with Argo CD. Missing permissions block digest MRs and GitOps pull.

### Commands

If `glab` is installed:

```bash
glab auth status
glab repo view <GROUP_OR_NAMESPACE>/boutique-eks-gitops -F json | jq -r '.path_with_namespace, .permissions'
```

If not using `glab`, use the GUI path below and skip CLI.

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | GitLab |
| Navigation | Project → **Settings** → **General** (visible to Maintainers) |
| Permissions | **Maintainer** or **Owner** on the project (Developer may clone but often cannot configure CI OIDC / protected vars) |
| Verification | Project opens; you can view **Build → Pipeline editor** (or **Settings → CI/CD**) |

| Check | Expected | Why |
|-------|----------|-----|
| Project visibility | Private recommended | Control plane repo |
| Your role | Maintainer/Owner | OIDC + protected settings in Topic 10 |
| Repository empty or populated | Either OK | Step 1.10 pushes local tree if empty |
| CI/CD | Enabled | Digest pipeline later |

### Expected output

You can open the project and reach CI/CD-related settings. Role is Maintainer or Owner.

### Validation

Manual checklist (report in confirmation):

- [ ] Project URL recorded privately
- [ ] Role ≥ Maintainer
- [ ] Ability to create branches / MRs
- [ ] CI/CD settings page accessible

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| 404 on project | Wrong namespace / no access / Step 1.8 skipped | Create project (1.8) or request invite |
| Reporter only | Insufficient role | Request Maintainer for pilot |

### Recovery

Group owner adjusts membership; re-check Settings visibility.

### Best practices

Use project-level CI OIDC later (Topic 10); avoid long-lived AWS keys in GitLab variables.

### Security notes

Do not paste project access tokens into the repo. Rotate tokens if exposed in chat logs.

---

## Step 1.10: Initialize local Git and connect the remote

### Goal

Turn the local working tree into a Git repository, set `origin` to the GitLab project from Steps 1.8–1.9, and push the first commit to `main`.

### Why this step is required

Topic 02 commands assume a real Git root (`git rev-parse --show-toplevel`). Argo CD and GitLab CI later pull from this remote — a directory of files without `.git/` is not enough.

### Commands

Run from the directory that contains `ROADMAP.md` and `docs/setup/` (Phase B tree).

**A — Already a clone with `origin` set:** verify and skip init:

```bash
git rev-parse --is-inside-work-tree
git remote -v
git status
```

**B — No `.git/` yet (typical after Phase B authoring on disk):**

```bash
cd /path/to/boutique-eks-gitops   # directory with ROADMAP.md

git init -b main
git remote add origin <GITLAB_REPO_HTTPS_OR_SSH_URL>

git status
git add -A
git status   # confirm no secrets (.env, credentials, backend.hcl, *.tfvars secrets)

git commit -m "$(cat <<'EOF'
Initial control-plane tree from Phase B setup guides.

EOF
)"

git push -u origin main
```

Replace `<GITLAB_REPO_HTTPS_OR_SSH_URL>` with the clone URL from Step 1.8. Prefer SSH with a passphrase-protected key, or HTTPS with a short-lived token.

If `git push` is rejected because the remote has an unexpected commit (e.g. README was initialized):

```bash
git pull origin main --rebase
# resolve conflicts if any, then:
git push -u origin main
```

Do **not** use `--force` on `main` unless you intentionally own an empty pilot project and understand the risk.

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | GitLab |
| Navigation | Project → **Repository** → **Files** (after push) |
| Permissions | Developer+ to push; Maintainer to protect `main` later (Topic 11) |
| Verification | Default branch `main` shows `README.md`, `ROADMAP.md`, `docs/setup/` |

Optional now (or Topic 11): **Settings → Repository → Protected branches** — protect `main` with Maintainer merge.

### Expected output

- `git rev-parse --is-inside-work-tree` → `true`
- `origin` points at your GitLab project
- `main` exists on the remote with the control-plane tree
- No credential files in the first commit

### Validation

```bash
git rev-parse --show-toplevel
git remote get-url origin
git branch -vv
git ls-remote --heads origin main
test -f "$(git rev-parse --show-toplevel)/docs/setup/README.md" && echo "git+setup: OK"
```

Expect: toplevel path printed; `origin` URL matches Step 1.8; remote `main` listed; `git+setup: OK`.

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `not a git repository` | Wrong cwd or init skipped | `cd` to tree with `ROADMAP.md`; run `git init -b main` |
| `remote origin already exists` | Re-run | `git remote -v`; only `git remote set-url origin <URL>` if URL is wrong |
| Auth failed on push | No SSH key / expired token | Fix GitLab auth; retry push |
| Secrets staged | Accidental local credential file | `git reset HEAD -- <file>`; add to `.gitignore`; rotate if exposed |
| Push rejected (non-fast-forward) | Remote has commits | `git pull --rebase` then push; avoid force on shared `main` |

### Recovery

Fix auth or remote URL; unstage secrets; re-validate with the commands above. No AWS rollback.

### Best practices

Commit only the control-plane tree. Keep `backend.hcl` and real `*.tfvars` out of Git (see `.gitignore` from Topic 02 delivery).

### Security notes

Never commit AWS keys, GitLab PATs, or SMTP passwords. If a secret was committed, rotate it and purge from history before Topics 03+.

---

## Step 1.11: Confirm SMTP mailbox for Alertmanager

### Goal

Confirm an email inbox you control can receive SMTP-authenticated mail for Alertmanager tests (Topic 08).

### Why this step is required

Observability acceptance requires a real **email** alert path (no PagerDuty). Discovering blocked SMTP at Topic 08 delays Milestone M2.

### Commands

No cluster commands in this topic. Document locally (password manager):

```text
SMTP host: <smtp.example.com>
SMTP port: <587 or 465>
SMTP username: <user>
From address: <alertmanager@your-domain>
To address (test inbox): <you@your-domain>
Password: (password manager only — NEVER in Git)
```

Optional connectivity smoke (does not send mail on all providers):

```bash
nc -vz <SMTP_HOST> <SMTP_PORT>
```

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | Your mail provider admin (Google Workspace, Microsoft 365, Mailgun, Amazon SES, etc.) |
| Navigation | Provider console → SMTP / App passwords / Sending domains — follow **your** provider’s docs |
| Permissions | Ability to create SMTP credentials or app password |
| Verification | You can state host/port/user and have a test inbox |

| Field | Value | Why |
|-------|-------|-----|
| Purpose | Alertmanager receiver | Topic 08 ESO-backed secret |
| TLS | Required (STARTTLS or SMTPS) | Secure relay |
| Secrets storage (later) | AWS Secrets Manager / SSM via ESO | Never Git |

### Expected output

Written-down SMTP parameters in a password manager; inbox reachable.

### Validation

Checklist:

- [ ] SMTP host/port known
- [ ] Credentials stored outside Git
- [ ] Destination mailbox you can open today
- [ ] Aware that Topic 08 will send a **test alert email**

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Corporate relay blocks unknown senders | SPF/DKIM | Use approved relay or SES in-account |
| Only OAuth mail APIs | No SMTP | Choose a provider that allows SMTP AUTH for AM |

### Recovery

Switch to a supported SMTP provider before Topic 08; do not block Topics 02–07 on mail.

### Best practices

Use a dedicated `alerts@…` mailbox; rate-limit later.

### Security notes

SMTP passwords are secrets. Topic 07–08 load them via External Secrets — **never** commit to `gitops/` values.

---

## Step 1.12: Topic validation (gate to Topic 02)

### Goal

Run the consolidated checklist proving Topic 01 is complete.

### Why this step is required

Topic 02 assumes pins, Git remote, and access checks already passed.

### Commands

```bash
echo "=== versions file ==="
test -f docs/versions.md && grep -E '1\.31|0\.71\.0|2\.4\.x|eu-central-1' docs/versions.md

echo "=== CLI versions ==="
aws --version
terraform version
kubectl version --client
helm version --short
git --version
jq --version

echo "=== Git remote ==="
git rev-parse --is-inside-work-tree
git remote get-url origin
git ls-remote --heads origin main | head -1

echo "=== AWS ==="
aws sts get-caller-identity --region eu-central-1

echo "=== Route53 ==="
aws route53 list-hosted-zones-by-name --dns-name biroltilki.art \
  --query "HostedZones[?Name=='biroltilki.art.'].Id" --output text
```

### GUI instructions (if applicable)

Re-confirm GitLab project (1.8), role (1.9), remote files visible after push (1.10), and SMTP notes (1.11).

### Expected output

- Pins visible in `docs/versions.md`
- CLI versions match [matrix](../versions.md) (kubectl 1.31.x, Helm 3.16.x, Terraform ≥ 1.9, AWS CLI 2.x)
- Local Git linked to `origin`; remote `main` exists
- AWS identity returns Account/Arn
- Route53 zone id printed
- GitLab + SMTP checklists done

### Validation

Mark complete only if **all** items pass:

- [ ] Repo root + `docs/versions.md` present
- [ ] AWS CLI 2.x
- [ ] Terraform ≥ 1.9
- [ ] kubectl 1.31.x
- [ ] Helm 3.16.x
- [ ] git, jq, curl available
- [ ] `sts get-caller-identity` succeeds for intended account
- [ ] Route53 `biroltilki.art` visible
- [ ] GitLab project created (or pre-existed) and role ≥ Maintainer
- [ ] Local Git initialized; `origin` set; `main` pushed
- [ ] SMTP parameters stored securely (not in Git)

### Common problems

Any failed checkbox — return to the matching step (1.2–1.11); do not start Topic 02.

### Recovery

Fix the failing prerequisite; re-run Step 1.12 only.

### Best practices

Paste validation command output (redact Account ARN if required by policy) to your session partner before Topic 02.

### Security notes

Redact secrets and full access keys in chat. Account ID redaction is optional but recommended in public channels.

---

## Topic validation (end-to-end)

Topic 01 is **complete** when Step 1.12 checklist is fully checked and you have confirmed results with your session partner.

**Cost check:** No NAT, EKS, or ALB should exist yet from this topic. If you created resources accidentally, stop and clean them up before Topic 02.

---

## Topic troubleshooting

| Area | Symptom | Action |
|------|---------|--------|
| Versions | Minor skew (e.g. Helm 3.17) | Document deviation; prefer pinning 3.16.x; ask partner before continuing |
| AWS | Multiple accounts | Standardize on one `AWS_PROFILE` for the pilot |
| DNS | Zone in different account than EKS | Stop — architecture assumes same account for Route53 + cluster |
| GitLab | Project missing | Complete Step 1.8 before 1.9–1.10 |
| Git | No `.git/` or no `origin` | Complete Step 1.10 before Topic 02 |
| GitLab | Cannot open CI settings | Escalate role before Topic 10 (can continue 02–09 with push access alone, but plan the upgrade) |
| SMTP | Unknown yet | You may proceed through Topic 07; **must** resolve before Topic 08 |

---

## Next step

After you confirm Topic 01 execution (Phase C), continue with:

**[02 — Repo foundation](02-repo-foundation.md)**

Live execution remains one step per turn under `docs/setup/`.

**Phase C:** Resume at the next incomplete Topic 01 step (currently **1.1** unless already confirmed).
