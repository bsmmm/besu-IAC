# Conseils de Débogage

Voici les problèmes courants et les étapes de dépannage pour administrer le cluster Hyperledger Besu.

## 1. Vérification de l'état des VMs
Utilisez `virsh` sur l'hôte hyperviseur pour vérifier l'état des machines virtuelles :
```bash
sudo virsh list --all
```

## 2. Accès direct à la console
Si un nœud n'est pas accessible via SSH, connectez-vous directement via la console série :
```bash
sudo virsh console validator-1
```
*(Appuyez sur `Entrée` pour afficher l'invite de connexion. Pour quitter la console, appuyez sur `Ctrl + ]`)*

## 3. Examen des logs cloud-init
Si la configuration initiale ou le déploiement des clés SSH échouent, vérifiez les journaux sur l'invité :
```bash
tail -f /var/log/cloud-init-output.log
```

## 4. Requêtage de l'état d'un nœud Besu
Vérifiez le nombre de pairs et la progression de la synchronisation depuis l'hôte ou d'autres nœuds :
```bash
curl -k -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
  https://10.10.10.15:8545
```
*(Note : `-k` ou `--insecure` est requis car les certificats TLS générés sont auto-signés).*

## 5. Nettoyage des clés d'hôte SSH
Si les adresses IP des machines virtuelles changent ou sont réutilisées, supprimez les anciennes empreintes SSH :
```bash
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "10.10.10.11"
```
