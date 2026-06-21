locals {
  validators = [for n in local.nodes : n if n.role == "validator"]
  rpc_nodes  = [for n in local.nodes : n if n.role == "rpc"]
}

resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/../ansible/inventory/hosts.ini"
  file_permission = "0644"
  content         = <<-EOF
[validators]
%{for node in local.validators~}
${node.name} ansible_host=${node.ip}
%{endfor~}

[rpc]
%{for node in local.rpc_nodes~}
${node.name} ansible_host=${node.ip}
%{endfor~}

[all:vars]
ansible_user=besu
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EOF
}

output "node_ips" {
  value = { for n in local.nodes : n.name => n.ip }
}

output "cluster_network_name" {
  value = libvirt_network.cluster_lan.name
}
