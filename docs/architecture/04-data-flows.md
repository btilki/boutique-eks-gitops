# 04 — Data flows

## Application request flow

```mermaid
sequenceDiagram
  actor User
  participant R53 as Route53
  participant ALB as ALB + ACM
  participant FE as frontend
  participant Cat as productcatalog
  participant Cart as cartservice
  participant Redis as Redis
  participant Co as checkout
  participant Pay as payment
  participant Ship as shipping
  participant Cur as currency

  User->>R53: DNS boutique host
  User->>ALB: HTTPS
  ALB->>FE: HTTP to pods
  FE->>Cat: gRPC/HTTP catalog
  FE->>Cart: cart ops
  Cart->>Redis: session/cart
  FE->>Co: checkout
  Co->>Cur: convert
  Co->>Pay: charge
  Co->>Ship: quote/ship
  FE-->>User: HTML/JSON
```

**Alt text:** User resolves DNS, connects via ACM-backed ALB to frontend; frontend calls catalog, cart (Redis), and checkout; checkout calls currency, payment, and shipping.

## GitOps + CI flow

```mermaid
sequenceDiagram
  participant Dev as Engineer
  participant GL as GitLab CI
  participant ECR as ECR
  participant Git as Git repo
  participant Argo as Argo CD
  participant K8s as EKS

  Dev->>GL: push / MR merge to app path
  GL->>GL: test → build
  GL->>GL: Trivy CRITICAL gate
  GL->>GL: cosign sign
  GL->>ECR: OIDC push digest
  GL->>Git: open MR patch image.digest only
  Dev->>Git: merge digest MR
  Argo->>Git: poll/webhook
  Argo->>K8s: sync (auto dev/stage; manual prod)
  K8s->>ECR: pull by digest
```

**Alt text:** CI builds, scans, signs, pushes to ECR, and opens a digest-only MR. After merge, Argo syncs the cluster; pods pull immutable digests. CI never calls kubectl or argocd sync.

## Infrastructure flow

```mermaid
sequenceDiagram
  participant Op as Operator
  participant TF as Terraform
  participant S3 as State S3+DDB
  participant AWS as AWS APIs

  Op->>TF: plan/apply
  TF->>S3: lock + read/write state
  TF->>AWS: VPC EKS ECR IAM ACM...
  AWS-->>TF: resource IDs
  TF->>S3: persist state
```

**Alt text:** Terraform applies through AWS APIs with state locked in S3/DynamoDB.

## Secrets flow

```mermaid
sequenceDiagram
  participant Human as Operator
  participant SM as Secrets Manager/SSM
  participant ESO as External Secrets
  participant Pod as Workload / Alertmanager
  participant CI as GitLab CI

  Human->>SM: store SMTP / app secrets
  ESO->>SM: IRSA read
  ESO->>Pod: sync K8s Secret
  CI->>CI: OIDC token
  CI->>AWS: assume role ECR push
  Note over Human,CI: No long-lived keys in Git
```

**Alt text:** Humans place secrets in AWS; ESO syncs to pods via IRSA. CI uses OIDC. Nothing secret is committed to Git.

## Telemetry flow (v1 — no OTel)

```mermaid
flowchart LR
  Pods[Boutique + platform pods] -->|metrics scrape| Prom[Prometheus]
  Pods -->|log ship| Loki[Loki]
  Prom --> Graf[Grafana]
  Loki --> Graf
  Prom -->|rules| AM[Alertmanager]
  AM -->|SMTP| Mail[Email inbox]
```

**Alt text:** Prometheus scrapes metrics; Loki stores logs; Grafana visualizes both; Alertmanager emails critical alerts. No trace pipeline in v1.
