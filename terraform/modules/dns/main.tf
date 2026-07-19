# DNS / ACM module — Route53 zone data + ACM cert for boutique hosts
# Setup Topic 04–05 · ADR-0003 / ADR-0004

variable "zone_name" {
  type        = string
  description = "Public Route53 zone name (e.g. biroltilki.art)"
}

variable "certificate_domain_name" {
  type        = string
  description = "Primary certificate domain (e.g. boutique.biroltilki.art)"
}

variable "subject_alternative_names" {
  type        = list(string)
  description = "SAN list for platform and env hosts"
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}

data "aws_route53_zone" "this" {
  name         = var.zone_name
  private_zone = false
}

resource "aws_acm_certificate" "this" {
  domain_name               = var.certificate_domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"
  tags                      = merge(var.tags, { Name = var.certificate_domain_name })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.this.zone_id
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

output "zone_id" {
  value = data.aws_route53_zone.this.zone_id
}

output "zone_name" {
  value = data.aws_route53_zone.this.name
}

output "acm_certificate_arn" {
  value = aws_acm_certificate_validation.this.certificate_arn
}
