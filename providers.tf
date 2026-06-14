provider "digitalocean" {
  # Token read from DIGITALOCEAN_TOKEN environment variable
}

provider "aws" {
  region = var.contract_storage_region

  # For S3-compatible storage (e.g. DigitalOcean Spaces), set these in
  # variables.tf or via environment variables / CI secrets:
  #
  #   skip_credentials_validation = true
  #   skip_metadata_api_check     = true
  #   skip_requesting_account_id  = true
  #   force_path_style            = true

  skip_credentials_validation = var.s3_skip_credentials_validation
  skip_metadata_api_check     = var.s3_skip_metadata_api_check
  skip_requesting_account_id  = var.s3_skip_requesting_account_id
  force_path_style            = var.s3_force_path_style

  endpoints {
    s3 = var.s3_endpoint
  }
}
