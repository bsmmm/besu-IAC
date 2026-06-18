terraform {
  required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7.6"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_network" "cluster_lan" {
  name      = var.cluster_network_name
  mode      = "none"
  bridge    = var.cluster_network_bridge
  domain    = "besu.lan"
  addresses = [var.cluster_network_cidr]
  autostart = true
}

# Base image stored in default pool
resource "libvirt_volume" "debian_base" {
  name   = "debian-13-base-image.qcow2"
  pool   = "default"
  source = var.debian_image_url
  format = "qcow2"
}

# Unique volumes for each VM using the base image backing store
resource "libvirt_volume" "node_volume" {
  count          = length(var.nodes)
  name           = "volume-${var.nodes[count.index].name}.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.debian_base.id
  size           = 10737418240 # 10GB
  format         = "qcow2"
}

# Cloud-Init disks containing user credentials and network setups
resource "libvirt_cloudinit_disk" "commoninit" {
  count     = length(var.nodes)
  name      = "commoninit-${var.nodes[count.index].name}.iso"
  pool      = "default"
  user_data = <<EOF
#cloud-config
users:
  - name: besu
    groups: sudo
    shell: /bin/bash
    sudo: 'ALL=(ALL) NOPASSWD:ALL'
    ssh_authorized_keys:
      - ${var.ssh_public_key}
runcmd:
  - [ ssh-keygen, -A ]
  - [ systemctl, restart, ssh ]
EOF

  meta_data = <<EOF
instance-id: ${var.nodes[count.index].name}
local-hostname: ${var.nodes[count.index].name}
EOF

  network_config = <<EOF
version: 2
ethernets:
  ens3:
    dhcp4: true
  ens4:
    dhcp4: false
    addresses:
      - ${var.nodes[count.index].ip}/24
EOF
}

# Domains configuration
resource "libvirt_domain" "nodes" {
  count  = length(var.nodes)
  name   = var.nodes[count.index].name
  memory = var.memory
  vcpu   = var.vcpu

  cloudinit = libvirt_cloudinit_disk.commoninit[count.index].id

  disk {
    volume_id = libvirt_volume.node_volume[count.index].id
  }

  # NIC 1 (enp1s0) -> default bridge (DHCP)
  network_interface {
    network_name = "default"
  }

  # NIC 2 (enp2s0) -> private Besu LAN (Static)
  network_interface {
    network_id = libvirt_network.cluster_lan.id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
  }
}
