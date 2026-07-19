# External Secrets Operator

**Setup:** Topic 07 · **Pin:** chart **0.14.4** (ESO 0.14.x)

## IRSA

```bash
terraform -chdir=terraform/envs/prod output -raw irsa_external_secrets_role_arn
# Must annotate SA external-secrets/external-secrets (values.yaml)
```

## Sync

- Operator: `platform-apps` ApplicationSet (Helm)
- ClusterSecretStore: `platform-manifests` → this directory’s `clustersecretstore.yaml`

Sample ExternalSecret: `examples/externalsecret-sample.yaml` (apply after creating the AWS secret).
