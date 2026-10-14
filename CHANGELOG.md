# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Fixed

- Mermaid GitOps sequence in [`docs/architecture/04-data-flows.md`](docs/architecture/04-data-flows.md): removed `;` from message label (broke GitHub render) and declared missing AWS participant in secrets flow.

### Changed

- Interview claims now match the files, with no cluster required: [`docs/pilot-claims.md`](docs/pilot-claims.md). Signature admission stays Audit. The “ignore red CI” checklist line now states that the failed job was not recorded. Version pins are dated to the July 2026 pilot. The network-design page, Topic 07, and the architecture summaries now describe the coarse NetworkPolicy. The claims page names the missing workload `securityContext`, Redis durability, and the committed account id.
- Docs use **production** / **test** wording consistently (checklist section **E**, Topic 13, FR-10, README audience/related projects).
- ESO smoke-test sample renamed to `eso-smoke` / `eso-smoke-secret` ([`examples/externalsecret-sample.yaml`](examples/externalsecret-sample.yaml), Topic 07).
- Abbreviation first-mention format on public overview docs (**AWS**, **EKS**, **CI**, **MR**, **SRE**, **ACM**, **ALB**); fixed broken `` `kubectl apply`s `` typography in README.

### Added

- **Phase 12 scaffold** (Topics 15–19): cosign admission verify + SBOM Audit policies, CI gates (Gitleaks/Checkov/Kyverno unit), Argo AppProjects + Dex/notifications examples, canary AnalysisTemplates, optional WAF/Falco stubs — see [`ROADMAP.md`](ROADMAP.md).
- Setup screenshots embedded in Topics 06–13; abbreviation ownership table in [`docs/setup/README.md`](docs/setup/README.md).

## [0.1.0] — 2026-07-20

Production pilot closed: **M3 PASS** (2026-07-19) · **M4 PASS** (2026-07-19/20). AWS billable resources destroyed (Appendix T).

### Added

- Terraform: VPC (1× NAT), EKS 1.31, ECR, GitLab OIDC, IRSA, remote state; ACM/Route53 data.
- Platform GitOps: LB controller, external-dns, cert-manager, Argo CD app-of-apps, Kyverno, ESO, NetworkPolicy, Rollouts, Prom/Loki/Grafana/Alertmanager → email.
- Boutique Helm charts (7 services + Redis); env overlays `dev` / `stage` / `prod`; digest-only image contract.
- GitLab CI: test → build → Trivy CRITICAL → Sigstore keyless cosign → digest MR only (no cluster deploy).
- Promotion governance, CODEOWNERS on prod, stage+prod frontend canary, rollback via `git revert`.
- Setup Guide Topics 01–14, ADRs 0001–0006, PRODUCTION_CHECKLIST, runbooks, operations docs.

### Changed

- Post-teardown: CI dormant unless `ENABLE_PILOT_CI` / `ENABLE_REPO_GATES` set in GitLab.
