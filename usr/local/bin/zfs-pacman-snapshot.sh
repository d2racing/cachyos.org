#!/bin/bash
# Script de snapshot ZFS avant modification du système (uniformisé @auto)
DATASET="zpcachyos/ROOT/cos"
SNAP="auto-$(date +'%Y%m%d-%H%M')"

# Création du snapshot récursif
/usr/bin/zfs snapshot -r "${DATASET}@${SNAP}"
echo "Snapshot ${DATASET}@${SNAP} created successfully."
