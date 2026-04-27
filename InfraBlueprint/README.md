# InfraBlueprint — Vela Payments Infrastructure

Terraform configuration that provisions a reproducible two-tier AWS infrastructure for Vela Payments from scratch.

## Architecture

```
Internet
    │
    ▼
[Internet Gateway]
    │
    ▼
[Route Table — 0.0.0.0/0 → IGW]
    │
┌───┴──────────────────────────────┐
│           VPC 10.0.0.0/16        │
│                                  │
│  Public Subnet AZ-1  (10.0.0.0)  │
│  Public Subnet AZ-2  (10.0.1.0)  │
│       │                          │
│  [web-sg]                        │
│  [EC2 t2.micro + IAM Profile]    │
│       │                          │
│       │ port 5432 only           │
│       ▼                          │
│  [db-sg]                         │
│  Private Subnet AZ-1 (10.0.2.0)  │
│  Private Subnet AZ-2 (10.0.3.0)  │
│  [RDS PostgreSQL 15 db.t3.micro] │
│                                  │
│  [S3 Bucket — static assets]     │
│   ↑ EC2 IAM role only            │
└──────────────────────────────────┘
```

## File Structure

```
InfraBlueprint/
├── infra/
│   ├── main.tf         # Provider, backend config, AZ data source
│   ├── networking.tf   # VPC, subnets, IGW, route tables
│   ├── compute.tf      # EC2, web-sg, IAM role and instance profile
│   ├── database.tf     # RDS, db-sg, DB subnet group
│   ├── storage.tf      # S3 bucket, public access block, versioning
│   ├── variables.tf    # All input variables
│   └── outputs.tf      # EC2 IP, RDS endpoint, S3 bucket name
├── example.tfvars      # Placeholder variable values for reviewers
└── .gitignore
```

## Variable Reference

| Variable          | Type   | Description                                              |
|-------------------|--------|----------------------------------------------------------|
| `aws_region`      | string | AWS region to deploy into (e.g. `us-east-1`)            |
| `vpc_cidr`        | string | CIDR block for the VPC (default: `10.0.0.0/16`)         |
| `allowed_ssh_cidr`| string | Your IP in CIDR notation for SSH access (e.g. `1.2.3.4/32`) |
| `db_username`     | string | Master username for the RDS instance (sensitive)        |
| `db_password`     | string | Master password for the RDS instance (sensitive)        |
| `s3_bucket_name`  | string | Globally unique name for the S3 static assets bucket    |

## Setup Instructions

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- AWS credentials configured via `~/.aws/credentials` or environment variables:
  ```bash
  export AWS_ACCESS_KEY_ID="..."
  export AWS_SECRET_ACCESS_KEY="..."
  ```

### Backend bucket (one-time manual step)

Before running `terraform init`, create an S3 bucket to store remote state:

```bash
aws s3api create-bucket \
  --bucket vela-payments-tf-state \
  --region us-east-1
```

Then uncomment the `backend "s3"` block in `infra/main.tf`.

### Run

```bash
cd infra
terraform init
terraform plan -var-file="../example.tfvars"
terraform apply -var-file="../example.tfvars"
```

### Destroy

```bash
terraform destroy -var-file="../example.tfvars"
```

## Design Decisions

**RDS in private subnets**
The database has no public IP and `publicly_accessible = false`. The only inbound rule on `db-sg` allows port 5432 from `web-sg`. This means the database is only reachable from the EC2 instance, never from the internet — even if someone obtains the endpoint.

**IAM role instead of access keys**
The EC2 instance gets an IAM instance profile rather than hardcoded access keys. The policy grants only `s3:GetObject` and `s3:PutObject` on the specific assets bucket — nothing else. Rotating credentials is automatic; there are no keys to leak.

**Subnets computed from VPC CIDR**
Public and private subnets are derived using `cidrsubnet(var.vpc_cidr, 8, n)` so changing the VPC CIDR automatically adjusts all subnet ranges — no manual recalculation needed.

**Provider-level default tags**
All resources inherit `Project = "vela-payments"` via `provider.default_tags`, keeping individual resource blocks clean and ensuring no resource is ever untagged.
