# Guide de Démarrage

Ce guide explique comment initialiser, configurer et lancer le cluster de lab Hyperledger Besu.

---

## Étape 1 : Configuration des Paramètres du Cluster

Toute la personnalisation du réseau s'effectue dans le répertoire `config/` :
1. Créez votre fichier de configuration local à partir du modèle fourni :
   ```bash
   cp config/settings.yml.default config/settings.yml
   ```
2. Modifiez le fichier `config/settings.yml` avec vos valeurs (clé SSH, ressources matérielles, version de Besu, etc.). 
   * *Note :* Tout paramètre omis dans votre fichier `settings.yml` bénéficiera d'un repli automatique sur sa valeur par défaut déclarée dans `settings.yml.default`.
   * Pour une explication complète de chaque paramètre en français, consultez le document **[Explication des Paramètres de Configuration](06-settings-explanation.md)**.

---

## Étape 2 : Prérequis Système

Assurez-vous que l'hôte de déploiement dispose de toutes les dépendances requises détaillées dans les **[Prérequis Système](04-requirements.md)** (telles que libvirt, QEMU, Terraform, Ansible, et l'accès au groupe d'utilisateurs requis).

---

## Étape 3 : Exécution du Déploiement Complet

Le déploiement complet est entièrement orchestré de manière interactive par le script global :
```bash
# Lancer le déploiement global interactif (Terraform, Ansible, Tests, Observabilité)
./scripts/run_all.sh
```

Si le script détecte que `config/settings.yml` est manquant, il vous demandera si vous souhaitez copier automatiquement les paramètres par défaut pour continuer ou interrompre le processus.

---

## Étape 4 : Déploiement Manuel Étape par Étape (Optionnel)

Si vous préférez exécuter les composants individuellement :

### 1. Provisionnement de l'infrastructure (Terraform)
Exécutez le script d'automatisation Terraform :
```bash
./scripts/run_terraform.sh
```
Ce script initialise les fournisseurs et provisionne les machines virtuelles configurées sur KVM/QEMU, puis génère le fichier d'inventaire dynamique Ansible dans `ansible/inventory/hosts.ini`.

### 2. Configuration logicielle (Ansible)
Accédez au dossier Ansible et exécutez le playbook :
```bash
cd ansible
ansible-playbook -i inventory/hosts.ini playbook.yml
```
Ce playbook installe Besu, génère les clés cryptographiques du consensus QBFT, distribue les certificats TLS et démarre le cluster.

### 3. Validation de l'état de santé du cluster
Exécutez le playbook de vérification :
```bash
ansible-playbook -i inventory/hosts.ini check.yml
```
Ce playbook s'assure du bon peering des nœuds, de la synchronisation de l'heure système, et de la saine progression de la hauteur de bloc de la blockchain.
