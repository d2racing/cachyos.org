#!/bin/bash
set -euo pipefail

POOL="backuppool"
DATASET="backuppool/nas_backup/current"

# 1⃣ Démonte uniquement le dataset utilisé
sudo zfs unmount "$DATASET"

# 2⃣ Vérifie si le dataset est bien démonté
mountpoint -q "/mnt/backup/nas_backup/current" && {
    echo "ERROR: $DATASET n'a pas été démonté correctement"
    exit 1
}

# 3⃣ Export du pool
sudo zpool export "$POOL"

echo "✅ $POOL exporté avec succès"
