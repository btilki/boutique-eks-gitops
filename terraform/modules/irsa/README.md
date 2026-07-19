# irsa module
#
# Purpose: IAM role trusted by a specific Kubernetes service account (IRSA).
# Inputs: name, oidc_provider_arn/url, namespace, service_account, policy_json
# Outputs: role_arn, role_name
# Deps: EKS OIDC provider
# Usage: terraform/envs/prod · Setup Topic 04 scaffolding for Topics 05/07
