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
  name      = local.cluster_network_name
  mode      = "none"
  bridge    = local.cluster_network_bridge
  domain    = "besu.lan"
  addresses = [local.cluster_network_cidr]
  autostart = true
}

# Base image stored in default pool
resource "libvirt_volume" "debian_base" {
  name   = "debian-13-base-image.qcow2"
  pool   = "default"
  source = local.debian_image_url
  format = "qcow2"
}

# Unique volumes for each VM using the base image backing store
resource "libvirt_volume" "node_volume" {
  count          = length(local.nodes)
  name           = "volume-${local.nodes[count.index].name}.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.debian_base.id
  size           = 10737418240 # 10GB
  format         = "qcow2"
}

# Cloud-Init disks containing user credentials and network setups
resource "libvirt_cloudinit_disk" "commoninit" {
  count     = length(local.nodes)
  name      = "commoninit-${local.nodes[count.index].name}.iso"
  pool      = "default"
  user_data = <<EOF
#cloud-config
users:
  - name: besu
    groups: sudo
    shell: /bin/bash
    sudo: 'ALL=(ALL) NOPASSWD:ALL'
    ssh_authorized_keys:
      - ${local.ssh_public_key}
runcmd:
  - [ ssh-keygen, -A ]
  - [ systemctl, restart, ssh ]
EOF

  meta_data = <<EOF
instance-id: ${local.nodes[count.index].name}
local-hostname: ${local.nodes[count.index].name}
EOF

  network_config = <<EOF
version: 2
ethernets:
  ens3:
    dhcp4: true
  ens4:
    dhcp4: false
    addresses:
      - ${local.nodes[count.index].ip}/24
EOF
}

# Domains configuration
resource "libvirt_domain" "nodes" {
  count  = length(local.nodes)
  name   = local.nodes[count.index].name
  memory = local.memory
  vcpu   = local.vcpu

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
