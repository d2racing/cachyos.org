#!/bin/bash
set -euo pipefail

POOL="backuppool"
DATASET="$POOL/nas_backup/current"
DST="/mnt/backup/nas_backup/current"

# 1 Import du pool si non présent
if ! zpool list -H -o name | grep -qx "$POOL"; then
    echo "📥 Import du pool $POOL..."
    sudo zpool import "$POOL"
fi

# 2 Création du point de montage si nécessaire
if [ ! -d "$DST" ]; then
    echo "📁 Création du dossier de montage $DST..."
    sudo mkdir -p "$DST"
fi

# 3 Montage du dataset
if ! zfs list -H -o mounted "$DATASET" | grep -qx "yes"; then
    echo "🔧 Montage du dataset $DATASET..."
    sudo zfs mount "$DATASET"
fi

# 4 Vérification
if mountpoint -q "$DST"; then
    echo "✅ Dataset monté sur $DST"
else
    echo "❌ ERREUR : $DST n'est pas monté"
    sudo zpool export "$POOL"
    exit 1
fi

# 5 Affichage pour contrôle
echo "🔹 État du pool :"
zpool status "$POOL"
echo
echo "🔹 Datasets :"
zfs list "$POOL"
echo
echo "🔹 Détails des mounts :"
zfs list -o name,canmount,mounted,mountpoint
echo
echo "🔹 Options importantes :"
zfs get compression,recordsize,atime,relatime,xattr,redundant_metadata "$POOL" "$DATASET"

