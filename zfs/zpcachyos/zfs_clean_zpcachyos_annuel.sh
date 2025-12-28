#!/bin/bash
set -euo pipefail

############################################
# CONFIGURATION
############################################
SRC_DATASET="zpcachyos/ROOT/cos"
DST_POOL="backuppool"
DST_DATASET="${DST_POOL}/cachyos_backup"
SNAP_PREFIX="auto-"

############################################
# LOG FUNCTION
############################################
LOG() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

############################################
# PRÉCHECKS
############################################
zfs list "$SRC_DATASET" >/dev/null || { LOG "Erreur : dataset source introuvable"; exit 1; }
zfs list "$DST_POOL" >/dev/null || { LOG "Erreur : pool $DST_POOL introuvable"; exit 1; }

# Crée le dataset destination si nécessaire
if ! zfs list "$DST_DATASET" >/dev/null 2>&1; then
    LOG "Création dataset de destination sécurisé : $DST_DATASET"
    zfs create -o canmount=off -o mountpoint=none "$DST_DATASET"
else
    LOG "Dataset de destination existe déjà : $DST_DATASET"
    zfs set mountpoint=none "$DST_DATASET"
fi

############################################
# DERNIER SNAPSHOT SOURCE
############################################
SRC_SNAPS=$(zfs list -t snapshot -o name -s creation | grep "^$SRC_DATASET@${SNAP_PREFIX}" || true)
if [[ -z "$SRC_SNAPS" ]]; then
    LOG "Erreur : aucun snapshot source trouvé"
    exit 1
fi

LATEST_SNAP=$(echo "$SRC_SNAPS" | tail -n1)
LOG "Snapshot source le plus récent : $LATEST_SNAP"

############################################
# SUPPRESSION DES SNAPSHOTS EXISTANTS SUR DESTINATION
############################################
LOG "Suppression de tous les snapshots existants sur $DST_DATASET et ses enfants"
mapfile -t dst_snaps < <(zfs list -H -t snapshot -r "$DST_DATASET" -o name)
for snap in "${dst_snaps[@]}"; do
    LOG "Suppression snapshot : $snap"
    sudo zfs destroy -f "$snap"
done

############################################
# ENVOI ZFS
############################################
LOG "Envoi FULL du snapshot $LATEST_SNAP vers $DST_DATASET"
zfs send -R "$LATEST_SNAP" | pv -pterb | zfs receive -F "$DST_DATASET"

############################################
# NETTOYAGE DES MOUNTPOINTS
############################################
LOG "Forçage mountpoint=none sur tous les enfants de $DST_DATASET"
mapfile -t datasets < <(zfs list -H -o name -r "$DST_DATASET")
for ds in "${datasets[@]}"; do
    LOG "Forçage mountpoint=none pour $ds"
    sudo zfs set mountpoint=none "$ds"
done

# Démonter les éventuels datasets encore montés
for ds in "${datasets[@]}"; do
    sudo zfs unmount "$ds" || true
done

LOG "✅ BACKUP ZFS ANNUEL TERMINÉ, dataset en mode backup-only"
