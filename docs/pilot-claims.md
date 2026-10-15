# What this pilot claims

**Audience:** Someone defending this repository in a DevOps interview  
**Status:** Closed production pilot. AWS resources were destroyed. Nothing in this file requires a new cluster.

Say this first: GitLab proposes image digests, Git stores them, and Argo CD is the reconciler. The pilot proved that path once, then the cloud resources were removed.

## Proven in the closed production pilot

- EKS 1.31 in `eu-central-1`, three nodes, digest-pinned Boutique pods.
- GitLab OIDC to ECR. CI did not call the cluster API.
- Kyverno **Enforce** for `:latest`, required digests, and the ECR allowlist.
- Promotion `dev → stage → prod`, CODEOWNERS on prod, manual prod sync.
- Frontend canary with timed ALB weights on stage and prod, then a `git revert` rollback.
- Teardown completed. The checklist is [`PRODUCTION_CHECKLIST.md`](PRODUCTION_CHECKLIST.md).

## What a reader can check with no cluster

| Control | File | Claim that matches the file |
|---------|------|-----------------------------|
| CI does not deploy | `.gitlab-ci.yml` | The gitops job refuses `kubectl` and `argocd`. It opens a digest MR for `gitops/envs/dev/values/` only. |
| Default image publish | `.gitlab-ci.yml` `BOUTIQUE_BUILD_MODE` | Default is `ecr-bootstrap`: retag `:bootstrap`. `git` builds from the Boutique tag and is opt-in. `currencyservice` and `paymentservice` then get the protobufjs patch. |
| Digest contract | `charts/*/templates/deployment.yaml` | The image reference is `repository@digest`. |
| Tag and registry admission | `gitops/platform/kyverno/policies/deny-latest-tag.yaml`, `require-image-digest.yaml`, `ecr-registry-allowlist.yaml` | `validationFailureAction: Enforce`. |
| Signature and SBOM admission | `verify-image-signatures.yaml`, `verify-sbom-attestation.yaml` | `validationFailureAction: Audit`. CI can sign and attest. Audit records a miss. An unsigned digest can still be scheduled. |
| Network baseline | `gitops/platform/network-policies/prod.yaml` | Cross-namespace traffic is denied. Pods in the same namespace may use any port. Ingress allows `10.0.0.0/16`. Egress allows TCP 80 and 443 to the internet, except the instance metadata address. |
| Canary | `gitops/envs/prod/values/frontend.yaml` | Weights 10, 30, 50, 100 with pauses. `canary.analysis.enabled: false`. |
| API exposure and secret encryption | `terraform/modules/eks/main.tf` | Public API access is on. The default CIDR is `0.0.0.0/0`. The cluster resource has no `encryption_config`. |
| IaC scan | `.checkov.yaml` | `soft_fail: true`. The skipped checks include the public API and the single NAT. |
| Versions | `docs/versions.md` | EKS 1.31 extended support runs into November 2026. Kyverno CLI `1.13.4` is the offline test binary. The cluster chart target is 1.16.x. |
| CI today | `.gitlab-ci.yml` workflow | No pipeline is created unless `ENABLE_PILOT_CI` or `ENABLE_REPO_GATES` is set. |
| Workload hardening | `charts/*/templates/deployment.yaml` | No `securityContext`: no `runAsNonRoot`, no dropped capabilities, no read-only root filesystem. Probes are TCP. |
| Pod Security | `gitops/envs/{dev,stage,prod}/namespace.yaml` | `pod-security.kubernetes.io/enforce: baseline`. |
| Redis | `charts/redis/` | No password and no volume. Cart data ends when the pod is replaced. |
| Identifiers in Git | `gitops/envs/prod/values/frontend.yaml` and platform values | Account `868480224481` and ACM certificate `9363fd9a-7ed5-41da-aea5-f37f53a94269` are committed. The certificate and cluster are gone. These are identifiers. The secret path was External Secrets. |

## Sentences to retire

- “Ignore red CI on digest MRs.” The production-pilot checklist did not name the failed job. The image path was taken from the default-branch pipeline and the merged digest diff. See [`ci.md`](ci.md).
- “Signatures are enforced.” The Enforce policies are the tag, digest, and ECR checks. Signature verify is Audit ([ADR-0007](adr/0007-admission-verify-and-sbom.md)).
- “The pipeline builds the application from source.” That is `BOUTIQUE_BUILD_MODE=git`. The default mode retags.
- “The canary analyzes error rate.” The rehearsed canary moved traffic on a timer.
- “These pins are the current supported set.” They are the closed production-pilot set.

## Left for a rebuild you choose later

Private API CIDR, KMS encryption for Kubernetes secrets, `Enforce` on signature verify, metric analysis on the canary, and an EKS version past 1.31. Those edits belong in Git only after you decide to run them. This page does not mark them done.
