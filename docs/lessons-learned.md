# Lessons learned — boutique-eks-gitops

Concrete takeaways from the closed production reference (Milestone 3 path + Milestone 4 teardown). Not a full postmortem — only items backed by the repo, checklist, or captured evidence.

---

## What worked

- **Digest-only + CI never deploys** stayed enforceable end to end: pipeline opens MRs; Argo reconciles; prod stays manual sync. ADR-0001 and the file-backed claims stay readable without a live cluster.
- **Teardown as a first-class milestone** kept cost in the short-run band (~$35–45 with teardown). Leaving EKS + NAT + ALBs running is the expensive failure mode; Topic 14 / Appendix T treat destroy as mandatory after tests.
- **Honest scope** (one account, one region, namespaces not isolation) made tradeoffs discussable instead of hidden.

## What broke or surprised us

- **Digest MR creation via job-token API was insufficient** for the GitLab project settings in use. The working path was creating the digest MR with **git push options** instead (see pipeline commit message on evidence capture `#2688809559`). Prefer push options (or a PAT with explicit MR scope) when designing the gitops job — do not assume `CI_JOB_TOKEN` can open MRs.
- **Boutique `ENV_PLATFORM` defaults to a `local` UI badge** when unset. Storefront screenshots on real `*.biroltilki.art` hosts still show `local`, which confuses reviewers. Set the env var per overlay on the next rebuild and re-capture.
- **Evidence that is not screenshotted is hard to show later.** Kyverno denies, canary progress, digest MR diffs, and alert email were exercised in the reference path but were not packaged under `assets/images/setup/` — see [`evidence/README.md`](evidence/README.md) “Not shown yet.”

## Design limits we accept (and would change for real production)

- Namespaces on one cluster ≠ blast-radius isolation.
- Solo `CODEOWNERS` without GitLab “Code owner approval” is documentation, not dual control.
- Stock Grafana mixins ≠ application SLOs; email-only Alertmanager ≠ on-call.
- Phase 12 items (admission verify, blocking CI gates, WAF/Falco, …) are **scaffolds** until deliberately enabled on a rebuilt cluster.

## Presenting without a live cluster

Share the repo as a closed reference. Lead with README → [ADR-0001](adr/0001-digest-only-gitops.md) → [`reference-claims.md`](reference-claims.md) → [`evidence/README.md`](evidence/README.md). State limits in the same breath as wins:

- **CI never deploys** — point at `.gitlab-ci.yml` FORBIDDEN guards and digest MR scope (`gitops/envs/dev` only).
- **Admission** — Enforce is tag/digest/ECR; signature/SBOM is Audit ([ADR-0007](adr/0007-admission-verify-and-sbom.md)).
- **Default publish** — `ecr-bootstrap` retag; from-source build is opt-in `BOUTIQUE_BUILD_MODE=git`.
- **Canary** — timed ALB weights; `canary.analysis.enabled: false` in prod values.
- **Proof gaps** — Kyverno deny, digest MR diff, and canary UI are file-backed and checklist-backed, not pictured yet; see evidence “Not shown yet.”

Do not claim live demos, green CI on default pushes (dormant until `ENABLE_REFERENCE_CI` / `ENABLE_REPO_GATES`), or Enforce on cosign verify unless you have changed Git and re-run the path.

---

## Related

- Proof gallery: [`evidence/README.md`](evidence/README.md)
- File-backed claims: [`reference-claims.md`](reference-claims.md)
- Pins / upgrade path: [`versions.md`](versions.md) · [`operations/13-upgrades.md`](operations/13-upgrades.md)
- Architecture summary: [`ARCHITECTURE.md`](ARCHITECTURE.md)
