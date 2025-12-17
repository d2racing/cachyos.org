!/bin/bash
set -euo pipefail

############################################
# CONFIGURATION
############################################
SRC_DATASET="zpcachyos/ROOT/cos"
DST_DATASET="backuppool/cachyos_backup"
RETENTION_DAYS=30

############################################
# OUTILS
############################################
LOG() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

############################################
# VÉRIFICATIONS
############################################
zfs list "$SRC_DATASET" >/dev/null
zfs list backuppool >/dev/null

############################################
# SNAPSHOT SOURCE
############################################
SNAP_NAME="auto-$(date '+%Y-%m-%d_%H-%M')"
LOG "Création du snapshot source : $SNAP_NAME"
zfs snapshot -r "$SRC_DATASET@$SNAP_NAME"

############################################
# FULL SEND
############################################
LOG "FULL SEND → suppression éventuelle du dataset destination"
zfs destroy -r "$DST_DATASET" 2>/dev/null || true

# Créer le dataset s'il n'existe pas
if ! zfs list "$DST_DATASET" >/dev/null 2>&1; then
    LOG "Dataset de destination inexistant, création..."
    zfs create -o mountpoint=none "$DST_DATASET"
fi

LOG "Envoi complet du snapshot $SNAP_NAME"
zfs send -R "$SRC_DATASET@$SNAP_NAME" | pv -pterb | zfs receive -F "$DST_DATASET"

LOG "✔ Transfert ZFS terminé"

############################################
# SÉCURISATION BACKUP
############################################
zfs set readonly=on "$DST_DATASET"
zfs set mountpoint=none "$DST_DATASET"

############################################
# ROTATION SNAPSHOTS (30 JOURS)
############################################
LOG "Rotation des snapshots (> ${RETENTION_DAYS} jours)"
NOW_TS=$(date +%s)
RETENTION_SEC=$((RETENTION_DAYS * 86400))

for DS in "$SRC_DATASET" "$DST_DATASET"; do
    zfs list -t snapshot -o name | grep "^$DS@auto-" | while read -r SNAP; do
        SNAP_NAME="${SNAP##*@auto-}"
        SNAP_TS=$(date -d "${SNAP_NAME/_/ }" +%s 2>/dev/null || true)
        if [[ -n "$SNAP_TS" ]]; then
            AGE=$((NOW_TS - SNAP_TS))
            if (( AGE > RETENTION_SEC )); then
                LOG "Suppression snapshot ancien : $SNAP"
                zfs destroy "$SNAP"
            fi
        fi
    done
done

############################################
# FIN
############################################
LOG "✅ BACKUP ZFS TERMINÉ AVEC SUCCÈS"
zfs list "$DST_DATASET"
