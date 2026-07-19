# 05 — Ingress, DNS, TLS

Audience: L2 — Implementer  
Estimated time: 1.5–2.5 hours  
Prerequisites: [04 — Network, EKS, ECR, IAM](04-network-eks-ecr-iam.md) complete (nodes Ready, ACM **ISSUED**, IRSA ARNs available)  
Creates: Helm-installed AWS LB Controller, external-dns, cert-manager; GitOps values under `gitops/platform/{aws-load-balancer-controller,external-dns,cert-manager}/`; [`docs/dns-and-tls.md`](../dns-and-tls.md); temporary [`examples/smoke-ingress.yaml`](../../examples/smoke-ingress.yaml)  
Related ADRs: [0003](../adr/0003-tls-acm-alb.md) · [0004](../adr/0004-dns-hostname-scheme.md)  
**Milestone:** **M1 — Cluster reachable (HTTPS smoke)**

---

## Topic goal

Expose HTTPS on boutique DNS via ACM + ALB, with external-dns managing records, proving the ingress path before Argo CD (Topic 06).

## Why this topic is required

Without a working Ingress → ALB → ACM → Route53 path, Argo/Grafana/Boutique hostnames cannot be validated. This topic is **Milestone M1**.

## Before you begin

- `kubectl get nodes` shows Ready.
- `terraform -chdir=terraform/envs/prod output -raw acm_certificate_arn` and IRSA role outputs work.
- Helm 3.16.x available (Topic 01).
- Phase B files for Topic 05 present in the repo.
- **Cost:** ALB hours while smoke Ingress exists — delete smoke when done; controllers are low incremental cost on existing nodes.

**Idempotent:** `helm upgrade --install` is safe to re-run. Re-applying smoke Ingress is safe.

**Note:** Controllers are installed with **Helm** now; Argo Applications under each platform path are adopted in Topic 06 (`TODO(setup:6.5)`).

---

## Step 5.1: Bind IRSA in Helm values

### Goal

Replace placeholders in platform `values.yaml` files with Terraform IRSA ARNs, cluster name, VPC ID, and Route53 zone ID.

### Why this step is required

Without correct `eks.amazonaws.com/role-arn` annotations, controllers cannot call AWS APIs (ALB create / Route53 upsert).

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"
cd terraform/envs/prod

export CLUSTER_NAME=$(terraform output -raw cluster_name)
export VPC_ID=$(terraform output -raw vpc_id)
export ACM_ARN=$(terraform output -raw acm_certificate_arn)
export IRSA_LB=$(terraform output -raw irsa_aws_lb_controller_role_arn)
export IRSA_DNS=$(terraform output -raw irsa_external_dns_role_arn)
export ZONE_ID=$(terraform output -raw route53_zone_id)

cd ../..

# LB controller values
sed -i '' "s|<CLUSTER_NAME>|${CLUSTER_NAME}|g" gitops/platform/aws-load-balancer-controller/values.yaml
sed -i '' "s|<VPC_ID>|${VPC_ID}|g" gitops/platform/aws-load-balancer-controller/values.yaml
sed -i '' "s|<IRSA_ROLE_ARN>|${IRSA_LB}|g" gitops/platform/aws-load-balancer-controller/values.yaml

# external-dns values
sed -i '' "s|<IRSA_ROLE_ARN>|${IRSA_DNS}|g" gitops/platform/external-dns/values.yaml
sed -i '' "s|<ZONE_ID>|${ZONE_ID}|g" gitops/platform/external-dns/values.yaml
sed -i '' "s|<DOMAIN_FILTER>|biroltilki.art|g" gitops/platform/external-dns/values.yaml

# Linux: use sed -i without ''

grep -E 'role-arn|clusterName|vpcId|zoneIdFilters' \
  gitops/platform/aws-load-balancer-controller/values.yaml \
  gitops/platform/external-dns/values.yaml
```

**Do not commit** live account ARNs if your org forbids it — keep substituted values local or use a private overlay. For this pilot, committing non-secret ARNs is acceptable; never commit AWS keys.

### GUI instructions (if applicable)

N/A — editor search/replace is fine if you prefer not to use `sed`.

### Expected output

No remaining `<IRSA_ROLE_ARN>`, `<CLUSTER_NAME>`, `<VPC_ID>`, `<ZONE_ID>`, or `<DOMAIN_FILTER>` placeholders in those two values files.

### Validation

```bash
! grep -E '<IRSA_ROLE_ARN>|<CLUSTER_NAME>|<VPC_ID>|<ZONE_ID>|<DOMAIN_FILTER>' \
  gitops/platform/aws-load-balancer-controller/values.yaml \
  gitops/platform/external-dns/values.yaml && echo "placeholders: OK"
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Empty terraform output | Topic 04 incomplete | Finish 04 validation |
| sed no-op on Linux | BSD sed flag | Use `sed -i` without `''` |

### Recovery

Restore values from Git and re-run substitutions.

### Best practices

Export outputs once into your shell session for Steps 5.2–5.6.

### Security notes

IRSA roles are scoped; do not annotate app pods with the LB controller role.

---

## Step 5.2: Install AWS Load Balancer Controller

### Goal

Install controller **v2.11.x** via Helm chart **1.11.4** into `kube-system`.

### Why this step is required

Ingress resources cannot provision ALBs without this controller.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"

helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --version 1.11.4 \
  --values gitops/platform/aws-load-balancer-controller/values.yaml \
  --wait

kubectl -n kube-system get deploy aws-load-balancer-controller
kubectl -n kube-system rollout status deploy/aws-load-balancer-controller
```

Expected duration: 1–3 minutes.

### GUI instructions (if applicable)

N/A.

### Expected output

Deployment available; pods `Running` / Ready.

### Validation

```bash
kubectl -n kube-system get pods -l app.kubernetes.io/name=aws-load-balancer-controller
kubectl get ingressclass alb
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Pods `Unauthorized` / AWS errors | Bad IRSA annotation / trust | Re-check role ARN and SA name `aws-load-balancer-controller` in `kube-system` |
| Chart version missing | Repo outdated | `helm repo update`; confirm chart 1.11.4 exists |

### Recovery

`helm upgrade --install` again after fixing values; check controller logs:

```bash
kubectl -n kube-system logs deploy/aws-load-balancer-controller --tail=100
```

### Best practices

Keep replicaCount ≥ 2 for controller HA on the pilot.

### Security notes

Controller can create AWS load balancers — limit who can create Ingresses in later NetworkPolicy/RBAC hardening.

---

## Step 5.3: Install external-dns

### Goal

Install external-dns **v0.15.x** watching Ingresses for zone `biroltilki.art`.

### Why this step is required

Manual Route53 edits do not scale; Argo/Grafana/Boutique hosts must be automated.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"

helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
helm repo update

kubectl create namespace external-dns --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install external-dns external-dns/external-dns \
  --namespace external-dns \
  --version 1.15.0 \
  --values gitops/platform/external-dns/values.yaml \
  --wait

kubectl -n external-dns rollout status deploy/external-dns
```

### GUI instructions (if applicable)

N/A.

### Expected output

Pods Ready in `external-dns`.

### Validation

```bash
kubectl -n external-dns get pods
kubectl -n external-dns logs deploy/external-dns --tail=50 | grep -iE 'error|zone' || true
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| AccessDenied Route53 | IRSA policy / wrong zone ID | Confirm `zoneIdFilters` and Topic 04 IRSA |
| Wrong namespace | SA trust mismatch | Must be namespace `external-dns`, SA `external-dns` |

### Recovery

Fix values; helm upgrade; verify IAM role trust `sub` matches.

### Best practices

Keep `txtOwnerId: boutique-eks-gitops` unique per cluster managing this zone.

### Security notes

`policy: sync` can delete records it owns — do not point at production zones you do not control.

---

## Step 5.4: Install cert-manager

### Goal

Install cert-manager **v1.16.x** for platform readiness (not primary public TLS).

### Why this step is required

Architecture requires cert-manager present; public boutique TLS remains ACM ([ADR-0003](../adr/0003-tls-acm-alb.md)).

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"

helm repo add jetstack https://charts.jetstack.io
helm repo update

kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v1.16.2 \
  --values gitops/platform/cert-manager/values.yaml \
  --wait

kubectl -n cert-manager get pods
```

### GUI instructions (if applicable)

N/A.

### Expected output

`cert-manager`, `cert-manager-webhook`, `cert-manager-cainjector` pods Ready.

### Validation

```bash
kubectl -n cert-manager get deploy
kubectl get crd | grep cert-manager.io
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| CRDs missing | values `crds.enabled` false | Ensure values enable CRDs; re-upgrade |

### Recovery

Re-run helm upgrade with documented version; do not mix major versions.

### Best practices

Do not create a public DNS-01 ClusterIssuer for boutique hosts in v1 — stick to ACM.

### Security notes

Webhook failure can block cert resources; for this pilot, ACM path does not depend on it.

---

## Step 5.5: Confirm ACM certificate for boutique hosts

### Goal

Re-validate ACM certificate is **ISSUED** and document ARN in [`docs/dns-and-tls.md`](../dns-and-tls.md) workflow (already authored).

### Why this step is required

Smoke Ingress HTTPS fails if the cert is pending or wrong region.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)/terraform/envs/prod"
terraform output -raw acm_certificate_arn
aws acm describe-certificate \
  --certificate-arn "$(terraform output -raw acm_certificate_arn)" \
  --region eu-central-1 \
  --query 'Certificate.{Status:Status,SANs:SubjectAlternativeNames}' --output yaml
```

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | AWS Console |
| Navigation | **ACM** → Certificates → boutique cert (`eu-central-1`) |
| Permissions | `acm:DescribeCertificate` |
| Verification | Status **Issued**; SANs include `*.boutique.biroltilki.art` |

### Expected output

Status `ISSUED`.

### Validation

```bash
test "$(aws acm describe-certificate --certificate-arn "$(terraform output -raw acm_certificate_arn)" --region eu-central-1 --query 'Certificate.Status' --output text)" = "ISSUED"
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Pending | Topic 04 DNS validation incomplete | Return to Topic 04 Step 4.6 |

### Recovery

Do not request a second duplicate cert ad-hoc; fix Terraform-managed cert.

### Best practices

Use the same ARN on all public Ingresses in this pilot.

### Security notes

Certificate private keys never leave ACM.

---

## Step 5.6: Apply temporary smoke Ingress

### Goal

Deploy `examples/smoke-ingress.yaml` with ACM ARN substituted to create ALB + DNS for `smoke.boutique.biroltilki.art`.

### Why this step is required

End-to-end proof of controller + DNS + TLS before platform UIs exist.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"
export ACM_ARN=$(terraform -chdir=terraform/envs/prod output -raw acm_certificate_arn)

cp examples/smoke-ingress.yaml /tmp/smoke-ingress.yaml
sed -i '' "s|<ACM_CERTIFICATE_ARN>|${ACM_ARN}|g" /tmp/smoke-ingress.yaml
# Linux: sed -i

grep certificate-arn /tmp/smoke-ingress.yaml
kubectl apply -f /tmp/smoke-ingress.yaml

kubectl -n smoke-m1 get ingress smoke-echo -w
# Wait until ADDRESS is populated (ALB DNS name). Ctrl+C when set.
```

Expected duration: ALB provisioning often **3–8 minutes**; DNS TTL may add 1–2 minutes.

**Cost impact:** Application Load Balancer hourly charge while the Ingress exists.

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | AWS Console |
| Navigation | **EC2** → **Load Balancers** → look for k8s-created ALB |
| Verification | Scheme internet-facing; HTTPS:443 listener; ACM cert attached |
| Route 53 | Hosted zone `biroltilki.art` → record `smoke.boutique.biroltilki.art` (A/ALIAS) |

### Expected output

Ingress `ADDRESS` shows `*.elb.amazonaws.com`. Route53 record appears for smoke host.

### Validation

```bash
kubectl -n smoke-m1 get ingress smoke-echo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}{"\n"}'
aws route53 list-resource-record-sets --hosted-zone-id "$(terraform -chdir=terraform/envs/prod output -raw route53_zone_id)" \
  --query "ResourceRecordSets[?Name=='smoke.boutique.biroltilki.art.']" --output table
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| No ADDRESS | LB controller / subnet tags | Check controller logs; confirm public subnet `kubernetes.io/role/elb=1` |
| No DNS record | external-dns | Check logs; annotation hostname; zone filter |
| Placeholder left in YAML | sed failed | Ensure ACM ARN substituted |

### Recovery

Delete and re-apply smoke; fix controllers first if ADDRESS never appears.

```bash
kubectl delete -f /tmp/smoke-ingress.yaml --ignore-not-found
```

### Best practices

Keep smoke only until Step 5.7 passes, then delete to stop ALB charges.

### Security notes

Smoke namespace is intentionally public HTTPS — remove after M1 proof.

---

## Step 5.7: HTTPS curl validation (M1 proof)

### Goal

Prove `https://smoke.boutique.biroltilki.art` returns success over public TLS.

### Why this step is required

This is the **Milestone M1** acceptance check.

### Commands

```bash
# Wait for DNS if needed
dig +short smoke.boutique.biroltilki.art

curl -I --max-time 30 https://smoke.boutique.biroltilki.art
curl -fsS --max-time 30 https://smoke.boutique.biroltilki.art | head -20
```

### GUI instructions (if applicable)

Browser: open `https://smoke.boutique.biroltilki.art` — padlock valid; page from echoserver.

### Expected output

HTTP `200` (or `302`) on `curl -I`; TLS cert valid for the smoke hostname (SAN via `*.boutique.biroltilki.art`).

### Validation

```bash
curl -fsS -o /dev/null -w "%{http_code}\n" https://smoke.boutique.biroltilki.art
# expect 200
echo "M1 smoke HTTPS: OK"
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| SSL error | Wrong cert / not ready | Confirm ACM on listener; wait for ALB |
| Timeout | SG / DNS | Check ALB security groups; dig record |
| 404/502 | Targets unhealthy | Check pods Ready; target type `ip` |

### Recovery

Fix targets/DNS/cert; re-curl. Do not proceed to Topic 06 until M1 passes.

### Best practices

Capture `curl -I` output in session notes as M1 evidence.

### Security notes

After proof, delete smoke to reduce attack surface and cost:

```bash
kubectl delete -f /tmp/smoke-ingress.yaml --ignore-not-found
# or original path if substituted file was applied from examples/ after edit
```

---

## Step 5.8: Topic validation (gate to Topic 06)

### Goal

Confirm controllers healthy, DNS/TLS doc present, M1 proven, smoke cleaned up (or scheduled).

### Why this step is required

Topic 06 installs Argo on the same ingress/DNS foundation.

### Commands

```bash
kubectl -n kube-system get deploy aws-load-balancer-controller
kubectl -n external-dns get deploy external-dns
kubectl -n cert-manager get deploy
test -f docs/dns-and-tls.md
test -f examples/smoke-ingress.yaml
helm list -A | grep -E 'aws-load-balancer-controller|external-dns|cert-manager'
```

### GUI instructions (if applicable)

N/A.

### Expected output

Three Helm releases present; docs exist; M1 curl succeeded earlier.

### Validation

Checklist:

- [ ] IRSA placeholders resolved in values (5.1)
- [ ] AWS LB Controller pods Ready (5.2)
- [ ] external-dns pods Ready (5.3)
- [ ] cert-manager pods Ready + CRDs (5.4)
- [ ] ACM ISSUED (5.5)
- [ ] Smoke Ingress reached HTTPS 200 (5.7) — **M1**
- [ ] Smoke namespace deleted (recommended) or deletion time noted
- [ ] `docs/dns-and-tls.md` reviewed

### Common problems

Any failure — return to matching step; do not bootstrap Argo yet.

### Recovery

Re-run failed step; keep ALB only as long as needed for debug.

### Best practices

Commit GitOps values (with or without ARNs per org policy) before Topic 06 so Argo can adopt the same paths.

### Security notes

Confirm no long-lived smoke ALB left forgotten.

---

## Topic validation (end-to-end)

Topic 05 / **M1** is complete when Step 5.8 checklist passes.

**Cost check:** Delete smoke Ingress/ALB; retain controllers for Topics 06+.

---

## Topic troubleshooting

| Area | Symptom | Action |
|------|---------|--------|
| ALB | Stuck provisioning | Subnet tags, IAM, service-linked role `AWSServiceRoleForElasticLoadBalancing` |
| DNS | Flapping records | Duplicate external-dns owners — ensure single `txtOwnerId` |
| Helm | Drift after manual kubectl | Prefer helm upgrade; later Argo owns (Topic 06) |
| TLS | Browser warns | Wrong host or cert SAN — use `smoke.boutique.biroltilki.art` exactly |

---

## Next step

**[06 — Argo CD bootstrap](06-argocd-bootstrap.md)** (Phase B next).

Argo UI will use `argocd.boutique.biroltilki.art` on this same ACM+ALB path.
