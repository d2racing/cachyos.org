#!/bin/bash
# ==============================================
# Envoi du dernier snapshot de CachyOS vers disque externe
# ==============================================

# Dataset source sur ton système CachyOS
SRC="zpcachyos/ROOT/cos"

# Dataset destination sur le disque externe
DEST_PARENT="backuppool/cachyos_backup"
DEST_CURRENT="backuppool/cachyos_backup/current"

# Récupère le dernier snapshot créé
LAST_SNAP=$(zfs list -t snapshot -o name -s creation | grep "^${SRC}@" | tail -n1)

if [ -z "$LAST_SNAP" ]; then
    echo "Aucun snapshot trouvé pour ${SRC}. Abandon."
    exit 1
fi

echo "Envoi du snapshot ${LAST_SNAP} vers ${DEST_CURRENT} ..."

# Envoi récursif (-R) vers le dataset 'current'
sudo zfs send -R "$LAST_SNAP" | sudo zfs receive -u "$DEST_CURRENT"

if [ $? -eq 0 ]; then
    echo "Snapshot ${LAST_SNAP} envoyé avec succès vers ${DEST_CURRENT}."
else
    echo "Erreur lors de l'envoi du snapshot."
    exit 1
fi
