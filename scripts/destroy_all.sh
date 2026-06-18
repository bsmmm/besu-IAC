#!/usr/bin/env bash

# Script de destruction et nettoyage complet en français.
# Emplacement : scripts/destroy_all.sh

set -euo pipefail

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

# Demande de confirmation à l'utilisateur
read -p "Êtes-vous sûr de vouloir détruire TOUTE l'infrastructure du cluster Besu ? [o/N] : " choice
case "$choice" in
    [oO]|[yY]|[oO][uU][iI])
        ;;
    *)
        log_info "Destruction annulée par l'utilisateur."
        exit 0
        ;;
esac

# 1. Destruction de l'infrastructure via Terraform
log_info "Étape 1/2 : Destruction des machines virtuelles avec Terraform..."
cd "$REPO_ROOT/besu-lab/infrastructure"

if [ -d ".terraform" ]; then
    terraform destroy -auto-approve
    log_success "Machines virtuelles détruites."
else
    log_warn "Terraform n'est pas initialisé ou aucune infrastructure n'existe dans besu-lab/infrastructure."
fi

# 2. Nettoyage des fichiers générés localement
log_info "Étape 2/2 : Nettoyage des fichiers temporaires et des clés locales..."

# Fichiers générés par Ansible / Python
CLEAN_PATHS=(
    "/tmp/besu-local-gen"
    "/tmp/besu-dist"
    "/tmp/besu-extracted"
    "/tmp/besu-24.12.0.tar.gz"
    "$REPO_ROOT/besu-lab/configuration/inventory/hosts.ini"
)

for path in "${CLEAN_PATHS[@]}"; do
    if [ -e "$path" ] || [ -d "$path" ]; then
        log_info "Suppression de : $path"
        sudo rm -rf "$path"
    fi
done

log_success "Nettoyage terminé."
log_success "Le cluster Hyperledger Besu a été entièrement détruit."
