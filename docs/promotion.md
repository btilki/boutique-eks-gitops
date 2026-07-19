# Promotion — digest copy across environments

**Audience:** L2 — Implementer / Release owner  
**Setup:** Topic 11 · **ADR:** [0001 digest-only GitOps](adr/0001-digest-only-gitops.md)  
**Related:** [rollback.md](rollback.md) · [ci.md](ci.md) · [CODEOWNERS](../CODEOWNERS)

## Goal

Move **the same image digests** from `dev` → `stage` → `prod` using Git merge requests. Argo reconciles; CI does not promote.

## Rules (non-negotiable)

| Rule | Detail |
|------|--------|
| Digest-only | Promotion MRs change **only** `image.digest` under `gitops/envs/<env>/values/*.yaml` |
| No chart edits | Do not change templates, ports, or replica counts in a promote MR |
| No CI promote | GitLab CI writes **dev** only ([docs/ci.md](ci.md)) |
| Stage first | Never skip stage for the pilot happy path |
| Prod ownership | `gitops/envs/prod/**` requires `@btilki` CODEOWNERS approval |
| Prod sync | After merge, **manual** Argo sync for `*-prod` apps (no auto-sync) |

## Paths

| Env | Values path | Hostname | Argo sync |
|-----|-------------|----------|-----------|
| dev | `gitops/envs/dev/values/` | `dev-boutique.biroltilki.art` | Automated |
| stage | `gitops/envs/stage/values/` | `stage-boutique.biroltilki.art` | Automated |
| prod | `gitops/envs/prod/values/` | `boutique.biroltilki.art` | **Manual** |

## Procedure — promote `dev` → `stage`

```bash
git fetch origin
git checkout -b promote/stage-$(date +%Y%m%d) origin/main

# Copy digests service-by-service (example: all boutique services)
for svc in frontend productcatalogservice cartservice checkoutservice \
           currencyservice paymentservice shippingservice redis; do
  dig=$(yq '.image.digest' "gitops/envs/dev/values/${svc}.yaml")
  yq -i ".image.digest = \"${dig}\"" "gitops/envs/stage/values/${svc}.yaml"
done

git add gitops/envs/stage/values/*.yaml
git status  # must show ONLY stage values files
git commit -m "promote: copy digests dev → stage"
git push -u origin HEAD
# Open MR → main; merge after review
```

**Validate after merge:** Argo apps `*-stage` Synced/Healthy; `https://stage-boutique.biroltilki.art` OK.

## Procedure — promote `stage` → `prod`

```bash
git fetch origin
git checkout -b promote/prod-$(date +%Y%m%d) origin/main

for svc in frontend productcatalogservice cartservice checkoutservice \
           currencyservice paymentservice shippingservice redis; do
  dig=$(yq '.image.digest' "gitops/envs/stage/values/${svc}.yaml")
  yq -i ".image.digest = \"${dig}\"" "gitops/envs/prod/values/${svc}.yaml"
done

git add gitops/envs/prod/values/*.yaml
git status  # must show ONLY prod values files
git commit -m "promote: copy digests stage → prod"
git push -u origin HEAD
# Open MR → main
# CODEOWNERS: @btilki must approve
# Merge, then MANUAL Argo sync for each *-prod app (or Application sync)
```

**Validate after manual sync:** `https://boutique.biroltilki.art` OK; Argo `*-prod` Healthy.

## MR checklist (reviewer)

- [ ] Diff is digest lines only (no Ingress/host/ACM churn unless intentional and called out)
- [ ] Source env digests match what was tested
- [ ] Stage promote precedes prod
- [ ] Prod MR has `@btilki` approval
- [ ] No `kubectl` / CI deploy instructions in the MR

## Partial promote

Allowed: promote a **subset** of services (e.g. only `frontend`) if tested that way — still digest-only, still stage then prod.
