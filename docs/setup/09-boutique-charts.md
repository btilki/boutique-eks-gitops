# 09 — Boutique charts

Audience: L2 — Implementer  
Estimated time: 3–4 hours  
Prerequisites: [08 — Observability](08-observability.md) complete (M2)  
Creates: Helm charts under `charts/*`; env digest overlays; Argo boutique ApplicationSet; **bootstrap ECR digests**; `dev-boutique` HTTPS  
Related ADRs: [0001](../adr/0001-digest-only-gitops.md) · [0004](../adr/0004-dns-hostname-scheme.md)

---

## Topic goal

Run the scoped Online Boutique storefront on GitOps digests: charts + env overlays + one-time ECR image bootstrap so Argo can sync **before** the first CI digest pipeline (Topic 10).

## Why this topic is required

CI only patches digests — it cannot invent first images. Charts must expose `image.repository` + `image.digest`, and ECR must hold signed/bootstrap digests Kyverno will allow.

## Before you begin

- Topics 06–08 healthy; ACM ARN available.
- ECR repos exist (Topic 04) including **`redis`** (added to Terraform list — re-apply `module.ecr` if missing).
- Docker (or `nerdctl`/`podman`) available to pull upstream Boutique images and push to ECR.
- Phase B Topic 09 files on `main`.

**Cost:** ECR storage + ALB for `dev-boutique` Ingress.

**Idempotent:** Re-push digests and re-sync Argo is safe. Prod remains **manual sync**.

---

## Step 9.1: Review Helm charts and image contract

### Goal

Confirm every chart pins images via `repository` + `digest` (no tags in the rendered Pod spec).

### Why this step is required

Kyverno require-digest / ECR allowlist (Topic 07) will block non-compliant Pods.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"

ls charts/
for c in frontend productcatalogservice cartservice checkoutservice \
         currencyservice paymentservice shippingservice redis; do
  echo "== $c =="
  grep -E 'repository:|digest:' "charts/$c/values.yaml"
  helm template "t-$c" "charts/$c" | grep -E 'image:' | head -3
done
```

### GUI instructions (if applicable)

N/A.

### Expected output

Rendered images look like `…@sha256:aaaa…` (placeholder until Step 9.2).

### Validation

```bash
helm lint charts/frontend charts/cartservice charts/redis
test -f gitops/apps/workload-apps/boutique-applicationset.yaml
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| helm not found | Topic 01 | Install Helm 3.16.x |
| lint fail | Template error | Fix chart; re-run generator/review |

### Recovery

Fix chart YAML; do not weaken Kyverno.

### Best practices

Keep `fullnameOverride` equal to service DNS name expected by frontend env vars.

### Security notes

Never add `:latest` to chart templates.

---

## Step 9.2: Bootstrap ECR digests (one-time)

### Goal

Pull is not available for v0.10.6 — **build** Online Boutique from GitHub (and Redis from public ECR), push to project ECR, record digests into env values.

### Why this step is required

First Argo sync needs digests in ECR before GitLab CI exists (locked plan decision).

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"
export AWS_REGION=eu-central-1
export ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
export REGISTRY="${ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com"
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "$REGISTRY"

# Ensure redis repo exists (terraform apply if needed)
aws ecr describe-repositories --repository-names boutique-eks-gitops/redis --region "$AWS_REGION" \
  || terraform -chdir=terraform/envs/prod apply -target=module.ecr -auto-approve

# Boutique v0.10.6 is not publicly pullable from Artifact Registry / gcr.
# Build from the GitHub release tag (same approach as Topic 10 CI).
TAG="v0.10.6"
WORKDIR="/tmp/microservices-demo-${TAG}"
PLATFORM="linux/amd64"

if [ ! -d "$WORKDIR/.git" ]; then
  rm -rf "$WORKDIR"
  git clone --depth 1 --branch "$TAG" \
    https://github.com/GoogleCloudPlatform/microservices-demo.git "$WORKDIR"
fi

mkdir -p /tmp/boutique-digests
: > /tmp/boutique-digests/digests.txt

while IFS='|' read -r svc ctx; do
  [ -z "$svc" ] && continue
  dst="${REGISTRY}/boutique-eks-gitops/${svc}"
  docker build --platform "$PLATFORM" -t "${dst}:bootstrap" "${WORKDIR}/${ctx}"
  docker push "${dst}:bootstrap"
  ecr_dig=$(aws ecr describe-images --repository-name "boutique-eks-gitops/${svc}" \
    --image-ids imageTag=bootstrap --region "$AWS_REGION" \
    --query 'imageDetails[0].imageDigest' --output text)
  echo "${svc}=${ecr_dig}" | tee -a /tmp/boutique-digests/digests.txt
done <<'SERVICES'
frontend|src/frontend
productcatalogservice|src/productcatalogservice
cartservice|src/cartservice/src
checkoutservice|src/checkoutservice
currencyservice|src/currencyservice
paymentservice|src/paymentservice
shippingservice|src/shippingservice
SERVICES

docker pull --platform "$PLATFORM" public.ecr.aws/docker/library/redis:7.2-alpine
docker tag public.ecr.aws/docker/library/redis:7.2-alpine "${REGISTRY}/boutique-eks-gitops/redis:bootstrap"
docker push "${REGISTRY}/boutique-eks-gitops/redis:bootstrap"
ecr_dig=$(aws ecr describe-images --repository-name "boutique-eks-gitops/redis" \
  --image-ids imageTag=bootstrap --region "$AWS_REGION" \
  --query 'imageDetails[0].imageDigest' --output text)
echo "redis=${ecr_dig}" | tee -a /tmp/boutique-digests/digests.txt

cat /tmp/boutique-digests/digests.txt
```

**Note:** ECR tag mutability is **IMMUTABLE** in Terraform — `bootstrap` tag can only be pushed once. If re-running, use a new tag (`bootstrap2`) or push by digest-only workflows. Prefer one successful bootstrap.

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | AWS Console → ECR |
| Navigation | Repositories → `boutique-eks-gitops/*` |
| Verification | Each repo has an image; copy Image digest `sha256:…` |

### Expected output

Eight digests listed in `/tmp/boutique-digests/digests.txt`.

### Validation

```bash
wc -l /tmp/boutique-digests/digests.txt
# expect 8
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `TagAlreadyExistsException` | Immutable tag reused | Use new tag name; update describe-images |
| Upstream build fail | Dockerfile / network | Fix context path; retry; use `bootstrap2` if tag immutable |
| Redis repo missing | TF not applied | Apply `module.ecr` |

### Recovery

Do not delete all ECR images casually; push with a new tag and record that digest.

### Best practices

Save `digests.txt` privately for the commit in Step 9.3.

### Security notes

Bootstrap images are not yet CI-signed; Topic 10 adds Sigstore signing for subsequent builds. Kyverno still requires digest + ECR.

---

## Step 9.3: Wire `gitops/envs/dev` digests + Ingress

### Goal

Update `gitops/envs/dev/values/*.yaml` with account ID, real digests, and ACM ARN on frontend Ingress.

### Why this step is required

Argo Helm apps read digests only from env overlays.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"
export ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
export ACM_ARN=$(terraform -chdir=terraform/envs/prod output -raw acm_certificate_arn)

# Replace account + ACM across env values
find gitops/envs -name '*.yaml' -print0 | xargs -0 sed -i '' "s/REPLACE_ACCOUNT/${ACCOUNT}/g"
find gitops/envs -name 'frontend.yaml' -print0 | xargs -0 sed -i '' "s|<ACM_CERTIFICATE_ARN>|${ACM_ARN}|g"
# Linux: sed -i

# Apply digests from Step 9.2 file
while IFS='=' read -r svc dig; do
  for env in dev stage prod; do
    f="gitops/envs/${env}/values/${svc}.yaml"
    # replace digest line
    sed -i '' "s|digest: \".*\"|digest: \"${dig}\"|" "$f"
  done
done < /tmp/boutique-digests/digests.txt

grep -E 'repository:|digest:|certificate-arn|host:' gitops/envs/dev/values/frontend.yaml
```

Commit and push to `main`.

### GUI instructions (if applicable)

N/A — Git commit/MR as usual.

### Expected output

Dev frontend values show real account, real `sha256:…`, ACM ARN, host `dev-boutique.biroltilki.art`.

### Validation

```bash
! grep -q REPLACE_ACCOUNT gitops/envs/dev/values/*.yaml
! grep -q '<ACM_CERTIFICATE_ARN>' gitops/envs/dev/values/frontend.yaml
! grep -q 'sha256:aaaaaaaa' gitops/envs/dev/values/*.yaml
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Placeholder remains | sed path | Re-run substitutions; verify file paths |

### Recovery

Restore values from Git; re-apply digests carefully.

### Best practices

Same digests initially on stage/prod overlays; promotion later copies digests deliberately (Topic 11).

### Security notes

Account ID in Git is OK for this pilot; still no secrets.

---

## Step 9.4: Confirm stage/prod overlays scaffolded

### Goal

Ensure stage/prod values exist with same digest pins and correct hostnames (prod not auto-synced).

### Why this step is required

Promotion MRs only change digests — structure must already exist.

### Commands

```bash
ls gitops/envs/stage/values gitops/envs/prod/values
grep host: gitops/envs/stage/values/frontend.yaml gitops/envs/prod/values/frontend.yaml
grep autoSync gitops/apps/workload-apps/boutique-applicationset.yaml
```

### GUI instructions (if applicable)

N/A.

### Expected output

stage host `stage-boutique…`; prod host `boutique.biroltilki.art`; prod `autoSync: false`.

### Validation

```bash
grep -q 'autoSync: false' gitops/apps/workload-apps/boutique-applicationset.yaml && echo "prod manual: OK"
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Missing values | Incomplete Phase B | Restore Topic 09 files |

### Recovery

Re-copy overlays from Phase B delivery; re-run digest substitution.

### Best practices

Do not enable prod auto-sync when debugging.

### Security notes

Prod manual sync remains mandatory.

---

## Step 9.5: Argo sync Boutique (dev) and verify HTTPS

### Goal

Sync ApplicationSet apps for `dev` and prove `https://dev-boutique.biroltilki.art`.

### Why this step is required

Storefront reachability validates charts + Ingress + digests end-to-end.

### Commands

```bash
# Ensure ApplicationSet URL substituted & pushed
kubectl -n argocd get applicationset boutique-workloads
argocd app list --grpc-web | grep -- '-dev'

# Sync redis first, then services, then frontend (or sync all -dev)
for app in redis-dev productcatalogservice-dev currencyservice-dev cartservice-dev \
           paymentservice-dev shippingservice-dev checkoutservice-dev frontend-dev; do
  argocd app sync "$app" --grpc-web || true
done

kubectl -n dev get pods
kubectl -n dev get ingress
dig +short dev-boutique.biroltilki.art
curl -I --max-time 60 https://dev-boutique.biroltilki.art
```

Expected duration: image pulls 2–10 minutes first time.

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | Argo CD UI |
| Navigation | Filter `boutique-env:dev` → SYNC |
| Verification | Apps Healthy; browser opens storefront |
| Prod | Leave OutOfSync until manual sync intentionally |

### Expected output

Pods Running in `dev`; HTTPS 200/302 on `dev-boutique.biroltilki.art`.

![Online Boutique storefront — `dev-boutique.biroltilki.art`](../../assets/images/setup/09-boutique-dev-homepage.png)

### Validation

```bash
kubectl -n dev get pods --no-headers | awk '{print $3}' | sort | uniq -c
curl -fsS -o /dev/null -w "%{http_code}\n" https://dev-boutique.biroltilki.art
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| ImagePullBackOff | Bad digest / repo | Re-check ECR digest; values repository |
| Kyverno deny | Tag used / wrong registry | Ensure `@sha256` and account ECR host |
| Frontend 5xx | Downstream not ready | Wait for cart/catalog pods; check logs |
| Prod accidentally synced | UI sync | Avoid; ok if only namespaces |

### Recovery

Fix values; hard refresh app; delete failing pods after policy fix.

### Best practices

Sync `redis-dev` before `cartservice-dev`.

### Security notes

Do not sync prod until Topic 11 promotion deliberately.

---

## Step 9.6: Topic validation (gate to Topic 10)

### Goal

Confirm Boutique GitOps path ready for digest-only CI.

### Why this step is required

Topic 10 assumes charts + ECR + env overlays exist.

### Commands

```bash
test -d charts/frontend && test -d charts/redis
kubectl -n dev get deploy,svc,ingress
curl -fsS -o /dev/null -w "%{http_code}\n" https://dev-boutique.biroltilki.art
kubectl -n argocd get applicationset boutique-workloads
```

### GUI instructions (if applicable)

N/A.

### Expected output

Checklist complete.

### Validation

- [ ] Eight charts present (7 services + redis) (9.1)
- [ ] Bootstrap digests in ECR (9.2)
- [ ] `gitops/envs/dev` digests + ACM set (9.3)
- [ ] stage/prod overlays present; prod manual (9.4)
- [ ] `dev-boutique` HTTPS works (9.5)
- [ ] No `:latest` in rendered Boutique pods

### Common problems

Partial pod failures — fix before CI or CI will promote broken digests.

### Recovery

Stabilize dev; only then proceed to Topic 10.

### Best practices

Record digest list in session notes for first CI comparison.

### Security notes

Bootstrap images unsigned until Topic 10 — acceptable one-time exception documented in plan.

---

## Topic validation (end-to-end)

Topic 09 is complete when Step 9.6 checklist passes.

**Cost check:** Dev ALB + ECR storage active; teardown Topic 14.

---

## Topic troubleshooting

| Area | Symptom | Action |
|------|---------|--------|
| Helm | Multi-source AppSet error | Confirm `$values/...` paths and GITLAB_REPO_URL |
| Immutable tag | Cannot re-push `bootstrap` | New tag + new digest |
| Kyverno | Blocks redis public ECR | Must use project ECR mirror |
| Frontend | gRPC errors | Confirm service names match `fullnameOverride` |

---

## Next step

**[10 — GitLab CI digests](10-gitlab-ci-digest.md)** (Phase B next).

CI will rebuild/sign and open MRs that change **only** `image.digest` under `gitops/envs/dev/values/`.
