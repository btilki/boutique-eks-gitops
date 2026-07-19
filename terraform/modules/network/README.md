# Network module
#
# Purpose: VPC with public/private subnets, **single NAT**, S3 + ECR VPC endpoints.
# Inputs: name, vpc_cidr, azs, tags
# Outputs: vpc_id, subnet IDs, nat_gateway_id
# Deps: none
# Usage: see terraform/envs/prod/main.tf · Setup Topic 04
#
# Cost: NAT Gateway hours dominate — destroy in Topic 14.
