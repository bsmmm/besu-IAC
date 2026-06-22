#!/usr/bin/env bash

# Script d'exécution des tests Molecule pour les rôles Ansible.
# Emplacement : scripts/run_molecule.sh
#
# Usage :
#   ./scripts/run_molecule.sh                    # Tester tous les rôles
#   ./scripts/run_molecule.sh system_prep        # Tester un rôle spécifique
#   ./scripts/run_molecule.sh system_prep verify # Exécuter uniquement la vérification

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPTS_DIR/.." && pwd)"
ROLES_DIR="$REPO_ROOT/ansible/roles"

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

log_error() {
    echo -e "${RED}[ERREUR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[ATTENTION]${NC} $1"
}

# Vérification des prérequis
check_prerequisites() {
    local failures=0

    if ! command -v docker &> /dev/null; then
        log_error "Docker n'est pas installé. Molecule nécessite Docker pour les conteneurs de test."
        failures=$((failures + 1))
    fi

    if ! command -v molecule &> /dev/null; then
        log_error "Molecule n'est pas installé. Installez-le avec : pip install -r ansible/requirements.txt"
        failures=$((failures + 1))
    fi

    if [ $failures -gt 0 ]; then
        exit 1
    fi
}

# Exécuter Molecule pour un rôle donné
run_molecule_for_role() {
    local role_name="$1"
    local molecule_action="${2:-test}"
    local role_path="$ROLES_DIR/$role_name"

    if [ ! -d "$role_path/molecule" ]; then
        log_warn "Le rôle '$role_name' n'a pas de configuration Molecule. Ignoré."
        return 2
    fi

    log_info "Exécution de 'molecule $molecule_action' pour le rôle : $role_name"
    echo "────────────────────────────────────────────────────────────────"

    if (cd "$role_path" && molecule "$molecule_action"); then
        log_success "Rôle '$role_name' : RÉUSSI ✓"
        return 0
    else
        log_error "Rôle '$role_name' : ÉCHOUÉ ✗"
        return 1
    fi
}

# ─── Main ────────────────────────────────────────────────────────────────────

check_prerequisites

ROLE_FILTER="${1:-}"
MOLECULE_ACTION="${2:-test}"

passed=0
failed=0
skipped=0

if [ -n "$ROLE_FILTER" ]; then
    # Tester un seul rôle
    if [ ! -d "$ROLES_DIR/$ROLE_FILTER" ]; then
        log_error "Le rôle '$ROLE_FILTER' n'existe pas dans $ROLES_DIR"
        exit 1
    fi
    run_molecule_for_role "$ROLE_FILTER" "$MOLECULE_ACTION"
    exit $?
fi

# Tester tous les rôles qui ont une configuration Molecule
log_info "Exécution des tests Molecule pour tous les rôles configurés..."
echo ""

for role_dir in "$ROLES_DIR"/*/; do
    role_name=$(basename "$role_dir")

    if [ ! -d "$role_dir/molecule" ]; then
        skipped=$((skipped + 1))
        continue
    fi

    if run_molecule_for_role "$role_name" "$MOLECULE_ACTION"; then
        passed=$((passed + 1))
    else
        failed=$((failed + 1))
    fi
    echo ""
done

# ─── Résumé ──────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════════════════════"
echo -e "  Résumé des tests Molecule"
echo "────────────────────────────────────────────────────────────────"
echo -e "  ${GREEN}Réussis${NC}  : $passed"
echo -e "  ${RED}Échoués${NC}  : $failed"
echo -e "  ${YELLOW}Ignorés${NC}  : $skipped (pas de configuration Molecule)"
echo "════════════════════════════════════════════════════════════════"

if [ $failed -gt 0 ]; then
    log_error "$failed rôle(s) ont échoué les tests Molecule."
    exit 1
fi

log_success "Tous les tests Molecule ont réussi !"
