# Guide de Démarrage

Ce guide explique comment initialiser et configurer le cluster de lab Hyperledger Besu.

## Étape 1 : Cloner et initialiser
Naviguez vers le dossier racine du projet.

## Étape 2 : Valider les prérequis
Assurez-vous de respecter tous les prérequis listés dans les [Prérequis Système](04-requirements.md).

## Étape 3 : Exécuter le provisionnement Terraform
Accédez au répertoire `besu-lab/infrastructure/` et lancez le script d'initialisation :
```bash
cd besu-lab/infrastructure
chmod +x run.sh
./run.sh
```
Ce script va :
1. Initialiser le fournisseur libvirt.
2. Télécharger l'image de base Debian 13.
3. Provisionner 5 VMs avec des configurations double carte réseau (dual-NIC).
4. Générer dynamiquement le fichier d'inventaire Ansible dans `../configuration/inventory/hosts.ini`.

## Étape 4 : Lancer la configuration Ansible
Accédez au répertoire `besu-lab/configuration/` et exécutez le playbook :
```bash
cd ../configuration
ansible-playbook -i inventory/hosts.ini playbook.yml
```
Ce playbook va :
1. Mettre à jour les paquets système, synchroniser l'horloge système et activer les règles UFW.
2. Générer les certificats TLS et les clés des nœuds Besu, puis les distribuer de manière sécurisée.
3. Télécharger le binaire Besu, configurer les scripts de service, initialiser le bloc genesis et démarrer le réseau.

## Étape 5 : Vérifier l'état du cluster
Pour exécuter les tests de validation automatisés sur tous les nœuds, lancez le playbook de vérification :
```bash
ansible-playbook -i inventory/hosts.ini check.yml
```
Ce script valide que :
- Le démon de synchronisation d'horloge Chrony fonctionne correctement.
- Le service `besu` est actif et configuré pour démarrer au boot sur tous les hôtes.
- Les ports de découverte des nœuds (30303) sont ouverts et à l'écoute.
- Le port HTTPS JSON-RPC (8545) est actif sur le nœud RPC.
- Le peering des nœuds est complet (4 pairs connectés).
- La hauteur de bloc du consensus progresse normalement et de manière saine.
