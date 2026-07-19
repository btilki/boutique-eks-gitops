# Reusable IRSA role module
# Setup Topic 04 · used for LB controller, external-dns, ESO scaffolding

variable "name" {
  type        = string
  description = "IAM role name"
}

variable "oidc_provider_arn" {
  type = string
}

variable "oidc_provider_url" {
  type        = string
  description = "EKS OIDC issuer URL (without https:// for condition keys use strip)"
}

variable "namespace" {
  type = string
}

variable "service_account" {
  type = string
}

variable "policy_json" {
  type        = string
  description = "IAM policy document JSON for this role"
}

variable "tags" {
  type    = map(string)
  default = {}
}

locals {
  issuer_host = replace(var.oidc_provider_url, "https://", "")
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.issuer_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.issuer_host}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.service_account}"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = merge(var.tags, { Name = var.name })
}

resource "aws_iam_role_policy" "this" {
  name   = "${var.name}-policy"
  role   = aws_iam_role.this.id
  policy = var.policy_json
}

output "role_arn" {
  value = aws_iam_role.this.arn
}

output "role_name" {
  value = aws_iam_role.this.name
}
