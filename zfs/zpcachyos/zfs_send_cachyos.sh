#!/bin/bash
set -euo pipefail

############################################
# CONFIGURATION
############################################
SRC_DATASET="zpcachyos/ROOT/cos"
DST_DATASET="backuppool/cachyos_backup"
SNAP_PREFIX="auto-"
RETENTION_DAYS=30

############################################
# LOG
############################################
LOG() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

############################################
# PRÉCHECKS
############################################
zfs list "$SRC_DATASET" >/dev/null
zfs list backuppool >/dev/null

############################################
# SNAPSHOT SOURCE
############################################
SNAP_NEW="${SNAP_PREFIX}$(date '+%Y-%m-%d_%H-%M')"
LOG "Création snapshot source : $SNAP_NEW"
zfs snapshot -r "$SRC_DATASET@$SNAP_NEW"

############################################
# DERNIER SNAPSHOT COMMUN
############################################
LOG "Recherche du dernier snapshot commun..."

SRC_SNAPS=$(zfs list -t snapshot -o name -s creation | grep "^$SRC_DATASET@${SNAP_PREFIX}" || true)
DST_SNAPS=$(zfs list -t snapshot -o name -s creation | grep "^$DST_DATASET@${SNAP_PREFIX}" || true)

COMMON_SNAP=""
for S in $SRC_SNAPS; do
    SNAP_NAME="${S##*@}"
    if echo "$DST_SNAPS" | grep -qx "$DST_DATASET@$SNAP_NAME"; then
        COMMON_SNAP="$SNAP_NAME"
    fi
done

############################################
# ENVOI ZFS
############################################
if [[ -n "$COMMON_SNAP" ]]; then
    LOG "Snapshot commun trouvé : $COMMON_SNAP"
    LOG "Envoi incrémental → $SNAP_NEW"
    zfs send -R -i "$SRC_DATASET@$COMMON_SNAP" "$SRC_DATASET@$SNAP_NEW" \
        | pv -pterb \
        | zfs receive "$DST_DATASET"
else
    LOG "Aucun snapshot commun → FULL SEND initial"
    zfs send -R "$SRC_DATASET@$SNAP_NEW" \
        | pv -pterb \
        | zfs receive "$DST_DATASET"
fi

LOG "✔ Transfert terminé"

############################################
# ROTATION SNAPSHOTS SOURCE UNIQUEMENT
############################################
LOG "Rotation snapshots source (> ${RETENTION_DAYS} jours)"

NOW_TS=$(date +%s)
RETENTION_SEC=$((RETENTION_DAYS * 86400))

zfs list -t snapshot -o name | grep "^$SRC_DATASET@${SNAP_PREFIX}" | while read -r SNAP; do
    SNAP_TS=$(date -d "${SNAP##*@${SNAP_PREFIX}//_/ }" +%s 2>/dev/null || true)
    if [[ -n "$SNAP_TS" ]]; then
        AGE=$((NOW_TS - SNAP_TS))
        if (( AGE > RETENTION_SEC )); then
            LOG "Suppression snapshot source : $SNAP"
            zfs destroy "$SNAP"
        fi
    fi
done

############################################
# FIN
############################################
LOG "✅ BACKUP ZFS INCRÉMENTAL TERMINÉ"
