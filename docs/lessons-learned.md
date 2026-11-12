# Lessons learned — boutique-eks-gitops

Concrete takeaways from the closed production pilot (Milestone 3 path + Milestone 4 teardown). Not a full postmortem — only items backed by the repo, checklist, or captured evidence.

---

## What worked

- **Digest-only + CI never deploys** stayed enforceable end to end: pipeline opens MRs; Argo reconciles; prod stays manual sync. Interviewers can walk ADR-0001 without a live cluster.
- **Teardown as a first-class milestone** kept cost in the short-pilot band. Leaving EKS + NAT + ALBs running is the expensive failure mode; Topic 14 / Appendix T treat destroy as mandatory after tests.
- **Honest scope** (one account, one region, namespaces not isolation) made tradeoffs discussable instead of hidden.

## What broke or surprised us

- **Digest MR creation via job-token API was insufficient** for the GitLab project settings in use. The working path was creating the digest MR with **git push options** instead (see pipeline commit message on evidence capture `#2688809559`). Prefer push options (or a PAT with explicit MR scope) when designing the gitops job — do not assume `CI_JOB_TOKEN` can open MRs.
- **Boutique `ENV_PLATFORM` defaults to a `local` UI badge** when unset. Storefront screenshots on real `*.biroltilki.art` hosts still show `local`, which confuses reviewers. Set the env var per overlay on the next rebuild and re-capture.
- **Evidence that is not screenshotted does not count in a portfolio review.** Kyverno denies, canary progress, digest MR diffs, and alert email were exercised in the pilot path but were not packaged under `assets/images/setup/` — see [`evidence/README.md`](evidence/README.md) “Not shown yet.”

## Design limits we accept (and would change for real production)

- Namespaces on one cluster ≠ blast-radius isolation.
- Solo `CODEOWNERS` without GitLab “Code owner approval” is documentation, not dual control.
- Stock Grafana mixins ≠ application SLOs; email-only Alertmanager ≠ on-call.
- Phase 12 items (admission verify, blocking CI gates, WAF/Falco, …) are **scaffolds** until deliberately enabled on a rebuilt cluster.

## Related

- Proof gallery: [`evidence/README.md`](evidence/README.md)
- File-backed claims: [`pilot-claims.md`](pilot-claims.md)
- Pins / upgrade path: [`versions.md`](versions.md) · [`operations/13-upgrades.md`](operations/13-upgrades.md)
- Architecture summary: [`ARCHITECTURE.md`](ARCHITECTURE.md)
