# AGENTS.md — infra-digitalocean

Instructions for AI agents using this OpenTofu repository.

## Overview

This repository provisions DigitalOcean infrastructure and publishes a
**DNS contract JSON** to S3-compatible object storage. The contract is
consumed by the `infra-cloudflare` repository to create Cloudflare DNS
records.

The contract replaces `terraform_remote_state`. The Cloudflare repo
never accesses the DigitalOcean state file — it only reads the JSON
contract from S3.

**Apply order:** Run this repo **before** `infra-cloudflare`.

---

## File map

| File | What it does |
|---|---|
| `versions.tf` | OpenTofu version and provider constraints |
| `backend.tf` | S3 state backend (configured at `tofu init` time) |
| `providers.tf` | DigitalOcean + AWS providers |
| `variables.tf` | All input variables with defaults and descriptions |
| `main.tf` | DigitalOcean resources (reserved IPs, droplets, etc.) |
| `contract.tf` | JSON contract builder + `aws_s3_object` upload |
| `outputs.tf` | Exposed outputs |
| `example.tfvars` | Sample variable values for a new project |

---

## Bootstrap a new project

### 1. Clone or copy the repository

```bash
cp -r infra-digitalocean my-project-infra-digitalocean
cd my-project-infra-digitalocean
```

### 2. Set environment variables

```bash
export DIGITALOCEAN_TOKEN="dop_v1_..."
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
```

When using **DigitalOcean Spaces** for the contract bucket, use your
Spaces access key for the AWS credentials.

### 3. Create a tfvars file

```bash
cp example.tfvars prod.tfvars
```

Edit `prod.tfvars` and set at minimum:

```hcl
environment          = "prod"
digitalocean_region  = "nyc3"
contract_bucket      = "your-contracts-bucket"
contract_key         = "contracts/prod/digitalocean-dns-targets.json"
```

For DigitalOcean Spaces, uncomment and set the `s3_*` overrides:

```hcl
s3_endpoint                   = "https://nyc3.digitaloceanspaces.com"
s3_skip_credentials_validation = true
s3_skip_metadata_api_check     = true
s3_skip_requesting_account_id  = true
s3_force_path_style            = true
```

### 4. Initialize the backend

The backend key includes the repo prefix. Match the environment name
in the key:

**AWS S3:**
```bash
tofu init \
  -backend-config="bucket=your-state-bucket" \
  -backend-config="key=digitalocean/prod.tfstate" \
  -backend-config="region=us-east-1"
```

**DigitalOcean Spaces:**
```bash
tofu init \
  -backend-config="bucket=your-state-bucket" \
  -backend-config="key=digitalocean/prod.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="endpoint=https://nyc3.digitaloceanspaces.com" \
  -backend-config="skip_credentials_validation=true" \
  -backend-config="skip_metadata_api_check=true" \
  -backend-config="skip_requesting_account_id=true" \
  -backend-config="force_path_style=true"
```

### 5. Plan and apply

```bash
tofu plan   -var-file=prod.tfvars
tofu apply  -var-file=prod.tfvars
```

After apply, the contract is written to:
```
s3://<contract_bucket>/<contract_key>
```

---

## Adding a new DNS target

To expose a new service (e.g., `worker`) so `infra-cloudflare` creates
a DNS record for it:

### Step 1: Add a DigitalOcean resource in `main.tf`

```hcl
resource "digitalocean_reserved_ip" "worker" {
  region = var.digitalocean_region
}
```

### Step 2: Add a contract entry in `contract.tf`

Edit the `local.dns_records` map. Keep the same shape:

```hcl
locals {
  dns_records = {
    frontend = {
      name    = "app"
      type    = "A"
      content = digitalocean_reserved_ip.frontend.ip_address
      proxied = true
      ttl     = 1
    }
    backend = {
      name    = "api"
      type    = "A"
      content = digitalocean_reserved_ip.backend.ip_address
      proxied = true
      ttl     = 1
    }
    # NEW ENTRY
    worker = {
      name    = "worker"
      type    = "A"
      content = digitalocean_reserved_ip.worker.ip_address
      proxied = false
      ttl     = 1
    }
  }
  # ... rest stays the same
}
```

### Step 3: Apply

```bash
tofu apply -var-file=prod.tfvars
```

The contract is updated automatically. The `infra-cloudflare` repo
picks up the new record on its next apply — no changes needed there.

---

## Adding a new environment (e.g. staging)

```bash
# 1. Create a new tfvars file
cp example.tfvars staging.tfvars

# 2. Edit it — use staging-specific values
#    environment    = "staging"
#    contract_key   = "contracts/staging/digitalocean-dns-targets.json"

# 3. Init a new backend state for staging
tofu init \
  -backend-config="bucket=your-state-bucket" \
  -backend-config="key=digitalocean/staging.tfstate" \
  -backend-config="region=us-east-1"

# 4. Plan and apply
tofu plan  -var-file=staging.tfvars
tofu apply -var-file=staging.tfvars
```

---

## Apply order

```
1. infra-digitalocean  ← this repo (run first)
2. infra-cloudflare    ← reads the contract from S3
```

In CI/CD, the Cloudflare pipeline must gate on a successful
DigitalOcean pipeline run.

---

## Contract format

The contract JSON published to S3 has this schema:

```json
{
  "schema_version": 1,
  "environment": "prod",
  "records": {
    "frontend": {
      "name": "app",
      "type": "A",
      "content": "203.0.113.10",
      "proxied": true,
      "ttl": 1
    },
    "backend": {
      "name": "api",
      "type": "A",
      "content": "203.0.113.11",
      "proxied": true,
      "ttl": 1
    }
  }
}
```

`proxied` is `true` for orange-cloud (Cloudflare proxy enabled),
`false` for grey-cloud (DNS only).

`ttl` must be `1` when `proxied = true` (Cloudflare requires
auto-TTL for proxied records).

---

## Common commands

```bash
tofu init -backend-config="..."    # first time or after backend changes
tofu plan  -var-file=prod.tfvars   # preview changes
tofu apply -var-file=prod.tfvars   # apply changes
tofu destroy -var-file=prod.tfvars # tear down all resources
tofu output                        # show outputs from current state
```
