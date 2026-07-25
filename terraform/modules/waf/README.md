# WAFv2 module — Topic 19 scaffold
#
# Creates a REGIONAL Web ACL with AWS Managed Rules when `enabled = true`.
# Associate to ALBs via Ingress annotation (preferred for this repo):
#   alb.ingress.kubernetes.io/wafv2-acl-arn: <web_acl_arn>
#
# LB Controller IRSA already allows wafv2 Associate/Disassociate (terraform/envs/prod).

## Usage

```hcl
module "waf" {
  source  = "../../modules/waf"
  enabled = var.enable_waf
  name    = "${local.name}-alb"
  tags    = local.tags
}
```

Default `enable_waf = false` — no AWS cost until flipped.
