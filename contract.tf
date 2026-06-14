# ── DNS contract builder and S3 upload ──
#
# Builds a minimal JSON contract containing only the values the
# Cloudflare repository needs. Does NOT expose full DigitalOcean state.

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
  }

  contract = {
    schema_version = 1
    environment    = var.environment
    records        = local.dns_records
  }
}

resource "aws_s3_object" "dns_contract" {
  bucket       = var.contract_bucket
  key          = var.contract_key
  content      = jsonencode(local.contract)
  content_type = "application/json"
  etag         = md5(jsonencode(local.contract))
}
