#!/bin/bash
set -euo pipefail

############################################
# CONFIGURATION
############################################
SRC_DATASET="zpcachyos/ROOT/cos"
DST_DATASET="backuppool/cachyos_backup"
SNAP_PREFIX="auto-"

############################################
# LOG
############################################
LOG() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

############################################
# PRÉCHECKS
############################################
zfs list "$SRC_DATASET" >/dev/null || { LOG "Erreur : dataset source introuvable"; exit 1; }
zfs list backuppool >/dev/null || { LOG "Erreur : pool backuppool introuvable"; exit 1; }

############################################
# DERNIER SNAPSHOT SOURCE
############################################
SRC_SNAPS=$(zfs list -t snapshot -o name -s creation | grep "^$SRC_DATASET@${SNAP_PREFIX}" || true)
if [[ -z "$SRC_SNAPS" ]]; then
    LOG "Erreur : aucun snapshot source trouvé"
    exit 1
fi

# On prend le plus récent
LATEST_SNAP=$(echo "$SRC_SNAPS" | tail -n1)
LOG "Snapshot source le plus récent : $LATEST_SNAP"

############################################
# SUPPRESSION DU DATASET DE DESTINATION
############################################
if zfs list "$DST_DATASET" >/dev/null 2>&1; then
    LOG "Destruction complète du dataset de destination : $DST_DATASET"
    zfs destroy -r "$DST_DATASET"
fi

LOG "Recréation du dataset de destination"
zfs create "$DST_DATASET"

############################################
# SEND FULL
############################################
LOG "Envoi FULL du snapshot $LATEST_SNAP vers $DST_DATASET"
zfs send -R "$LATEST_SNAP" | pv -pterb | zfs receive -F "$DST_DATASET"

LOG "✅ SEND FULL TERMINÉ"
