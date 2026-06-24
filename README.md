# Cluster de Lab Hyperledger Besu (QBFT, 4 Validateurs, 1 RPC)

Ce dépôt automatise la création d'un cluster local de blockchain Hyperledger Besu à 5 nœuds utilisant le mécanisme de consensus QBFT. Les nœuds sont provisionnés sur KVM/QEMU à l'aide de Terraform, puis configurés de manière sécurisée avec Ansible.

## Configuration des Paramètres

Toute la configuration du cluster (infrastructures VMs, versions de Besu, ports de monitoring, clé publique SSH) s'effectue dans un fichier de configuration unique :
1. **Fichier par défaut** : `config/settings.yml.default` contient les valeurs par défaut prêtes à l'emploi et est suivi par Git.
2. **Personnalisation** : Pour modifier les paramètres, créez un fichier `config/settings.yml` dans le dossier `config/`.
   * Vous n'avez pas besoin de recopier l'intégralité des paramètres dans `settings.yml`. Seuls les paramètres définis dans `settings.yml` surchargeront les valeurs par défaut. Tout paramètre non spécifié bénéficie d'un repli automatique (fallback) vers sa valeur par défaut.
   * Pour comprendre le rôle de chaque variable, consultez le guide en français **[Explication des Paramètres de Configuration](docs/06-settings-explanation.md)**.
   * Des messages d'information s'afficheront dans la console lors de la génération de configuration pour vous indiquer quels paramètres utilisent les valeurs par défaut.
   * Le fichier `config/settings.yml` est configuré dans `.gitignore` afin de ne jamais pousser vos clés SSH ou configurations spécifiques sur Git.

## Structure de la Documentation

Pour des instructions de configuration détaillées et des spécifications, veuillez vous référer à la documentation dans le dossier `docs/` :

* **[Guide de Démarrage](docs/01-getting-started.md)** : Étapes pour configurer `settings.yml` et exécuter le déploiement.
* **[Explication des Paramètres](docs/06-settings-explanation.md)** : Documentation en français de chaque paramètre de configuration.
* **[Architecture](docs/02-architecture.md)** : Aperçu de la topologie à 5 nœuds, de l'agencement des IP, de la configuration double carte réseau (dual-NIC) et des paramètres QBFT.
* **[Conseils de Débogage](docs/03-debugging-tips.md)** : Commandes rapides pour la console des machines virtuelles, le dépannage réseau et le requêtage des nœuds Besu.
* **[Prérequis Système](docs/04-requirements.md)** : Dépendances des paquets, configuration réseau et permissions requises sur l'hôte Debian 13.
* **[Opérations Réseau LAN](docs/05-operations-reseau-lan.md)** : Guide d'architecture et d'optimisation du réseau de l'hyperviseur KVM.

## Pour les Développeurs (Tests & Hooks)

Si vous clonez ce dépôt pour modifier le code (notamment les rôles Ansible), vous **devez** installer le hook Git de pré-commit local. Ce hook s'assure que les tests de conformité (Molecule) sont exécutés automatiquement avant chaque commit.

```bash
# À exécuter une seule fois juste après le git clone
./scripts/install-hooks.sh
```

## Lancement Rapide

Le déploiement complet automatisé peut être démarré avec le script global interactif à la racine :

```bash
# Lancer tout le déploiement (Terraform, Ansible, Tests, Observabilité)
./scripts/run_all.sh
```

> [!NOTE]
> Si aucun fichier `config/settings.yml` n'est détecté lors de l'exécution de `./scripts/run_all.sh`, le script vous demandera si vous souhaitez procéder avec les paramètres par défaut (en les copiant automatiquement dans `config/settings.yml`) ou annuler l'exécution.
