# 03 — Terraform remote state

Audience: L2 — Implementer  
Estimated time: 45–60 minutes  
Prerequisites: [02 — Repo foundation](02-repo-foundation.md) complete  
Creates: S3 state bucket + DynamoDB lock table in `eu-central-1`; repo files `terraform/backend.hcl.example`, `terraform/envs/prod/backend.tf`, `terraform/envs/prod/versions.tf`; local gitignored `terraform/backend.hcl`  
Related ADRs: None (operational bootstrap) · Pins: [docs/versions.md](../versions.md)

---

## Topic goal

Bootstrap durable, locked Terraform remote state so Topic 04 (and later) applies are safe across sessions and do not rely on local `terraform.tfstate` files. State lives in **S3 (Simple Storage Service)** with a DynamoDB lock table.

## Why this topic is required

Without remote state + locking, concurrent applies and laptop loss corrupt infrastructure truth. S3 versioning + DynamoDB locks are the AWS-standard backend for this pilot ([FR-01](../implementation/plan.md)).

## Before you begin

- Topics 01–02 complete (`make docs-check` passes).
- AWS credentials for the **pilot account** (`aws sts get-caller-identity` works in `eu-central-1`).
- IAM permission to create S3 buckets, DynamoDB tables, and use them for state (typically admin for the pilot).
- Phase B files for this topic present in the repo (partner delivery).
- **Cost impact (low):** empty S3 bucket + small DynamoDB table — still destroy in Topic 14.
- **Do not** create VPC/EKS in this topic.

**Idempotent notes:** Re-running `aws s3api create-bucket` / `create-table` fails if names exist — that is OK if you intentionally reuse; validate instead of recreate.

---

## Step 3.1: Choose state bucket and lock table names

### Goal

Pick globally unique S3 bucket name and DynamoDB table name; record them for `backend.hcl`.

### Why this step is required

S3 bucket names are global. Collisions or unclear names cause init failures and orphan resources.

### Commands

```bash
export AWS_REGION=eu-central-1
export AWS_DEFAULT_REGION=eu-central-1

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Account: ${ACCOUNT_ID}"

# Recommended naming (replace if your org has a mandated pattern)
export TF_STATE_BUCKET="boutique-eks-gitops-tfstate-${ACCOUNT_ID}"
export TF_LOCK_TABLE="boutique-eks-gitops-tf-locks"

echo "TF_STATE_BUCKET=${TF_STATE_BUCKET}"
echo "TF_LOCK_TABLE=${TF_LOCK_TABLE}"
```

Store these values in your password manager / private notes. **Do not commit** the account ID in Git if your org forbids it — `backend.hcl` is gitignored.

### GUI instructions (if applicable)

N/A (naming only). Optional console check later in 3.2–3.3.

### Expected output

Printed `TF_STATE_BUCKET` and `TF_LOCK_TABLE` values you will reuse in Steps 3.2–3.5.

### Validation

```bash
test -n "${TF_STATE_BUCKET}" && test -n "${TF_LOCK_TABLE}" && echo "names: OK"
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Empty Account | AWS auth missing | Return to Topic 01 Step 1.6 |
| Bucket name too long | Extra suffixes | Keep `boutique-eks-gitops-tfstate-<12-digit-account>` |

### Recovery

Choose new names before creating resources; renaming after creation means migrating state (avoid).

### Best practices

Include account ID in the bucket name for uniqueness; keep one lock table per pilot.

### Security notes

State files can contain sensitive attribute values later — encrypt the bucket (Step 3.2) and restrict bucket IAM to operators.

---

## Step 3.2: Create S3 bucket (versioning, encryption, public access block)

### Goal

Create the state bucket in `eu-central-1` with versioning, SSE-S3 encryption, and Block Public Access.

### Why this step is required

Versioning enables recovery from bad applies; encryption and public-access block are baseline hardening for state.

### Commands

```bash
# Re-export if new shell
export AWS_REGION=eu-central-1
# export TF_STATE_BUCKET=...  # from Step 3.1

# eu-central-1 requires LocationConstraint
aws s3api create-bucket \
  --bucket "${TF_STATE_BUCKET}" \
  --region eu-central-1 \
  --create-bucket-configuration LocationConstraint=eu-central-1

aws s3api put-bucket-versioning \
  --bucket "${TF_STATE_BUCKET}" \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket "${TF_STATE_BUCKET}" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      },
      "BucketKeyEnabled": true
    }]
  }'

aws s3api put-public-access-block \
  --bucket "${TF_STATE_BUCKET}" \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Optional but recommended: deny non-TLS
aws s3api put-bucket-policy \
  --bucket "${TF_STATE_BUCKET}" \
  --policy "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [{
      \"Sid\": \"DenyInsecureTransport\",
      \"Effect\": \"Deny\",
      \"Principal\": \"*\",
      \"Action\": \"s3:*\",
      \"Resource\": [
        \"arn:aws:s3:::${TF_STATE_BUCKET}\",
        \"arn:aws:s3:::${TF_STATE_BUCKET}/*\"
      ],
      \"Condition\": { \"Bool\": { \"aws:SecureTransport\": \"false\" } }
    }]
  }"
```

**Cost impact:** S3 storage for state objects (small) + versioning storage — low.

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | AWS Console |
| Navigation | **S3** → **Buckets** → **Create bucket** |
| Permissions | `s3:CreateBucket`, `s3:PutEncryptionConfiguration`, `s3:PutBucketVersioning`, `s3:PutBucketPublicAccessBlock` |
| Verification | Bucket appears in `Europe (Frankfurt) eu-central-1`; Public access **Blocked**; Versioning **Enabled** |

| Field | Value | Why |
|-------|-------|-----|
| Bucket name | Same as `TF_STATE_BUCKET` | Must match `backend.hcl` |
| AWS Region | Europe (Frankfurt) `eu-central-1` | Locked region |
| Object Ownership | ACLs disabled (recommended) | Modern default |
| Block Public Access | **All four ON** | State must not be public |
| Bucket Versioning | **Enable** | Recover prior state |
| Default encryption | SSE-S3 (AES-256) | Encrypt state at rest |

Prefer CLI above for reproducibility; GUI is acceptable if outputs match validation.

### Expected output

CLI commands return without error (or `BucketAlreadyOwnedByYou` if you re-run create on your own bucket).

### Validation

```bash
aws s3api get-bucket-versioning --bucket "${TF_STATE_BUCKET}"
aws s3api get-bucket-encryption --bucket "${TF_STATE_BUCKET}"
aws s3api get-public-access-block --bucket "${TF_STATE_BUCKET}"
```

Expect: `Status=Enabled` versioning; `AES256` rule; all public-access flags `true`.

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `BucketAlreadyExists` | Name taken globally | Change `TF_STATE_BUCKET`; re-run 3.1–3.2 |
| `IllegalLocationConstraintException` | Wrong create-bucket args | Use `LocationConstraint=eu-central-1` as shown |
| AccessDenied | IAM gap | Elevate pilot role / attach S3 admin for bootstrap |

### Recovery

If you created a wrongly configured bucket: fix versioning/encryption/public access with the `put-*` commands above. If wrong name/region: empty and delete bucket, recreate (only safe **before** state objects exist).

```bash
# ONLY if bucket is empty / unused — destructive
# aws s3 rb "s3://${TF_STATE_BUCKET}" --force
```

### Best practices

Do not enable static website hosting. Do not grant public read for “convenience.”

### Security notes

Limit who can `s3:GetObject` / `s3:PutObject` on this bucket to platform operators. State may later include resource attributes.

---

## Step 3.3: Create DynamoDB lock table

### Goal

Create a DynamoDB table for Terraform state locking with partition key `LockID` (String).

### Why this step is required

Locks prevent two applies from corrupting the same state object.

### Commands

```bash
export AWS_REGION=eu-central-1
# export TF_LOCK_TABLE=...  # from Step 3.1

aws dynamodb create-table \
  --table-name "${TF_LOCK_TABLE}" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-central-1

aws dynamodb wait table-exists --table-name "${TF_LOCK_TABLE}" --region eu-central-1
```

**Cost impact:** On-demand DynamoDB — pennies at pilot scale.

### GUI instructions (if applicable)

| Element | Content |
|---------|---------|
| Platform | AWS Console |
| Navigation | **DynamoDB** → **Tables** → **Create table** |
| Permissions | `dynamodb:CreateTable`, `dynamodb:DescribeTable` |
| Verification | Table **Active**; partition key `LockID` (String) |

| Field | Value | Why |
|-------|-------|-----|
| Table name | Same as `TF_LOCK_TABLE` | Must match backend |
| Partition key | `LockID` · type **String** | Terraform backend contract |
| Sort key | None | Not used by Terraform |
| Table settings | On-demand (pay-per-request) | Simple for pilot |
| Region | `eu-central-1` | Same as bucket |

### Expected output

Table status `ACTIVE`.

### Validation

```bash
aws dynamodb describe-table --table-name "${TF_LOCK_TABLE}" --region eu-central-1 \
  --query 'Table.[TableName,TableStatus,KeySchema]' --output table
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `ResourceInUseException` | Table already exists | Describe it; confirm `LockID` key; reuse |
| Wrong key name | Typo `lockId` | Delete unused table (if empty) and recreate with `LockID` |

### Recovery

```bash
# ONLY if table unused — destructive
# aws dynamodb delete-table --table-name "${TF_LOCK_TABLE}" --region eu-central-1
```

### Best practices

One lock table per state backend for this pilot; do not share with unrelated projects.

### Security notes

Restrict `dynamodb:PutItem`/`DeleteItem`/`GetItem` on this table to operators running Terraform.

---

## Step 3.4: Wire backend config (`backend.tf` + local `backend.hcl`)

### Goal

Confirm repo backend files exist; create **local** `terraform/backend.hcl` from the example (never commit it).

### Why this step is required

Partial backend configuration keeps bucket/table names out of Git while `backend.tf` declares the S3 backend type.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"

test -f terraform/backend.hcl.example
test -f terraform/envs/prod/backend.tf
test -f terraform/envs/prod/versions.tf

cp terraform/backend.hcl.example terraform/backend.hcl

# Replace placeholders (macOS/BSD sed; Linux may omit '')
sed -i '' "s|<TF_STATE_BUCKET>|${TF_STATE_BUCKET}|g" terraform/backend.hcl
sed -i '' "s|<TF_LOCK_TABLE>|${TF_LOCK_TABLE}|g" terraform/backend.hcl

# Linux alternative if sed -i '' fails:
# sed -i "s|<TF_STATE_BUCKET>|${TF_STATE_BUCKET}|g" terraform/backend.hcl
# sed -i "s|<TF_LOCK_TABLE>|${TF_LOCK_TABLE}|g" terraform/backend.hcl

grep -E 'bucket|dynamodb_table|region|key' terraform/backend.hcl
grep -q 'backend.hcl' .gitignore && echo "gitignore: OK"
```

Confirm `terraform/backend.hcl` is **untracked**:

```bash
git check-ignore -v terraform/backend.hcl || git status --short terraform/backend.hcl
```

### GUI instructions (if applicable)

N/A — local file edit. Open `terraform/backend.hcl` in your editor and set:

| Field | Value | Why |
|-------|-------|-----|
| `bucket` | Your `TF_STATE_BUCKET` | State location |
| `key` | `envs/prod/terraform.tfstate` | Path within bucket (keep as example) |
| `region` | `eu-central-1` | Locked |
| `dynamodb_table` | Your `TF_LOCK_TABLE` | Locking |
| `encrypt` | `true` | Encrypt state object |

### Expected output

`backend.hcl` shows real bucket/table names (no `<…>` placeholders). `gitignore: OK`. File ignored by Git.

### Validation

```bash
grep -v '^#' terraform/backend.hcl | grep -v '^$'
! grep -q '<TF_' terraform/backend.hcl && echo "placeholders resolved: OK"
test -f terraform/envs/prod/backend.tf
test -f terraform/envs/prod/versions.tf
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `backend.hcl` shows in `git status` | Not ignored | Confirm `.gitignore` has `backend.hcl`; move file under `terraform/backend.hcl` |
| Placeholders remain | Env vars empty | Re-export Step 3.1 vars; re-copy example |

### Recovery

Delete local `terraform/backend.hcl` and recreate from example. Do not force-add it to Git.

### Best practices

Share bucket/table names via a secure channel with teammates; each clones example → local hcl.

### Security notes

Never commit `backend.hcl` or paste it into public MRs. Account-specific names are sensitive inventory.

---

## Step 3.5: `terraform init` against the remote backend

### Goal

Initialize `terraform/envs/prod` so state will be stored in S3 with DynamoDB locks.

### Why this step is required

Proves IAM + bucket + table + backend config before Topic 04 modules exist.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)/terraform/envs/prod"

terraform version
terraform init -backend-config=../../backend.hcl
```

Expected duration: usually under 1 minute (provider download).

### GUI instructions (if applicable)

N/A.

### Expected output

Similar to:

```text
Initializing the backend...
Successfully configured the backend "s3"!
...
Terraform has been successfully initialized!
```

### Validation

```bash
cd "$(git rev-parse --show-toplevel)/terraform/envs/prod"
test -d .terraform
terraform init -backend-config=../../backend.hcl -reconfigure
aws s3api list-objects-v2 --bucket "${TF_STATE_BUCKET}" --prefix envs/prod/ --output table || true
```

After first successful init, Terraform may create the state object on first write; empty listing before any apply can still be OK. Critical: init succeeds without backend errors.

Optional lock smoke (safe):

```bash
terraform providers
```

### Common problems

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `AccessDenied` on S3 | IAM / wrong bucket | Fix IAM; confirm bucket name/region |
| `UnauthorizedOperation` DynamoDB | Missing dynamodb perms | Grant table access |
| `NoSuchBucket` | Typo / wrong region | Fix `backend.hcl`; confirm Step 3.2 |
| Provider version error | Terraform < 1.9 | Upgrade per Topic 01 |

### Recovery

Fix IAM or `backend.hcl`; re-run `terraform init -backend-config=../../backend.hcl -reconfigure`. Do not delete the bucket if unsure — ask partner first.

### Best practices

Always `cd terraform/envs/prod` before init/plan/apply for this pilot root module.

### Security notes

`.terraform/` is gitignored — never commit provider plugins or local state copies.

---

## Step 3.6: Topic validation (gate to Topic 04)

### Goal

Prove remote state bootstrap is complete and repo files match inventory.

### Why this step is required

Topic 04 will `plan`/`apply` real spend; backend mistakes are painful mid-apply.

### Commands

```bash
cd "$(git rev-parse --show-toplevel)"

test -f terraform/backend.hcl.example
test -f terraform/envs/prod/backend.tf
test -f terraform/envs/prod/versions.tf
test -f terraform/backend.hcl
git check-ignore -q terraform/backend.hcl && echo "backend.hcl ignored: OK"

aws s3api head-bucket --bucket "${TF_STATE_BUCKET}"
aws dynamodb describe-table --table-name "${TF_LOCK_TABLE}" --query 'Table.TableStatus' --output text

cd terraform/envs/prod
terraform init -backend-config=../../backend.hcl -reconfigure
```

### GUI instructions (if applicable)

Console spot-check: S3 bucket + DynamoDB table visible in `eu-central-1`.

### Expected output

All tests pass; DynamoDB `ACTIVE`; Terraform init succeeds.

### Validation

Checklist:

- [ ] Bucket names chosen and recorded (3.1)
- [ ] S3: versioning + encryption + public access block (3.2)
- [ ] DynamoDB lock table `LockID` ACTIVE (3.3)
- [ ] `terraform/backend.hcl` present, placeholders gone, **gitignored** (3.4)
- [ ] Repo files `backend.hcl.example`, `backend.tf`, `versions.tf` present
- [ ] `terraform init` succeeds (3.5)
- [ ] No VPC/EKS created yet

### Common problems

Any failed checkbox — return to matching step; do not start Topic 04.

### Recovery

Fix the failing step; re-run Step 3.6 only.

### Best practices

Paste redacted validation output (bucket name OK; omit account if required) to your session partner.

### Security notes

Confirm no `*.tfstate` was committed: `git status` should not list state files.

---

## Topic validation (end-to-end)

Topic 03 is complete when Step 3.6 checklist passes.

**Cost check:** Only S3 + DynamoDB exist for this topic — still tear down in Topic 14 (after emptying state / destroying stack).

---

## Topic troubleshooting

| Area | Symptom | Action |
|------|---------|--------|
| Backend | Want to change bucket after state exists | Prefer migrate with `terraform init -migrate-state`; avoid delete |
| Region | Resources in `us-east-1` by mistake | Recreate in `eu-central-1` before Topic 04 |
| Team | Second engineer cannot init | Share bucket/table names + IAM; each creates local `backend.hcl` |
| Chicken/egg | “Should Terraform manage the bucket?” | Out of scope for v1 — CLI bootstrap is intentional |

---

## Next step

**[04 — Network, EKS, ECR, IAM](04-network-eks-ecr-iam.md)** (Phase B authoring next).

Do not run foundation `terraform apply` until Topic 04 guide and modules are approved and you execute that topic’s steps.
