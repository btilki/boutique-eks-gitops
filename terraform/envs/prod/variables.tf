# Variables — terraform/envs/prod
# Setup Topic 04 · copy terraform.tfvars.example → terraform.tfvars (gitignored)

variable "project_name" {
  type        = string
  description = "Project name prefix for AWS resources"
  default     = "boutique-eks-gitops"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
  default     = "boutique-eks-gitops"
}

variable "cluster_version" {
  type        = string
  description = "EKS Kubernetes version"
  default     = "1.31"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
  default     = "10.0.0.0/16"
}

variable "az_count" {
  type        = number
  description = "Number of AZs (prefer 3)"
  default     = 3
}

variable "node_instance_types" {
  type    = list(string)
  default = ["m6i.large"]
}

variable "node_desired_size" {
  type    = number
  default = 3
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 5
}

variable "endpoint_public_access_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to reach the public EKS API endpoint"
  default     = ["0.0.0.0/0"] # TODO(setup:4.1): tighten to your IP/office CIDR before long-lived use
}

variable "dns_zone_name" {
  type        = string
  description = "Route53 public zone name"
  default     = "biroltilki.art"
}

variable "gitlab_url" {
  type        = string
  description = "GitLab issuer URL without trailing slash"
  default     = "https://gitlab.com"
}

variable "gitlab_project_path" {
  type        = string
  description = "GitLab path_with_namespace (group/project) for OIDC subject matching"
  # PLACEHOLDER — set in terraform.tfvars (called out explicitly)
  default = "REPLACE_ME/boutique-eks-gitops"
}

variable "gitlab_project_id" {
  type        = string
  description = "GitLab numeric project ID for OIDC sub claim (use when path-based ID tokens are burned)"
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Additional resource tags"
  default     = {}
}

# Topic 19 — WAFv2 (disabled by default; no cost until true)
variable "enable_waf" {
  type        = bool
  description = "Create REGIONAL WAFv2 Web ACL for ALB association (Topic 19)"
  default     = false
}
