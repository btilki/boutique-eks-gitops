# 19 — Edge WAF + runtime Falco (stubs)

Audience: L2 — Implementer  
Estimated time: 1–2 hours (scaffold now; enable selectively after rebuild)  
Prerequisites: Topic [04](04-network-eks-ecr-iam.md) for WAF Terraform; Topics [05](05-ingress-dns-tls.md)+[06](06-argocd-bootstrap.md) for Ingress/AppProject; Topic [08](08-observability.md) helpful for Falco log visibility  
Creates: `terraform/modules/waf` + `enable_waf` flag; Falco values + ApplicationSet example; Ingress WAF annotation example; [ADR-0010](../adr/0010-edge-waf-and-falco.md)  
Related ADRs: [0008](../adr/0008-argocd-appprojects-sso.md) · [0010](../adr/0010-edge-waf-and-falco.md)  
Pins: Falco chart **4.19.3** (target) · WAFv2 REGIONAL ([docs/versions.md](../versions.md))

---

## Topic goal

Scaffold **edge** protection (**AWS WAFv2** on ALBs) and **runtime** detection (**Falco**) for a fuller DevSecOps posture — both **off by default** so short rebuilds stay cheap and quiet.

## Why this topic is required

ACM+ALB+NetworkPolicy stop neither common L7 exploits at the edge nor suspicious syscalls in the cluster. Topic 19 encodes the enable path without forcing cost during scaffold.

## Before you begin

**Scaffold-only:**

- Confirm Creates files; `enable_waf` remains **false**; Falco is **not** in live `platform-apps`.

**Apply after rebuild:**

- Terraform foundation applied (Topic 04+).
- Boutique/Argo Ingresses working before associating WAF.
- Accept Falco DaemonSet cost/noise before enabling.

**Idempotent:** `enable_waf=false` creates zero WAF resources. Falco example file is not auto-synced (`.yaml.example`).

---

## Step 19.1: Confirm scaffold files

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"

test -f docs/setup/19-edge-runtime-waf-falco.md
test -f docs/adr/0010-edge-waf-and-falco.md
test -f terraform/modules/waf/main.tf
test -f gitops/platform/falco/values.yaml
test -f gitops/apps/platform-apps/falco-applicationset-snippet.yaml.example
test -f examples/waf-ingress-annotation.example.yaml
grep -q 'enable_waf' terraform/envs/prod/variables.tf
grep -q 'module "waf"' terraform/envs/prod/main.tf
grep -q 'waf_web_acl_arn' terraform/envs/prod/outputs.tf
```

### Expected output

All checks exit 0.

---

## Step 19.2: Review WAF module (disabled)

### Commands

```bash
cd "$(git rev-parse --show-toplevel)/terraform/envs/prod"
grep -A8 'variable "enable_waf"' variables.tf
grep -A10 'module "waf"' main.tf
```

### Expected output

`enable_waf` default **false**; module wired; output `waf_web_acl_arn` present.

### Security notes

Managed rule groups can block legitimate traffic — enable on **stage** Ingress first when testing.

---

## Step 19.3: Apply after rebuild — enable WAF

> **Apply after cluster rebuild.** Skip to keep $0 WAF cost.

### Goal

Create Web ACL and attach to ALB via Ingress annotation.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)/terraform/envs/prod"

# In terraform.tfvars:
#   enable_waf = true

terraform plan -out=waf.tfplan
# Review: aws_wafv2_web_acl only (when flipping false→true)
terraform apply waf.tfplan

ACL_ARN="$(terraform output -raw waf_web_acl_arn)"
echo "$ACL_ARN"
```

Add annotation to env Ingress values (frontend / argocd / grafana as desired):

```yaml
alb.ingress.kubernetes.io/wafv2-acl-arn: "<ACL_ARN>"
```

See [`examples/waf-ingress-annotation.example.yaml`](../../examples/waf-ingress-annotation.example.yaml).

Commit → Argo sync → verify in AWS console WAF → Associated AWS resources.

### Validation

```bash
aws wafv2 list-web-acls --scope REGIONAL --region eu-central-1
# Confirm ALB association after Ingress reconcile
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Annotation ignored | LB Controller version / IRSA | Confirm wafv2 Associate in IRSA policy (Topic 04) |
| 403 on storefront | Managed rule false positive | Count mode / rule exception (out of scope stub) |
| terraform creates nothing | enable_waf still false | Set true in tfvars |

---

## Step 19.4: Apply after rebuild — enable Falco (optional)

> **Higher noise/cost.** Prefer after WAF or alone on stage-sized clusters.

### Goal

Install Falco DaemonSet via Argo.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"

# 1) AppProject: add sourceRepo https://falcosecurity.github.io/charts
#    and destination namespace falco to boutique-platform.yaml — MR + sync argocd-hardening

# 2) Either merge list element from falco-applicationset-snippet.yaml.example
#    into platform-apps ApplicationSet, OR kubectl/argocd apply after copying
#    the example to a tracked .yaml (only when ready)

less gitops/apps/platform-apps/falco-applicationset-snippet.yaml.example
less gitops/platform/falco/values.yaml

# 3) Sync
argocd app sync falco --grpc-web
kubectl -n falco get pods -o wide
```

### Validation

```bash
kubectl -n falco logs -l app.kubernetes.io/name=falco --tail=50
# Expect JSON syscall events; tune rules before prod paging
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| AppProject denied chart | sourceRepos missing | Step 19.4 AppProject edit |
| Driver errors | wrong driver kind | Keep `modern-bpf` on EKS 1.31 |
| Example synced accidentally | Renamed to `.yaml` under apps/ | Keep `.yaml.example` until ready |

### Security notes

Falco is detection, not prevention. Pair with Kyverno admission (Topics 07/15); do not treat Falco as a substitute for digest/signature policy.

---

## Step 19.5: Topic validation (scaffold)

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"

test -f docs/setup/19-edge-runtime-waf-falco.md
test -f docs/adr/0010-edge-waf-and-falco.md
test -f terraform/modules/waf/main.tf
test -f gitops/platform/falco/values.yaml
grep -q 'falco' gitops/apps/platform-apps/applicationset.yaml && exit 1 || true
# Falco must NOT be in live ApplicationSet yet
make docs-check
```

### Validation checklist

| Check | Scaffold | After rebuild |
|-------|----------|---------------|
| WAF module + enable_waf=false | Required | Flip when needed |
| Falco values + example AppSet | Required | Opt-in sync |
| Falco **absent** from live platform-apps | Required | Until Step 19.4 |
| ADR-0010 | Required | — |

---

## Topic troubleshooting

| Symptom | Cause | Recovery |
|---------|-------|----------|
| WAF bill surprise | enable_waf left true | Set false + destroy ACL; remove annotations |
| Falco node pressure | DaemonSet on all nodes | Disable app; tune resources |

## Related

- WAF module: [`terraform/modules/waf/`](../../terraform/modules/waf/)
- Falco: [`gitops/platform/falco/`](../../gitops/platform/falco/)
- Prior: [04](04-network-eks-ecr-iam.md) · [05](05-ingress-dns-tls.md) · [17](17-argocd-hardening.md)
