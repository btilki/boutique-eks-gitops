# iam_gitlab_oidc module
#
# Purpose: GitLab OIDC provider + IAM role scoped to ECR push/pull (no eks:*).
# Inputs: name, gitlab_url, gitlab_project_path, ecr_repository_arns
# Outputs: oidc_provider_arn, ci_role_arn
# Deps: ECR module ARNs
# Usage: terraform/envs/prod · Setup Topic 04; hop-test in Topic 10
#
# Requires provider: hashicorp/tls
