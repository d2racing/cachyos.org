#!/bin/bash
# ===================================================
# Envoi du dernier snapshot pré-update de CachyOS
# vers le disque externe avec progression et rotation
# ===================================================

# Dataset source sur le système CachyOS
SRC="zpcachyos/ROOT/cos"

# Dataset destination sur le disque externe
DEST_PARENT="backuppool/cachyos_backup"
DEST_CURRENT="backuppool/cachyos_backup/current"

# Nombre maximum de snapshots à conserver sur le disque externe
MAX_SNAPS=10

# Vérifie si ZFS supporte -P
ZFS_SEND_OPTS="-vP"
zfs send -vP --help >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Option -P non supportée, utilisation de -v uniquement"
    ZFS_SEND_OPTS="-v"
fi

# Récupère le dernier snapshot pré-update
LAST_SNAP=$(zfs list -t snapshot -o name -s creation | grep "^${SRC}@pre-pacman" | tail -n1)

if [ -z "$LAST_SNAP" ]; then
    echo "Aucun snapshot pré-update trouvé pour ${SRC}. Abandon."
    exit 1
fi

echo "Envoi du snapshot ${LAST_SNAP} vers ${DEST_CURRENT} ..."

# Envoi récursif avec progression (-R et -vP) vers le dataset 'current'
sudo zfs send $ZFS_SEND_OPTS -R "$LAST_SNAP" | sudo zfs receive -u "$DEST_CURRENT"

if [ $? -eq 0 ]; then
    echo "Snapshot ${LAST_SNAP} envoyé avec succès vers ${DEST_CURRENT}."
else
    echo "Erreur lors de l'envoi du snapshot."
    exit 1
fi

# ===================================================
# Gestion de la rotation : garder les 10 derniers snapshots
# ===================================================

# Liste des snapshots présents sur le disque externe
SNAPS_ON_DEST=$(zfs list -t snapshot -o name -s creation | grep "^${DEST_CURRENT}@pre-pacman")

# Compter le nombre de snapshots
NUM_SNAPS=$(echo "$SNAPS_ON_DEST" | wc -l)

if [ "$NUM_SNAPS" -le "$MAX_SNAPS" ]; then
    echo "Rotation des snapshots : pas besoin de supprimer, total=$NUM_SNAPS"
else
    # Supprimer les snapshots les plus anciens
    NUM_TO_DELETE=$((NUM_SNAPS - MAX_SNAPS))
    echo "Rotation : suppression de $NUM_TO_DELETE anciens snapshots ..."
    echo "$SNAPS_ON_DEST" | head -n "$NUM_TO_DELETE" | while read SNAP_DELETE; do
        echo "Suppression de $SNAP_DELETE"
        sudo zfs destroy "$SNAP_DELETE"
    done
fi

echo "Rotation des snapshots terminée."
