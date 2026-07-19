# DNS / ACM module
#
# Purpose: Look up Route53 zone; request + DNS-validate ACM certificate for boutique hosts.
# Inputs: zone_name, certificate_domain_name, subject_alternative_names
# Outputs: zone_id, acm_certificate_arn
# Deps: existing public hosted zone (Topic 01)
# Usage: terraform/envs/prod · Setup Topic 04
#
# Note: Public HTTPS uses this ACM cert on ALB (Topic 05). cert-manager is separate.
