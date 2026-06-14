output "frontend_ip" {
  description = "Reserved IP for the frontend service"
  value       = digitalocean_reserved_ip.frontend.ip_address
}

output "backend_ip" {
  description = "Reserved IP for the backend service"
  value       = digitalocean_reserved_ip.backend.ip_address
}

output "contract_s3_url" {
  description = "S3 URL of the published DNS contract"
  value       = "s3://${var.contract_bucket}/${var.contract_key}"
}

output "contract_json" {
  description = "Full DNS contract (sensitive – contains infrastructure addresses)"
  value       = jsonencode(local.contract)
  sensitive   = true
}
