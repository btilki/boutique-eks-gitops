# ADR-0007: Admission signature verify + CycloneDX SBOM attestations

- **Status:** Accepted (scaffold)  
- **Date:** 2026-07-25  
- **Setup:** Topic 15  
- **Supersedes follow-up in:** [ADR-0006](0006-cosign-signing-mode.md)

## Context

ADR-0006 established **Sigstore keyless** cosign signing in GitLab CI. Signing alone does not stop an unsigned or foreign image from being admitted if Kyverno only checks digest/ECR. Operators also need a durable software bill of materials (**SBOM**) for vulnerability and license review.

## Decision

1. **Admission:** Kyverno `verifyImages` ClusterPolicies require Sigstore keyless signatures (and optionally CycloneDX attestations) for `*.dkr.ecr.eu-central-1.amazonaws.com/boutique-eks-gitops/*` in `dev` / `stage` / `prod`.
2. **Default mode:** Policies ship as **`validationFailureAction: Audit`** so Topic 09 bootstrap digests and first rebuild are not blocked. Switch to **Enforce** only after CI-signed (and attested) digests are proven.
3. **Identity:** Fulcio subject must match GitLab project OIDC identity; issuer `https://gitlab.com`; Rekor `https://rekor.sigstore.dev`.
4. **SBOM:** GitLab CI generates **CycloneDX** via Trivy and attaches it with `cosign attest --type cyclonedx` using the same keyless identity as signing. SBOM JSON is also retained as a CI artifact.
5. **Non-goals (this ADR):** SLSA provenance builders beyond cosign attest, in-toto layout policies, offline/air-gapped Sigstore mirrors.

## Consequences

- **Positive:** Closes the sign→admit loop; SBOM available in CI and as OCI attestations; Audit-first avoids rebuild lockouts.
- **Negative:** Admission needs cluster egress to Rekor/Fulcio (or a future mirror); webhook latency increases; Enforce before signed digests exist will block Boutique.
- **Follow-ups:** Tighten `subjectRegExp` to `@refs/heads/main` (or protected tags); optional Enforce for SBOM after signature Enforce is stable. Edge WAF / runtime Falco → [ADR-0010](0010-edge-waf-and-falco.md) / Topic 19 (scaffold done).
