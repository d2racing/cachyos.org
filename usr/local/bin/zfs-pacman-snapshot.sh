#!/bin/bash
# Script de snapshot ZFS avant modification du système
DATASET="zpcachyos/ROOT/cos"
SNAP="pre-pacman-$(date +'%Y%m%d-%H%M')"

/usr/bin/zfs snapshot -r "${DATASET}@${SNAP}"
echo "Snapshot ${DATASET}@${SNAP} created successfully."

# sudo chmod +x /usr/local/bin/zfs-pacman-snapshot.sh
