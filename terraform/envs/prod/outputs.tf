# Outputs — foundation stack
# Setup Topic 04 validation + inputs for Topics 05–10

output "vpc_id" {
  value = module.network.vpc_id
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}

output "route53_zone_id" {
  value = module.dns.zone_id
}

output "acm_certificate_arn" {
  value = module.dns.acm_certificate_arn
}

output "gitlab_ci_role_arn" {
  value       = module.iam_gitlab_oidc.ci_role_arn
  description = "IAM role for GitLab OIDC (ECR only)"
}

output "irsa_aws_lb_controller_role_arn" {
  value = module.irsa_aws_lb_controller.role_arn
}

output "irsa_external_dns_role_arn" {
  value = module.irsa_external_dns.role_arn
}

output "irsa_external_secrets_role_arn" {
  value = module.irsa_external_secrets.role_arn
}

output "configure_kubectl" {
  value = "aws eks update-kubeconfig --region eu-central-1 --name ${module.eks.cluster_name}"
}
