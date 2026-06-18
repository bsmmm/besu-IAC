# Prérequis Système

Avant de déployer le cluster, assurez-vous que la machine hôte (l'hyperviseur) répond aux prérequis suivants :

## Système d'Exploitation (Hyperviseur)
- Debian 13 (Trixie) ou une distribution Linux compatible.

## Paquets Requis
Le système hôte doit disposer des utilitaires suivants installés et configurés :
1. **QEMU / KVM & Libvirt :**
   ```bash
   sudo apt update && sudo apt install -y qemu-system-x86 qemu-utils libvirt-daemon-system libvirt-clients virtinst bridge-utils
   ```
2. **Terraform :**
   - Terraform v1.5.0+ installé sur l'hôte.
3. **Ansible :**
   - Ansible v2.12+ installé sur l'hôte.

## Interfaces Réseau
- Un pont réseau actif `virbr0` configuré pour le réseau NAT par défaut (`192.168.122.0/24`).
- Un pont réseau actif `virbr1` pour le réseau privé isolé (`10.10.10.0/24`) configuré sous le nom `isolated-lan`.
*(Pour plus de détails sur la configuration à double interface et la séquence d'activation du pont isolé, consultez le [Guide des Opérations Réseau LAN](05-operations-reseau-lan.md)).*


## Groupes d'Utilisateur
L'utilisateur exécutant les commandes Terraform et Ansible doit faire partie des groupes `libvirt` et `kvm` pour gérer les VMs sans élévation de privilèges systématique :
```bash
sudo usermod -aG libvirt,kvm $USER
newgrp libvirt
```
