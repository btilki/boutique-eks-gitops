# Contributing — boutique-eks-gitops

**Audience:** Engineers opening MRs on this control-plane repo  
**Authority:** [`docs/setup/`](docs/setup/) wins if chat, README, or scripts disagree.

## Rules

1. **One Setup topic or one bounded feature per MR** — do not bundle unrelated Terraform + CI + charts.
2. **Digest promotion MRs** must change only `image.digest` (and necessary blank-line noise) under `gitops/envs/{dev,stage,prod}/`.
3. **Prod path** (`gitops/envs/prod/**`) requires `@btilki` via [`CODEOWNERS`](CODEOWNERS). Enable GitLab **code owner approval** on `main` or the file is advisory only.
4. **Never commit secrets** — no AWS keys, SMTP passwords, `backend.hcl`, or real `*.tfvars`. Prefer placeholders in guides.
5. **CI must not deploy** — no `kubectl` / `argocd` in routine pipeline jobs (see [`.gitlab-ci.yml`](.gitlab-ci.yml) FORBIDDEN guards).
6. After live tests, run **Topic 14 teardown** — do not leave the pilot cluster billing.

## Local checks before push

```bash
make lint
make docs-check
# Optional: helm lint charts/<service>
```

## Where to start

| Goal | Start here |
|------|------------|
| Bootstrap / rebuild | [`docs/setup/README.md`](docs/setup/README.md) |
| Architecture | [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) |
| CI contract | [`docs/ci.md`](docs/ci.md) |
| Promotion / rollback | [`docs/promotion.md`](docs/promotion.md), [`docs/rollback.md`](docs/rollback.md) |
| Ops incidents | [`docs/runbooks/`](docs/runbooks/) |

## Account IDs in Git

Guides use `<ACCOUNT_ID>` placeholders. Env overlays may pin this pilot’s ECR/ACM ARNs so Argo can sync — that is intentional for the workshop account. Redact or templatize before publishing a public fork.

## Security reports

See [`SECURITY.md`](SECURITY.md). Do not file public issues with exploit details against a live account.

## License

Contributions are under the [Apache License 2.0](LICENSE) (Copyright 2026 Birol Tilki), unless noted otherwise.
