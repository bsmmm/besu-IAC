#!/usr/bin/env bash

# Script d'installation du hook pre-commit.
# Emplacement : scripts/install-hooks.sh

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPTS_DIR/.." && pwd)"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0;0m'

HOOK_SRC="$REPO_ROOT/hooks/pre-commit"
HOOK_DST="$REPO_ROOT/.git/hooks/pre-commit"

if [ ! -f "$HOOK_SRC" ]; then
    echo "Erreur : le fichier source du hook '$HOOK_SRC' est introuvable."
    exit 1
fi

echo -e "${BLUE}[INFO]${NC} Installation du hook pre-commit..."

cp "$HOOK_SRC" "$HOOK_DST"
chmod +x "$HOOK_DST"

echo -e "${GREEN}[SUCCÈS]${NC} Hook pre-commit installé dans .git/hooks/pre-commit"
echo -e "${BLUE}[INFO]${NC} Les tests Molecule seront exécutés automatiquement avant chaque commit"
echo -e "${BLUE}[INFO]${NC} sur les rôles Ansible modifiés."
echo -e "${BLUE}[INFO]${NC} Pour ignorer ponctuellement : git commit --no-verify"
