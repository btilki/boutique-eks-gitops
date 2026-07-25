# ADR-0006: Cosign Sigstore keyless signing via GitLab OIDC

- **Status:** Accepted  
- **Date:** 2026-07-18  
- **Setup:** Topic 10  

## Context

Container images pushed to ECR must be signed for supply-chain integrity. Long-lived cosign private keys in CI variables create theft risk and rotation burden. GitLab can issue OIDC identity tokens consumable by Sigstore Fulcio for **keyless** signatures.

## Decision

- Use **cosign 2.4.x** with **Sigstore keyless** signing.
- Obtain identity via GitLab CI `id_tokens` → `SIGSTORE_ID_TOKEN` (audience `sigstore`).
- Do **not** store cosign private keys in GitLab CI variables for routine signing.
- Verification (optional later) uses Fulcio/Rekor identity matching the GitLab project.

## Consequences

- **Positive:** No long-lived signing keys; signatures bound to GitLab identity; aligns with “no static AWS keys” posture.
- **Negative:** Requires outbound access to Sigstore infrastructure; offline air-gap signing unsupported in v1.
- **Follow-ups:** Document verify command in `docs/ci.md` (done). Admission verify + SBOM → [ADR-0007](0007-admission-verify-and-sbom.md) / Setup Topic 15.
