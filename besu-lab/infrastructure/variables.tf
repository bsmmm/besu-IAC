variable "nodes" {
  type = list(object({
    name = string
    ip   = string
    role = string
  }))
  default = [
    { name = "validator-1", ip = "10.10.20.11", role = "validator" },
    { name = "validator-2", ip = "10.10.20.12", role = "validator" },
    { name = "validator-3", ip = "10.10.20.13", role = "validator" },
    { name = "validator-4", ip = "10.10.20.14", role = "validator" },
    { name = "rpc-node", ip = "10.10.20.15", role = "rpc" }
  ]

  validation {
    condition     = length([for n in var.nodes : n.role if contains(["validator", "rpc"], n.role)]) == length(var.nodes)
    error_message = "Each node role must be either validator or rpc."
  }
}

variable "ssh_public_key" {
  type    = string
  default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOk7dKR1V+PGlKuk8L1o4D6ZWRtdRasRaRZ5GKE+iIl8 mohamed-mahdi.ben-slima@univ-lehavre.fr"
}

variable "debian_image_url" {
  type    = string
  default = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-generic-amd64.qcow2"
}

variable "vcpu" {
  type    = number
  default = 2
}

variable "memory" {
  type    = number
  default = 2048 # 2GB
}

variable "cluster_network_name" {
  type    = string
  default = "besu-isolated-lan"
}

variable "cluster_network_cidr" {
  type    = string
  default = "10.10.20.0/24"
}

variable "cluster_network_bridge" {
  type    = string
  default = "virbr-besu"
}
