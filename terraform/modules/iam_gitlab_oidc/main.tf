# GitLab OIDC → IAM role for ECR push (no EKS deploy)
# Setup Topic 04 / 10 · SECURITY.md

variable "name" {
  type        = string
  description = "Name prefix for OIDC resources"
}

variable "gitlab_url" {
  type        = string
  description = "GitLab issuer URL (no trailing slash), e.g. https://gitlab.com"
  default     = "https://gitlab.com"
}

variable "gitlab_project_path" {
  type        = string
  description = "GitLab project path group/project used in sub claim matching (legacy path-based sub)"
}

variable "gitlab_project_id" {
  type        = string
  description = "GitLab numeric project ID for OIDC sub (required when path-based ID tokens are burned)"
  default     = null
}

variable "gitlab_ref_pattern" {
  type        = string
  description = "Allowed ref pattern fragment for subject condition"
  default     = "*" # TODO(setup:10.1): tighten to protected branches in Topic 10
}

variable "ecr_repository_arns" {
  type        = list(string)
  description = "ECR repository ARNs the CI role may push to"
}

variable "tags" {
  type    = map(string)
  default = {}
}

data "tls_certificate" "gitlab" {
  url = var.gitlab_url
}

resource "aws_iam_openid_connect_provider" "gitlab" {
  url             = var.gitlab_url
  client_id_list  = [var.gitlab_url]
  thumbprint_list = [data.tls_certificate.gitlab.certificates[0].sha1_fingerprint]
  tags            = merge(var.tags, { Name = "${var.name}-gitlab-oidc" })
}

locals {
  # Prefer project_id-based sub when set (GitLab burned-path / rename-safe).
  # Format: project_id:<id>:ref_type:<type>:ref:<branch>
  oidc_sub_like = var.gitlab_project_id != null && var.gitlab_project_id != "" ? (
    "project_id:${var.gitlab_project_id}:*"
    ) : (
    "project_path:${var.gitlab_project_path}:*"
  )
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.gitlab.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(var.gitlab_url, "https://", "")}:aud"
      values   = [var.gitlab_url]
    }
    condition {
      test     = "StringLike"
      variable = "${replace(var.gitlab_url, "https://", "")}:sub"
      values   = [local.oidc_sub_like]
    }
  }
}

resource "aws_iam_role" "ci" {
  name               = "${var.name}-gitlab-ci"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = merge(var.tags, { Name = "${var.name}-gitlab-ci" })
}

data "aws_iam_policy_document" "ecr_push" {
  statement {
    sid    = "EcrAuth"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "EcrPushPull"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
    ]
    resources = var.ecr_repository_arns
  }
}

resource "aws_iam_role_policy" "ecr_push" {
  name   = "ecr-push"
  role   = aws_iam_role.ci.id
  policy = data.aws_iam_policy_document.ecr_push.json
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.gitlab.arn
}

output "ci_role_arn" {
  value = aws_iam_role.ci.arn
}
