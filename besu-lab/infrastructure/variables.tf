variable "nodes" {
  type = list(object({
    name = string
    ip   = string
  }))
  default = [
    { name = "validator-1", ip = "10.10.10.11" },
    { name = "validator-2", ip = "10.10.10.12" },
    { name = "validator-3", ip = "10.10.10.13" },
    { name = "validator-4", ip = "10.10.10.14" },
    { name = "rpc-node",    ip = "10.10.10.15" }
  ]
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
