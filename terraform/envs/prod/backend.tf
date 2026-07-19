# Remote state backend — S3 + DynamoDB locking
# Setup Topic 03. Partial backend config is supplied via -backend-config=../../backend.hcl
# (file is gitignored; start from terraform/backend.hcl.example).

terraform {
  backend "s3" {
    # bucket, key, region, dynamodb_table, encrypt — set via backend.hcl (Step 3.4)
  }
}
