# infra-digitalocean

OpenTofu configuration for DigitalOcean infrastructure.

## Resources

| Resource | Purpose |
|---|---|
| `digitalocean_reserved_ip.frontend` | Stable public IP for the frontend service |
| `digitalocean_reserved_ip.backend` | Stable public IP for the backend service |
| `aws_s3_object.dns_contract` | Publishes a DNS contract JSON to S3-compatible storage |

## Required Secrets

Set these environment variables:

```bash
export DIGITALOCEAN_TOKEN="dop_v1_..."
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
```

When using DigitalOcean Spaces for the contract bucket, also set `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` to your Spaces access key pair.

## Backend Initialisation

```bash
# Standard AWS S3
tofu init \
  -backend-config="bucket=my-opentofu-state" \
  -backend-config="key=digitalocean/prod.tfstate" \
  -backend-config="region=us-east-1"

# DigitalOcean Spaces
tofu init \
  -backend-config="bucket=my-opentofu-state" \
  -backend-config="key=digitalocean/prod.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="endpoint=https://nyc3.digitaloceanspaces.com" \
  -backend-config="skip_credentials_validation=true" \
  -backend-config="skip_metadata_api_check=true" \
  -backend-config="skip_requesting_account_id=true" \
  -backend-config="force_path_style=true"
```

## Usage

```bash
# Copy and customise variables
cp example.tfvars prod.tfvars
# Edit prod.tfvars with your values

# Plan
tofu plan -var-file=prod.tfvars

# Apply
tofu apply -var-file=prod.tfvars
```

## Contract File

After `tofu apply`, a JSON contract is written to:

```
s3://<contract_bucket>/contracts/<environment>/digitalocean-dns-targets.json
```

Example content:

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

## Adding Another DNS Record

1. Add a new DigitalOcean resource (e.g. another reserved IP) in `main.tf`.
2. Add a new entry to `local.dns_records` in `contract.tf`.
3. Run `tofu apply`. The updated contract is automatically published.

## Apply Order

```
1. infra-digitalocean  (this repo – run first)
2. infra-cloudflare    (run second, reads the contract)
```

The Cloudflare repo depends on the JSON contract produced by this repo.
