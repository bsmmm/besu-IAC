# Explication des Paramètres de Configuration

Ce document détaille chaque section et paramètre disponible dans le fichier de configuration unifiée `config/settings.yml`.

---

## 1. Section `infrastructure` (Provisionnement KVM/QEMU)

Cette section configure les caractéristiques matérielles et réseau des machines virtuelles (VMs) créées par Terraform.

* **`debian_image_url`** : L'URL de l'image cloud officielle Debian 13 (format `.qcow2`). Elle est téléchargée automatiquement lors du premier provisionnement.
* **`vcpu`** : Le nombre de processeurs virtuels alloués à chaque machine virtuelle (ex. : `2`).
* **`memory`** : La quantité de mémoire vive (RAM) en mégaoctets (Mo) allouée à chaque machine virtuelle (ex. : `2048` pour 2 Go).
* **`ssh_public_key`** : La clé publique SSH qui sera injectée dans le compte utilisateur par défaut (`debian`) de chaque VM pour permettre une authentification Ansible sans mot de passe.
* **`network`** (Configuration Réseau) :
  * **`name`** : Le nom du réseau virtuel isolé créé dans libvirt (ex. : `"besu-isolated-lan"`).
  * **`cidr`** : Le bloc d'adresses IP du réseau local (ex. : `"10.10.20.0/24"`).
  * **`bridge`** : Le nom de l'interface réseau bridge Linux créée sur l'hôte (ex. : `"virbr-besu"`).
* **`nodes`** (Liste des Nœuds) :
  * Une liste d'objets définissant les nœuds du cluster. Chaque nœud comprend :
    * **`name`** : Le nom de domaine local / nom d'hôte de la VM (ex. : `"validator-1"`).
    * **`ip`** : L'adresse IP statique attribuée à ce nœud dans le réseau isolé (ex. : `"10.10.20.11"`).
    * **`role`** : Le rôle du nœud. Peut être `"validator"` (nœud participant au consensus QBFT) ou `"rpc"` (nœud d'accès API public).

---

## 2. Section `besu` (Paramètres de la Blockchain)

Cette section configure le logiciel Hyperledger Besu et les caractéristiques du réseau privé Ethereum.

* **`version`** : La version de l'exécutable Hyperledger Besu à déployer sur tous les nœuds (ex. : `"24.12.0"`).
* **`tarball_checksum`** : L'empreinte de sécurité SHA-256 de l'archive officielle Besu téléchargée, garantissant l'intégrité du binaire.
* **`chain_id`** : L'identifiant unique du réseau EVM (ex. : `1337`).
* **`block_period_seconds`** : Le temps cible en secondes entre la production de deux blocs successifs dans le consensus QBFT (ex. : `2` secondes).
* **`request_timeout_seconds`** : Le temps d'attente maximum en secondes pour les messages de consensus QBFT (Round Change) avant de déclencher un timeout (ex. : `4` secondes).

---

## 3. Section `monitoring` (Observabilité & Services)

Cette section contrôle les ports réseau des outils de collecte de métriques et les paramètres de synchronisation temporelle.

* **`node_exporter_port`** : Le port réseau sur lequel s'exécute Prometheus Node Exporter pour collecter les métriques système (ex. : `9100`).
* **`process_exporter_port`** : Le port réseau pour Process Exporter afin de suivre la consommation de ressources spécifique du processus Besu (ex. : `9256`).
* **`besu_metrics_port`** : Le port d'écoute natif exposé par Hyperledger Besu pour distribuer ses métriques au format Prometheus (ex. : `9545`).
* **`chrony_primary_host`** : Le nom du nœud choisi pour servir de serveur NTP primaire interne (Chrony) pour garantir une synchronisation d'horloge parfaite entre tous les validateurs (ex. : `"validator-1"`).
* **`chrony_primary_ip`** : L'adresse IP locale de ce serveur NTP primaire (ex. : `"10.10.20.11"`).
