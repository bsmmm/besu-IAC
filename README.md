# Cluster de Lab Hyperledger Besu (QBFT, 4 Validateurs, 1 RPC)

Ce dépôt automatise la création d'un cluster local de blockchain Hyperledger Besu à 5 nœuds utilisant le mécanisme de consensus QBFT. Les nœuds sont provisionnés sur KVM/QEMU à l'aide de Terraform, puis configurés de manière sécurisée avec Ansible.

## Structure de la Documentation

Pour des instructions de configuration détaillées et des spécifications, veuillez vous référer à la documentation suivante dans le dossier `docs/` :

* **[Guide de Démarrage](docs/01-getting-started.md)** : Étapes pour exécuter le provisionnement Terraform et la configuration Ansible.
* **[Architecture](docs/02-architecture.md)** : Aperçu de la topologie à 5 nœuds, de l'agencement des IP, de la configuration double carte réseau (dual-NIC) et des paramètres QBFT.
* **[Conseils de Débogage](docs/03-debugging-tips.md)** : Commandes rapides pour la console des machines virtuelles, le dépannage réseau et le requêtage des nœuds Besu.
* **[Prérequis Système](docs/04-requirements.md)** : Dépendances des paquets, configuration réseau et permissions requises sur l'hôte Debian 13.
* **[Opérations Réseau LAN](docs/05-operations-reseau-lan.md)** : Guide d'architecture et d'optimisation du réseau de l'hyperviseur KVM.


## Lancement Rapide

```bash
# Étape 1 : Provisionner les VMs
cd besu-lab/infrastructure
chmod +x run.sh
./run.sh

# Étape 2 : Configurer et démarrer le cluster
cd ../configuration
ansible-playbook -i inventory/hosts.ini playbook.yml

# Étape 3 : Exécuter le playbook de vérification de l'état
ansible-playbook -i inventory/hosts.ini check.yml
```
