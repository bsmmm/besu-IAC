resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/../configuration/inventory/hosts.ini"
  file_permission = "0644"
  content         = <<EOF
[validators]
validator-1 ansible_host=10.10.10.11
validator-2 ansible_host=10.10.10.12
validator-3 ansible_host=10.10.10.13
validator-4 ansible_host=10.10.10.14

[rpc]
rpc-node ansible_host=10.10.10.15

[all:vars]
ansible_user=besu
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF
}

output "node_ips" {
  value = { for n in var.nodes : n.name => n.ip }
}
