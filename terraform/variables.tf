# terraform/variables.tf
# Decodes the unified settings files (default and optional override settings.yml)
# from the project root, performs fallback logic, and exposes them as local variables.

locals {
  default_settings = yamldecode(file("${path.module}/../config/settings.yml.default"))
  user_settings    = fileexists("${path.module}/../config/settings.yml") ? yamldecode(file("${path.module}/../config/settings.yml")) : local.default_settings

  # Extract and merge infrastructure blocks
  infra_defaults = local.default_settings.infrastructure
  infra_user     = lookup(local.user_settings, "infrastructure", {})

  # Merge network details
  net_defaults = local.infra_defaults.network
  net_user     = lookup(local.infra_user, "network", {})
  network      = merge(local.net_defaults, local.net_user)

  # Merge infrastructure
  infrastructure = merge(
    local.infra_defaults,
    local.infra_user,
    {
      network = local.network
    }
  )

  nodes                  = local.infrastructure.nodes
  ssh_public_key         = local.infrastructure.ssh_public_key
  debian_image_url       = local.infrastructure.debian_image_url
  vcpu                   = local.infrastructure.vcpu
  memory                 = local.infrastructure.memory
  cluster_network_name   = local.infrastructure.network.name
  cluster_network_cidr   = local.infrastructure.network.cidr
  cluster_network_bridge = local.infrastructure.network.bridge
}


