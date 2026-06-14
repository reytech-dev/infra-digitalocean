terraform {
  required_version = "~> 1.9"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.49"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.50"
    }
  }
}
