# Terraform & provider version pins — boutique-eks-gitops envs/prod
# Authority: docs/versions.md · Setup Topics 03–04

terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"

  default_tags {
    tags = {
      Project   = "boutique-eks-gitops"
      ManagedBy = "terraform"
    }
  }
}
