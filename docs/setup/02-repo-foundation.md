# 02 — Repo foundation

Audience: L2 — Implementer  
Estimated time: 2–3 hours (authoring already done in Phase B — execution is verify + commit)  
Prerequisites: [01 — Prerequisites](01-prerequisites.md) complete  
Creates: Repository tree, ADRs 0001–0005, root meta files (CODEOWNERS, gitignore, pre-commit, Makefile), SECURITY.md, stub READMEs under `terraform/`, `gitops/`, `charts/`, `tests/`  
Related ADRs: [0001](../adr/0001-digest-only-gitops.md) · [0002](../adr/0002-single-cluster-namespaces.md) · [0003](../adr/0003-tls-acm-alb.md) · [0004](../adr/0004-dns-hostname-scheme.md) · [0005](../adr/0005-observability-on-cluster.md)

---

## Topic goal

Materialize the control-plane repository spine so Topics 03+ have a stable layout, pinned versions, recorded decisions, and lint hooks — **without** provisioning AWS resources.

## Why this topic is required

Terraform modules, GitOps manifests, and CI need an agreed tree and ADRs before the first `terraform apply`. Skipping foundation causes path drift, missing CODEOWNERS on prod, and undocumented decisions.

## Before you begin

- Topic 01 Step 1.12 checklist passed.
- Working tree is a Git repo with `origin` on GitLab (Topic 01 Steps 1.8–1.10).
- Working tree contains Phase B Topic 02 files (this guide assumes partner materialized them; if a path is missing, stop and restore from Git / partner delivery).
- No `terraform apply` in this topic.
- Prefer verifying existing files over recreating them by hand.

**Idempotent:** Re-running validation is safe. Re-creating files only if missing.

---

## Step 2.1: Verify directory tree

### Goal

Confirm the approved repository layout exists on disk.

### Why this step is required

Later topics write into these paths; missing directories break GitOps and Terraform authoring.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"

for d in \
  terraform/modules terraform/envs/prod \
  gitops/bootstrap gitops/apps gitops/platform \
  gitops/envs/dev gitops/envs/stage gitops/envs/prod \
  charts examples \
  docs/adr docs/runbooks docs/setup \
  tests/helm tests/policy tests/smoke
 do
  test -d "$d" && echo "OK  $d" || echo "MISSING  $d"
done
```

If any path is **MISSING**, create only the missing directory (do not invent alternate layouts):

```bash
mkdir -p <MISSING_PATH>
# empty dirs need a tracked file:
touch <MISSING_PATH>/.gitkeep
```

### GUI instructions (if applicable)

N/A.

### Expected output

Every listed path prints `OK`.

### Validation

```bash
test -d terraform && test -d gitops && test -d charts && test -d docs/adr && echo "tree: OK"
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Many MISSING | Phase B files not in working tree | Pull/sync Topic 02 delivery |
| Wrong nested clone | cwd not repo root | `cd` to root with `ROADMAP.md` |

### Recovery

Restore from Git history or re-copy Phase B artifacts; do not invent a second structure.

### Best practices

Keep `.gitkeep` in empty dirs until real manifests land.

### Security notes

Do not place credentials under these directories.

---

## Step 2.2: Align `docs/versions.md`

### Goal

Confirm the pin matrix from Topic 01 matches locked architecture (no silent drift).

### Why this step is required

CI, Terraform, and kubectl minor must stay consistent across topics.

### Commands

```bash
test -f docs/versions.md
grep -E 'eu-central-1|1\.31|0\.71\.0|2\.4\.x|≥ 1\.9|3\.16' docs/versions.md
```

### GUI instructions (if applicable)

N/A.

### Expected output

File exists; greps show region, EKS 1.31, Trivy 0.71.0, cosign 2.4.x, Terraform ≥ 1.9, Helm 3.16.

### Validation

```bash
make docs-check
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `docs-check` fails on versions | File edited incorrectly | Restore from Topic 01 delivery; do not weaken pins without ADR |

### Recovery

Revert `docs/versions.md` to last known good.

### Best practices

Any pin change requires ADR + Setup Guide update in the same MR.

### Security notes

Pins reduce supply-chain surprise; do not float to `latest` in CI later.

---

## Step 2.3: Confirm architecture docs

### Goal

Ensure architecture summary and deep docs are present and marked accepted for implementation.

### Why this step is required

Setup topics defer design debates to architecture; missing docs force guesswork during apply.

### Commands

```bash
test -f docs/ARCHITECTURE.md
test -f docs/architecture/README.md
ls docs/architecture/0*.md docs/architecture/10-cost-model.md
```

### GUI instructions (if applicable)

N/A.

### Expected output

`ARCHITECTURE.md` plus docs `01`–`10` under `docs/architecture/`.

### Validation

```bash
grep -q 'eu-central-1' docs/ARCHITECTURE.md
grep -q 'biroltilki.art' docs/ARCHITECTURE.md
echo "architecture: OK"
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Status still “Draft” only | Stale header | Header should read Accepted / implementation-ready (Phase B update) |

### Recovery

Pull latest `docs/ARCHITECTURE.md` from Topic 02 delivery.

### Best practices

Link ADRs from architecture index when reviewing MRs.

### Security notes

Architecture security section is normative for Topics 07 and 10.

---

## Step 2.4: Verify ADRs 0001–0005

### Goal

Confirm accepted ADRs exist for digest-only GitOps, single-cluster namespaces, ACM+ALB TLS, DNS scheme, and on-cluster observability.

### Why this step is required

Locked decisions must be citable during later setup without re-litigation.

### Commands

```bash
ls docs/adr/0001-digest-only-gitops.md \
   docs/adr/0002-single-cluster-namespaces.md \
   docs/adr/0003-tls-acm-alb.md \
   docs/adr/0004-dns-hostname-scheme.md \
   docs/adr/0005-observability-on-cluster.md
```

### GUI instructions (if applicable)

N/A.

### Expected output

All five paths listed.

### Validation

```bash
grep -l 'Status:\*\* Accepted' docs/adr/000*.md | wc -l
# expect 5
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| ADR numbers disagree with old architecture index | Historical proposal list | Trust `docs/adr/*` + [REQUIRED-FILES](REQUIRED-FILES.md); index updated in Topic 02 |

### Recovery

Restore ADR files from Topic 02 delivery; do not renumber without updating all links.

### Best practices

New decisions get the next ADR number (0006 reserved for cosign in Topic 10).

### Security notes

ADR-0001 forbids CI cluster deploy — enforce in Topic 10 review.

---

## Step 2.5: Verify root meta files

### Goal

Confirm CODEOWNERS, `.gitignore`, `.pre-commit-config.yaml`, and `Makefile` exist and are sane.

### Why this step is required

Prod path ownership, secret exclusion, and lint gates prevent accidental leaks and drift before cloud resources exist.

### Commands

```bash
test -f CODEOWNERS && grep -q 'gitops/envs/prod' CODEOWNERS
test -f .gitignore && grep -q 'backend.hcl' .gitignore && grep -q '.terraform' .gitignore
test -f .pre-commit-config.yaml
test -f Makefile && grep -q 'docs-check' Makefile
make lint
make docs-check
```

Optional pre-commit install (local only):

```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files
```

### GUI instructions (if applicable)

N/A for file presence. GitLab CODEOWNERS enforcement is configured in **Topic 11** (do not block Topic 02).

### Expected output

`make lint` and `make docs-check` print `OK`. CODEOWNERS references `@btilki` on prod path.

### Validation

```bash
grep '@btilki' CODEOWNERS
make docs-check
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `terraform fmt` errors | Unexpected `.tf` with bad format | Run `terraform fmt -recursive terraform` if files exist |
| pre-commit network fail | Sandbox / offline | Skip optional install; Makefile checks remain mandatory |

### Recovery

Restore meta files from Topic 02 delivery; fix fmt; re-run `make docs-check`.

### Best practices

Never weaken `.gitignore` to commit `tfvars` with secrets.

### Security notes

`detect-private-key` hook is a backstop — not a substitute for discipline.

---

## Step 2.6: Verify stub READMEs and SECURITY.md

### Goal

Confirm navigational READMEs and security summary exist.

### Why this step is required

Onboarding and MR review need entrypoints before modules/charts are filled in.

### Commands

```bash
test -f SECURITY.md
test -f terraform/README.md
test -f gitops/README.md
test -f charts/README.md
test -f tests/README.md
test -f examples/.gitkeep
```

### GUI instructions (if applicable)

N/A.

### Expected output

All `test` commands succeed (exit 0).

### Validation

```bash
grep -q 'digest' gitops/README.md
grep -q 'frontend' charts/README.md
grep -q 'IRSA' SECURITY.md
echo "stubs: OK"
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Empty charts README | Incomplete delivery | Restore `charts/README.md` from Topic 02 |

### Recovery

Re-copy stub files; do not delete TODO markers — they link to later setup steps.

### Best practices

Update stub READMEs in the topic that fills the directory (03–12), not ad-hoc.

### Security notes

SECURITY.md points at architecture; keep threat claims consistent with ADR-0001/0005.

---

## Step 2.7: Topic validation (gate to Topic 03)

### Goal

Prove foundation complete and ready for remote state authoring/apply.

### Why this step is required

Topic 03 writes under `terraform/envs/prod/` and must not invent a new root layout.

### Commands

```bash
make docs-check
make lint
git status
find terraform gitops charts docs/adr -maxdepth 3 -type f | sort | head -80
```

### GUI instructions (if applicable)

If using GitLab: create a branch/MR containing Topic 02 files if not already on default branch.

| Element | Content |
|---------|---------|
| Platform | GitLab |
| Navigation | Project → **Merge requests** → **New merge request** |
| Permissions | Developer+ to push; Maintainer to merge to default |
| Verification | MR shows ADRs, tree, Makefile; pipeline may be absent until Topic 10 |

### Expected output

- `docs-check: OK` / `lint: OK`
- ADRs 0001–0005 tracked
- No secrets staged (`git status` clean of credentials)

### Validation

Checklist:

- [ ] Directory tree Step 2.1 all OK
- [ ] `docs/versions.md` aligned
- [ ] Architecture docs present
- [ ] ADRs 0001–0005 Accepted
- [ ] CODEOWNERS, gitignore, pre-commit, Makefile present
- [ ] SECURITY + stub READMEs present
- [ ] `make docs-check` passes
- [ ] No AWS resources created in this topic

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Untracked secrets | Accidental credential file | Delete; ensure gitignore; rotate if exposed |

### Recovery

Unstage secrets; rotate; re-validate.

### Best practices

Commit Topic 02 as one reviewable MR before Topic 03 cloud changes.

### Security notes

Confirm `backend.hcl` and `*.tfvars` (non-example) are ignored before any state work.

---

## Topic validation (end-to-end)

Topic 02 is complete when Step 2.7 checklist passes and the foundation MR is merged (or confirmed on your working branch for solo pilot).

**Cost check:** Still no EKS/NAT/ALB from this topic.

---

## Topic troubleshooting

| Area | Symptom | Action |
|------|---------|--------|
| Layout | Files under wrong top-level name | Stop; rename to approved structure in plan §7.13 |
| ADRs | Desire to change TLS or DNS | Open new ADR — do not silently edit 0003/0004 mid-flight |
| Make | `terraform` not installed | Topic 01 incomplete — return to 01 |
| Git | Huge unrelated files | Remove; keep control-plane focused |

---

## Next step

**[03 — Terraform remote state](03-remote-state.md)** (Phase B authoring next, then Phase C execution).

Do not create S3/DynamoDB until Topic 03 guide is approved and you execute its steps.
