# Optional WAFv2 Web ACL for ALB (Topic 19 / ADR-0010)
# Default: disabled (count = 0) — enable after rebuild via enable_waf = true

variable "enabled" {
  type        = bool
  description = "When false, no WAF resources are created"
  default     = false
}

variable "name" {
  type        = string
  description = "Web ACL name prefix"
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "aws_wafv2_web_acl" "this" {
  count = var.enabled ? 1 : 0

  name        = var.name
  description = "Regional WAF for Boutique ALBs (Topic 19)"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  # AWS Managed Rules — Common Rule Set (baseline OWASP-ish)
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name}-CommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # Known bad inputs
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name}-KnownBadInputs"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = var.name
    sampled_requests_enabled   = true
  }

  tags = var.tags
}

output "web_acl_arn" {
  description = "WAFv2 Web ACL ARN (null when disabled)"
  value       = try(aws_wafv2_web_acl.this[0].arn, null)
}

output "web_acl_id" {
  value = try(aws_wafv2_web_acl.this[0].id, null)
}
