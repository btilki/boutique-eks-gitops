# Tests — boutique-eks-gitops

Validation helpers for charts, policies, and smoke checks. **Not** a substitute for Setup Guide validation.

| Path | Purpose | First populated |
|------|---------|-----------------|
| `tests/helm/` | `helm lint` / template fixtures | Topic 09 |
| `tests/policy/` | Kyverno policy fixtures | Topic 07 |
| `tests/smoke/` | HTTP / kubectl smoke scripts referenced by setup | Topics 05, 09, 13 |

```bash
make lint
make docs-check
```

Do not add install-all or cluster-apply scripts here.

## TODO

- `TODO(setup:7.3)` — policy deny fixtures  
- `TODO(setup:9.1)` — helm lint samples  
- `TODO(setup:13.1)` — smoke checklist pointers  
