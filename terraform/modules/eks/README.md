# EKS module
#
# Purpose: EKS 1.31 control plane, managed node group (m6i.large ASG 2–5), cluster OIDC for IRSA.
# Inputs: name, vpc_id, private_subnet_ids, sizing, public API CIDRs
# Outputs: cluster_name, endpoint, oidc_provider_arn/url
# Deps: network module
# Requires provider: hashicorp/tls (for OIDC thumbprint)
# Usage: terraform/envs/prod · Setup Topic 04
#
# Cost: Control plane + 3× m6i.large — dominant bill; teardown Topic 14.
