#!/usr/bin/env bash

# Script de résolution automatique des prérequis en français avec support de SUDO_PASS.
# Emplacement : scripts/fix_requirements.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0;0m'

log_info() {
    echo -e "${YELLOW}[CORRECTION]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[CORRECTION SUCCÈS]${NC} $1"
}

log_error() {
    echo -e "${RED}[CORRECTION ERREUR]${NC} $1"
}

# Helper pour exécuter des commandes sudo (supporte SUDO_PASS en environnement non-interactif)
run_sudo() {
    if [ -n "${SUDO_PASS:-}" ]; then
        echo "$SUDO_PASS" | sudo -S "$@"
    else
        sudo "$@"
    fi
}

# Crée les fichiers XML temporaires dans un sous-dossier temporaire du workspace
TEMP_DIR="$(mktemp -d /tmp/besu-net-fix-XXXXXX)"
trap 'rm -rf "$TEMP_DIR"' EXIT

# XML du réseau default
DEFAULT_NET_XML="$TEMP_DIR/default.xml"
cat <<EOF > "$DEFAULT_NET_XML"
<network>
  <name>default</name>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
EOF

# XML du réseau isolated-lan
ISOLATED_NET_XML="$TEMP_DIR/isolated-lan.xml"
cat <<EOF > "$ISOLATED_NET_XML"
<network>
  <name>isolated-lan</name>
  <bridge name='virbr1' stp='on' delay='0'/>
  <domain name='isolated.lan'/>
  <ip address='10.10.10.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='10.10.10.10' end='10.10.10.250'/>
    </dhcp>
  </ip>
</network>
EOF

fix_terraform() {
    log_info "Installation de Terraform..."
    run_sudo apt update && run_sudo apt install -y gnupg software-properties-common curl
    curl -fsSL https://apt.releases.hashicorp.com/gpg | run_sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | run_sudo tee /etc/apt/sources.list.d/hashicorp.list
    run_sudo apt update && run_sudo apt install -y terraform
    log_success "Terraform a été installé avec succès."
}

fix_ansible() {
    log_info "Installation de Ansible..."
    run_sudo apt update && run_sudo apt install -y ansible
    log_success "Ansible a été installé avec succès."
}

fix_virsh() {
    log_info "Installation de libvirt-clients..."
    run_sudo apt update && run_sudo apt install -y libvirt-clients libvirt-daemon-system qemu-system-x86 qemu-utils virtinst bridge-utils
    log_success "Les outils Libvirt ont été installés avec succès."
}

fix_groups() {
    log_info "Ajout de l'utilisateur aux groupes 'libvirt' et 'kvm'..."
    run_sudo usermod -aG libvirt,kvm "$USER"
    log_success "Utilisateur ajouté aux groupes. ATTENTION : Vous devez vous reconnecter ou exécuter 'newgrp libvirt' pour appliquer les changements."
}

fix_default_network() {
    log_info "Configuration et démarrage du réseau 'default'..."
    if ! virsh net-info default &>/dev/null; then
        run_sudo virsh net-define "$DEFAULT_NET_XML"
    fi
    run_sudo virsh net-start default || true
    run_sudo virsh net-autostart default || true
    log_success "Le réseau 'default' a été configuré et démarré."
}

fix_isolated_network() {
    log_info "Configuration et démarrage du réseau 'isolated-lan'..."
    if ! virsh net-info isolated-lan &>/dev/null; then
        run_sudo virsh net-define "$ISOLATED_NET_XML"
    fi
    run_sudo virsh net-start isolated-lan || true
    run_sudo virsh net-autostart isolated-lan || true
    log_success "Le réseau 'isolated-lan' a été configuré et démarré."
}

# Analyse des arguments passés par run_all.sh
for arg in "$@"; do
    case "$arg" in
        --terraform)
            fix_terraform
            ;;
        --ansible)
            fix_ansible
            ;;
        --virsh)
            fix_virsh
            ;;
        --groups)
            fix_groups
            ;;
        --default-net)
            fix_default_network
            ;;
        --isolated-net)
            fix_isolated_network
            ;;
        *)
            log_error "Option inconnue : $arg"
            exit 1
            ;;
    esac
done
