# Makefile — validation helpers only.
# Does NOT install CLIs, apply Terraform, or deploy to the cluster.
# Setup authority remains docs/setup/.

.PHONY: help lint docs-check

help:
	@echo "Targets:"
	@echo "  make lint       - terraform fmt -check (when modules exist) + basic file checks"
	@echo "  make docs-check - verify Setup Guide index and versions matrix exist"

lint:
	@echo "==> docs/versions.md"
	@test -f docs/versions.md
	@echo "==> terraform fmt (if .tf files present)"
	@if find terraform -name '*.tf' 2>/dev/null | grep -q .; then \
		terraform fmt -check -recursive terraform; \
	else \
		echo "No .tf files — skip fmt"; \
	fi
	@echo "lint: OK"

docs-check:
	@test -f docs/setup/README.md
	@test -f CONTRIBUTING.md
	@test -f docs/setup/01-prerequisites.md
	@test -f docs/setup/02-repo-foundation.md
	@test -f docs/setup/03-remote-state.md
	@test -f terraform/backend.hcl.example
	@test -f terraform/envs/prod/backend.tf
	@test -f terraform/envs/prod/versions.tf
	@test -f docs/setup/04-network-eks-ecr-iam.md
	@test -f docs/setup/05-ingress-dns-tls.md
	@test -f docs/setup/06-argocd-bootstrap.md
	@test -f docs/setup/07-security-baseline.md
	@test -f docs/setup/08-observability.md
	@test -f docs/setup/09-boutique-charts.md
	@test -f docs/setup/10-gitlab-ci-digest.md
	@test -f docs/setup/11-promotion.md
	@test -f docs/setup/12-canary-rollouts.md
	@test -f docs/setup/13-production-readiness.md
	@test -f docs/setup/14-teardown.md
	@test -f docs/setup/15-supply-chain-verify-sbom.md
	@test -f docs/setup/16-ci-security-gates.md
	@test -f docs/setup/17-argocd-hardening.md
	@test -f docs/setup/18-canary-analysis.md
	@test -f docs/setup/19-edge-runtime-waf-falco.md
	@test -f docs/adr/0010-edge-waf-and-falco.md
	@test -f terraform/modules/waf/main.tf
	@test -f gitops/platform/falco/values.yaml
	@test -f docs/adr/0009-canary-analysis-templates.md
	@test -f docs/adr/0008-argocd-appprojects-sso.md
	@test -f gitops/platform/argo-rollouts/analysis/frontend-http-smoke.yaml
	@test -f gitops/bootstrap/argocd/hardening/projects/boutique-platform.yaml
	@test -f gitops/bootstrap/argocd/hardening/projects/boutique-workloads.yaml
	@test -f .checkov.yaml
	@test -f .gitleaks.toml
	@test -f tests/policy/unit/kyverno-test.yaml
	@test -f docs/adr/0007-admission-verify-and-sbom.md
	@test -f gitops/platform/kyverno/policies/verify-image-signatures.yaml
	@test -f gitops/platform/kyverno/policies/verify-sbom-attestation.yaml
	@test -f docs/runbooks/teardown.md
	@test -f LICENSE
	@test -f docs/operations/README.md
	@test -f docs/operations/17-common-incidents.md
	@test -f docs/PRODUCTION_CHECKLIST.md
	@test -f docs/runbooks/ingress.md
	@test -f docs/runbooks/argo-sync.md
	@test -f docs/runbooks/kyverno.md
	@test -f docs/runbooks/canary.md
	@test -f gitops/platform/argo-rollouts/values.yaml
	@test -f charts/frontend/templates/rollout.yaml
	@test -f docs/promotion.md
	@test -f docs/rollback.md
	@test -f .gitlab-ci.yml
	@test -f docs/ci.md
	@test -d charts/frontend
	@test -f docs/runbooks/alerting.md
	@test -f gitops/platform/kyverno/policies/deny-latest-tag.yaml
	@test -f gitops/bootstrap/root/application.yaml
	@test -f gitops/apps/platform-apps/applicationset.yaml
	@test -f docs/dns-and-tls.md
	@test -f examples/smoke-ingress.yaml
	@test -f terraform/envs/prod/main.tf
	@test -f terraform/modules/network/main.tf
	@test -f docs/versions.md
	@test -f docs/ARCHITECTURE.md
	@test -f docs/adr/0001-digest-only-gitops.md
	@grep -q 'eu-central-1' docs/versions.md
	@grep -q '0.71.0' docs/versions.md
	@echo "docs-check: OK"
