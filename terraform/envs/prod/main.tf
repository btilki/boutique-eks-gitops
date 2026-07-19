# Root module — boutique-eks-gitops foundation (eu-central-1)
# Setup Topic 04 · Do not apply until following docs/setup/04-network-eks-ecr-iam.md

locals {
  name = var.project_name
  tags = merge(var.tags, {
    Project = var.project_name
  })

  ecr_services = [
    "frontend",
    "productcatalogservice",
    "cartservice",
    "checkoutservice",
    "currencyservice",
    "paymentservice",
    "shippingservice",
    "redis", # cartservice dependency — mirrored in Topic 09 bootstrap
  ]

  acm_sans = [
    "*.boutique.${var.dns_zone_name}",
    "dev-boutique.${var.dns_zone_name}",
    "stage-boutique.${var.dns_zone_name}",
  ]
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

module "network" {
  source = "../../modules/network"

  name     = local.name
  vpc_cidr = var.vpc_cidr
  azs      = local.azs
  tags     = local.tags
}

module "eks" {
  source = "../../modules/eks"

  name                         = var.cluster_name
  cluster_version              = var.cluster_version
  vpc_id                       = module.network.vpc_id
  private_subnet_ids           = module.network.private_subnet_ids
  node_instance_types          = var.node_instance_types
  node_desired_size            = var.node_desired_size
  node_min_size                = var.node_min_size
  node_max_size                = var.node_max_size
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs
  tags                         = local.tags
}

module "ecr" {
  source = "../../modules/ecr"

  repository_names = [for s in local.ecr_services : "${var.project_name}/${s}"]
  tags             = local.tags
}

module "dns" {
  source = "../../modules/dns"

  zone_name                 = var.dns_zone_name
  certificate_domain_name   = "boutique.${var.dns_zone_name}"
  subject_alternative_names = local.acm_sans
  tags                      = local.tags
}

module "iam_gitlab_oidc" {
  source = "../../modules/iam_gitlab_oidc"

  name                = local.name
  gitlab_url          = var.gitlab_url
  gitlab_project_path = var.gitlab_project_path
  gitlab_project_id   = var.gitlab_project_id
  ecr_repository_arns = values(module.ecr.repository_arns)
  tags                = local.tags
}

# --- IRSA scaffolding (policies used by Topics 05 / 07) ---

data "aws_iam_policy_document" "external_dns" {
  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
    ]
    resources = ["arn:aws:route53:::hostedzone/${module.dns.zone_id}"]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource",
    ]
    resources = ["*"]
  }
}

module "irsa_external_dns" {
  source = "../../modules/irsa"

  name              = "${local.name}-external-dns"
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  namespace         = "external-dns"
  service_account   = "external-dns"
  policy_json       = data.aws_iam_policy_document.external_dns.json
  tags              = local.tags
}

data "aws_iam_policy_document" "aws_lb_controller" {
  # Condensed controller permissions — sufficient for ALB Ingress pilot.
  # TODO(setup:5.1): diff against latest AWS sample policy if IAM Access Denied appears.
  statement {
    effect = "Allow"
    actions = [
      "iam:CreateServiceLinkedRole",
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeVpcs",
      "ec2:DescribeVpcPeeringConnections",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeInstances",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeTags",
      "ec2:GetCoipPoolUsage",
      "ec2:DescribeCoipPools",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeListenerAttributes",
      "elasticloadbalancing:DescribeListenerCertificates",
      "elasticloadbalancing:DescribeSSLPolicies",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:DescribeTags",
      "cognito-idp:DescribeUserPoolClient",
      "acm:ListCertificates",
      "acm:DescribeCertificate",
      "iam:ListServerCertificates",
      "iam:GetServerCertificate",
      "shield:GetSubscriptionState",
      "shield:DescribeProtection",
      "shield:CreateProtection",
      "shield:DeleteProtection",
      "waf-regional:GetWebACL",
      "waf-regional:GetWebACLForResource",
      "waf-regional:AssociateWebACL",
      "waf-regional:DisassociateWebACL",
      "wafv2:GetWebACL",
      "wafv2:GetWebACLForResource",
      "wafv2:AssociateWebACL",
      "wafv2:DisassociateWebACL",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:CreateSecurityGroup",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:DeleteSecurityGroup",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:DeleteRule",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:SetWebAcl",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyListenerAttributes",
      "elasticloadbalancing:AddListenerCertificates",
      "elasticloadbalancing:RemoveListenerCertificates",
      "elasticloadbalancing:ModifyRule",
    ]
    resources = ["*"]
  }
}

module "irsa_aws_lb_controller" {
  source = "../../modules/irsa"

  name              = "${local.name}-aws-lb-controller"
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  namespace         = "kube-system"
  service_account   = "aws-load-balancer-controller"
  policy_json       = data.aws_iam_policy_document.aws_lb_controller.json
  tags              = local.tags
}

data "aws_iam_policy_document" "external_secrets" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]
    # TODO(setup:7.4): scope to project prefix ARNs once secret naming is fixed
    resources = ["*"]
  }
}

module "irsa_external_secrets" {
  source = "../../modules/irsa"

  name              = "${local.name}-external-secrets"
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  namespace         = "external-secrets"
  service_account   = "external-secrets"
  policy_json       = data.aws_iam_policy_document.external_secrets.json
  tags              = local.tags
}
