#!/bin/bash
# ==========================================
# Snapshot ZFS de CachyOS (nom uniforme @auto)
# ==========================================

DATASET="zpcachyos/ROOT/cos"

# Création d'un nom de snapshot standardisé
SNAPNAME="auto-$(date +'%Y-%m-%d_%H-%M')"

echo "[INFO] Création du snapshot ZFS : ${DATASET}@${SNAPNAME}"

# Création récursive du snapshot avec le nouveau nom
time zfs snapshot -r "${DATASET}@${SNAPNAME}"

# Affichage des snapshots récents pour vérifier
zfs list -t snapshot -r "${DATASET}"
