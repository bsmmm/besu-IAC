#!/usr/bin/env bash

# Script d'orchestration global interactif avec auto-résolution des erreurs.
# Emplacement : scripts/run_all.sh

set -euo pipefail

# Détermination du chemin absolu du dossier scripts et du dépôt
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPTS_DIR/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0;0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCÈS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[ATTENTION]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERREUR]${NC} $1"
}

ask_and_fix() {
    local error_msg="$1"
    local fix_flag="$2"
    
    log_error "$error_msg"
    read -p "Voulez-vous corriger automatiquement cette erreur ? [o/N] : " choice
    case "$choice" in
        [oO]|[yY]|[oO][uU][iI])
            "$SCRIPTS_DIR/fix_requirements.sh" "$fix_flag"
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# -----------------------------------------------------------------------------
# ÉTAPE 1 : Vérification des prérequis système
# -----------------------------------------------------------------------------
check_requirements() {
    log_info "Début de la vérification des prérequis système..."
    local failures=0

    # 1. Vérification de Terraform
    if ! command -v terraform &> /dev/null; then
        if ! ask_and_fix "Terraform n'est pas installé." "--terraform"; then
            failures=$((failures + 1))
        fi
    else
        log_success "Terraform est installé ($(terraform -v | head -n 1))."
    fi

    # 2. Vérification d'Ansible
    if ! command -v ansible &> /dev/null; then
        if ! ask_and_fix "Ansible n'est pas installé." "--ansible"; then
            failures=$((failures + 1))
        fi
    else
        log_success "Ansible est installé ($(ansible --version | head -n 1))."
    fi

    # 3. Vérification de virsh
    if ! command -v virsh &> /dev/null; then
        if ! ask_and_fix "L'utilitaire virsh n'est pas installé." "--virsh"; then
            failures=$((failures + 1))
        fi
    else
        log_success "L'utilitaire virsh est installé."
    fi

    # 4. Vérification de l'accès à libvirt daemon
    if command -v virsh &> /dev/null; then
        if ! virsh uri &> /dev/null; then
            if ! ask_and_fix "Impossible de se connecter à l'hyperviseur libvirt daemon." "--virsh"; then
                failures=$((failures + 1))
            fi
        else
            log_success "Connexion réussie à l'hyperviseur libvirt ($(virsh uri))."
        fi
    fi

    # 5. Vérification du groupe d'utilisateur
    local user_groups
    user_groups=$(groups)
    if [[ ! "$user_groups" =~ "libvirt" || ! "$user_groups" =~ "kvm" ]]; then
        if ! ask_and_fix "Votre utilisateur n'appartient pas au groupe 'libvirt' ou 'kvm'." "--groups"; then
            log_warn "Certaines commandes Terraform ou Ansible pourraient nécessiter des privilèges root (sudo)."
        fi
    else
        log_success "L'utilisateur appartient aux groupes requis (libvirt/kvm)."
    fi

    # 6. Vérification du réseau 'default' (NAT)
    if command -v virsh &> /dev/null; then
        if ! virsh -c qemu:///system net-info default &> /dev/null || [ "$(virsh -c qemu:///system net-info default | grep -E '^Active:' | awk '{print $2}')" != "yes" ]; then
            if ! ask_and_fix "Le réseau virtuel libvirt 'default' (NAT) n'est pas configuré ou est inactif." "--default-net"; then
                failures=$((failures + 1))
            fi
        else
            log_success "Le réseau virtuel libvirt 'default' (NAT) est actif."
        fi
    fi

    return $failures
}

# Lancer la vérification
check_requirements || {
    log_error "La vérification a échoué. Veuillez corriger les erreurs avant de poursuivre."
    exit 1
}

log_success "Tous les prérequis système critiques sont validés !"

# -----------------------------------------------------------------------------
# ÉTAPE 2 : Provisionnement avec Terraform
# -----------------------------------------------------------------------------
log_info "Étape 1/3 : Lancement du provisionnement de l'infrastructure avec Terraform..."
"$SCRIPTS_DIR/run_terraform.sh"

log_success "Provisionnement de l'infrastructure terminé avec succès."

# -----------------------------------------------------------------------------
# ÉTAPE 3 : Configuration du cluster avec Ansible
# -----------------------------------------------------------------------------
log_info "Nettoyage des anciennes clés SSH connues pour le cluster..."
for ip in 10.10.10.11 10.10.10.12 10.10.10.13 10.10.10.14 10.10.10.15 10.10.20.11 10.10.20.12 10.10.20.13 10.10.20.14 10.10.20.15; do
    ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$ip" &>/dev/null || true
done

log_info "Étape 2/3 : Lancement de la configuration logicielle avec Ansible..."
cd "$REPO_ROOT/besu-lab/configuration"
export ANSIBLE_LOCAL_TEMP="${ANSIBLE_LOCAL_TEMP:-/tmp/ansible-local}"
export ANSIBLE_REMOTE_TEMP="${ANSIBLE_REMOTE_TEMP:-/tmp/ansible-remote}"
export ANSIBLE_SSH_CONTROL_PATH_DIR="${ANSIBLE_SSH_CONTROL_PATH_DIR:-/tmp/ansible-cp}"
export ANSIBLE_SSH_ARGS="${ANSIBLE_SSH_ARGS:--F /dev/null -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null}"
mkdir -p "$ANSIBLE_LOCAL_TEMP" "$ANSIBLE_REMOTE_TEMP" "$ANSIBLE_SSH_CONTROL_PATH_DIR"
ansible-playbook -i inventory/hosts.ini playbook.yml

log_success "Configuration logicielle et démarrage du cluster Besu terminés."

# -----------------------------------------------------------------------------
# ÉTAPE 4 : Vérification de l'état de santé du cluster
# -----------------------------------------------------------------------------
log_info "Étape 3/4 : Lancement des tests automatisés de santé du cluster..."
"$SCRIPTS_DIR/validate_cluster.sh"

# -----------------------------------------------------------------------------
# ÉTAPE 5 : Démarrage et validation de la pile d'observabilité
# -----------------------------------------------------------------------------
log_info "Étape 4/4 : Démarrage de la pile d'observabilité..."
"$SCRIPTS_DIR/start_monitoring.sh"

log_info "Validation de la pile d'observabilité..."
sleep 5
"$SCRIPTS_DIR/validate_observability.sh"

log_success "Toutes les étapes du déploiement (Cluster & Monitoring) ont été exécutées avec succès !"
echo -e "\nServices Disponibles :"
echo -e "  - Grafana Dashboards : http://localhost:3000"
echo -e "  - Blockscout Explorer : http://localhost:4000"
echo -e "  - Prometheus Target UI : http://localhost:9090"

