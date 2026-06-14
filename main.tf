# ── DigitalOcean Reserved IPs ──
#
# Reserved IPs are stable public IP addresses that persist across
# Droplet reassignments. They serve as reliable DNS targets.

resource "digitalocean_reserved_ip" "frontend" {
  region = var.digitalocean_region
}

resource "digitalocean_reserved_ip" "backend" {
  region = var.digitalocean_region
}
