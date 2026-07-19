# ADR-0001: Digest-only GitOps (Argo CD as sole deploy authority)

- **Status:** Accepted  
- **Date:** 2026-07-18  
- **Setup:** Topic 02  

## Context

We need immutable, auditable releases for Online Boutique on EKS. Tag-based deploys (`:latest`, moving tags) and CI `kubectl apply` / `argocd sync` create drift, weaken audit trails, and couple pipeline credentials to the cluster API.

## Decision

- **Git is the only deploy authority.** Desired state lives in this repo under `gitops/`.
- Workload images are referenced by **digest only** (`image.digest`); never `:latest`.
- GitLab CI may build, scan, sign, and open MRs that patch digests — it must **not** deploy to the cluster.
- Argo CD reconciles Git → cluster (app-of-apps + ApplicationSet). Prod sync is **manual**.

## Consequences

- **Positive:** Reviewable promotions; rollback via `git revert`; CI needs no cluster kubeconfig.
- **Negative:** First bootstrap requires a one-time ECR digest push (Topic 09) before CI loops.
- **Follow-ups:** Kyverno enforce (Topic 07); CI contract (Topic 10); ADR-0006 cosign mode (Topic 10).
