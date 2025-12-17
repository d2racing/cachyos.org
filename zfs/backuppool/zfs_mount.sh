#!/bin/bash
set -euo pipefail

POOL="backuppool"
DST="/mnt/backup/nas_backup"

# 1️⃣ Import pool en lecture seule pour sécurité
if ! zpool list -H -o name | grep -qx "$POOL"; then
    sudo zpool import -N -o readonly=on "$POOL"
fi

# 2️⃣ Monte uniquement le dataset que tu veux utiliser
sudo zfs mount backuppool/nas_backup/current

# 3️⃣ Vérifie le mountpoint
mountpoint -q "$DST" || {
    echo "ERROR: $DST is not mounted"
    sudo zpool export "$POOL"
    exit 1
}

# 4️⃣ Affichage pour contrôle
zpool status "$POOL"
zfs list "$POOL"
zfs list -o name,canmount,mounted,mountpoint
zfs get compression,recordsize,atime,relatime,xattr,redundant_metadata backuppool backuppool/nas_backup/current
