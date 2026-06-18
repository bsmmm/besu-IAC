# Architecture

Ce document décrit la topologie du cluster Hyperledger Besu à 5 nœuds et la configuration de l'infrastructure réseau.

## 1. Topologie Réseau

Nous utilisons une configuration double carte réseau (dual-NIC) pour chaque machine virtuelle afin de combiner sécurité, connectivité et accessibilité locale :

* **NIC 1 (`ens3`) :** Connectée au commutateur NAT `default` (`virbr0`) avec adressage DHCP. Utilisée exclusivement pour l'accès à internet (installation de paquets, synchronisation horaire chrony).
* **NIC 2 (`ens4`) :** Connectée à un pont isolé (`virbr1` - `isolated-lan`) avec des adresses IP statiques (`10.10.20.11` à `10.10.20.15`). Utilisée pour la synchronisation sécurisée en peer-to-peer des nœuds Besu, les communications TLS et l'administration depuis l'hôte hyperviseur (`10.10.20.1`).

## 2. Nœuds du Cluster

Le réseau est composé de 5 nœuds exécutant Hyperledger Besu avec l'algorithme de consensus QBFT :

| Nom du Nœud | IP (isolated-lan) | Rôle |
|-------------|--------------------|------|
| `validator-1` | `10.10.20.11` | Validateur QBFT |
| `validator-2` | `10.10.20.12` | Validateur QBFT |
| `validator-3` | `10.10.20.13` | Validateur QBFT |
| `validator-4` | `10.10.20.14` | Validateur QBFT |
| `rpc-node` | `10.10.20.15` | Nœud de lecture/écriture RPC / WS non-validateur |

## 3. Mécanisme de Consensus

* **Moteur de consensus :** QBFT (variante d'Istanbul Byzantine Fault Tolerant).
* **Temps de bloc (Block Time) :** 2 secondes.
* **Longueur de l'époque (Epoch Length) :** 30 000 blocs.
* **TLS Natif :** Utilisé pour sécuriser les canaux de communication JSON-RPC et P2P.
