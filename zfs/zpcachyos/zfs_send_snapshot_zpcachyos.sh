#!/bin/bash
set -euo pipefail

############################################
# CONFIGURATION
############################################
POOL="zpbackup"
SRC_DATASET="zpcachyos/ROOT/cos"
DST_DATASET="$POOL/cachyos_backup"
SNAP_PREFIX="auto-"
RETENTION_KEEP=30     # Nombre de snapshots à conserver (SOURCE)

############################################
# LOG
############################################
LOG() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

############################################
# PRÉCHECKS
############################################
LOG "Préchecks ZFS"
zfs list "$SRC_DATASET" >/dev/null
zfs list "$DST_DATASET" >/dev/null

############################################
# SNAPSHOT SOURCE
############################################
SNAP_NEW="${SNAP_PREFIX}$(date '+%Y-%m-%d_%H-%M')"
LOG "Création snapshot source : $SRC_DATASET@$SNAP_NEW"
zfs snapshot -r "$SRC_DATASET@$SNAP_NEW"

############################################
# RECHERCHE DU DERNIER SNAPSHOT COMMUN
############################################
LOG "Recherche du dernier snapshot commun"

SRC_SNAPS=$(zfs list -t snapshot -o name -s creation \
    | grep "^$SRC_DATASET@${SNAP_PREFIX}" || true)

DST_SNAPS=$(zfs list -t snapshot -o name -s creation \
    | grep "^$DST_DATASET@${SNAP_PREFIX}" || true)

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
    LOG "Envoi incrémental vers $SNAP_NEW"

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
# ROTATION SNAPSHOTS SOURCE (PAR NOMBRE)
############################################
LOG "Rotation snapshots source (garder ${RETENTION_KEEP})"

mapfile -t SNAP_LIST < <(
    zfs list -t snapshot -o name -s creation \
    | grep "^$SRC_DATASET@${SNAP_PREFIX}"
)

SNAP_COUNT=${#SNAP_LIST[@]}

if (( SNAP_COUNT > RETENTION_KEEP )); then
    TO_DELETE=$(( SNAP_COUNT - RETENTION_KEEP ))
    LOG "Suppression de ${TO_DELETE} snapshot(s) ancien(s)"

    for (( i=0; i<TO_DELETE; i++ )); do
        LOG "Suppression snapshot source : ${SNAP_LIST[$i]}"
        zfs destroy "${SNAP_LIST[$i]}"
    done
else
    LOG "Aucune rotation nécessaire (${SNAP_COUNT}/${RETENTION_KEEP})"
fi

############################################
# FIN
############################################
LOG "✅ BACKUP ZFS INCRÉMENTAL TERMINÉ"
