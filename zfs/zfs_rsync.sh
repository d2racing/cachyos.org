#!/bin/bash
# ==========================================
# Backup Synology -> ZFS
# rsync + dry-run + confirmation + snapshots
# ==========================================

set -o pipefail
set -euo pipefail

# --- CONFIGURATION ---
NAS_IP="XXX.XXX.XXX.XXX"
CREDENTIALS_FILE="/root/.nas-credentials"

SHARES=("CLONEZILLA" "DIVERS" "DONNEES" "homes" "LOGICIELS" "photo" "PHOTOSYNC" "STORAGE_ANALYZER")

NAS_MOUNT_BASE="/mnt/nas"
BACKUP_ROOT="/mnt/backup/nas_backup"
CURRENT="$BACKUP_ROOT/current"
ZFS_DATASET="backuppool/nas_backup/current"

DATE=$(date +%Y-%m-%d_%H-%M)
SNAPNAME="snap-$DATE"
LOG_FILE="$BACKUP_ROOT/backup_log.txt"

ANY_CHANGE=0

# --- LOG FUNCTION ---
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# --- CHECK ZFS POOL ---
if ! zfs list backuppool >/dev/null 2>&1; then
    log "❌ Pool ZFS backuppool indisponible"
    exit 1
fi

# --- MOUNT SPECIFIC DATASET ---
log "Montage du dataset ZFS..."
if ! zfs mount backuppool/nas_backup >/dev/null 2>&1; then
    log "❌ Échec montage ZFS du dataset backuppool/nas_backup"
    exit 1
fi

# --- HARD MOUNTPOINT CHECK ---
mountpoint -q "$BACKUP_ROOT" || {
    log "❌ $BACKUP_ROOT n'est pas monté. Arrêt du script."
    exit 1
}

mkdir -p "$NAS_MOUNT_BASE" "$CURRENT"

# --- CHECK FREE SPACE ---
AVAIL=$(df -h "$CURRENT" | awk 'NR==2 {print $4}')
log "Espace disponible sur disque de sauvegarde : $AVAIL"

# --- PREVIEW + CONFIRM FUNCTION ---
preview_and_confirm() {
    local SRC="$1"
    local DEST="$2"
    local SHARE="$3"

    log ">>> Dry-run rsync pour $SHARE"
    echo
    echo "========== CHANGEMENTS POUR $SHARE =========="
    echo

    PREVIEW=$(rsync -aH --delete --one-file-system \
        --exclude="#snapshot" --exclude="#recycle" --exclude="@eaDir" \
        --exclude="@recycle" --exclude="@tmp" --exclude=".SynoIndex*" \
        --exclude="@__thumb/" \
        --dry-run --itemize-changes \
        "$SRC/" "$DEST/")

    if [ -z "$PREVIEW" ]; then
        log "Aucun changement détecté pour $SHARE"
        return 1
    fi

    echo "$PREVIEW"
    echo
    echo "============================================"
    echo

    read -rp "Appliquer ces changements pour $SHARE ? [o/N] : " CONFIRM
    echo

    case "$CONFIRM" in
        o|O|y|Y)
            return 0
            ;;
        *)
            log "Synchronisation annulée pour $SHARE"
            return 1
            ;;
    esac
}

# --- BACKUP LOOP ---
for SHARE in "${SHARES[@]}"; do
    SRC="$NAS_MOUNT_BASE/$SHARE"
    DEST="$CURRENT/$SHARE"

    log "▶ Traitement de $SHARE"

    mkdir -p "$SRC" "$DEST"

    # Mount NAS share
    if ! mount -t cifs "//$NAS_IP/$SHARE" "$SRC" \
        -o credentials="$CREDENTIALS_FILE",rw,iocharset=utf8,vers=3.0; then
        log "❌ Échec montage SMB pour $SHARE — arrêt du script"
        exit 1
    fi

    # Dry-run + confirm
    if preview_and_confirm "$SRC" "$DEST" "$SHARE"; then
        log "▶ Lancement rsync réel pour $SHARE"

        rsync -aH --delete --one-file-system \
            --exclude="#snapshot" --exclude="#recycle" --exclude="@eaDir" \
            --exclude="@recycle" --exclude="@tmp" --exclude=".SynoIndex*" \
            --exclude="@__thumb/" \
            --info=progress2 \
            "$SRC/" "$DEST/" \
            && ANY_CHANGE=1 \
            || log "⚠ Erreur rsync sur $SHARE"
    else
        log "▶ Aucun changement appliqué pour $SHARE"
    fi

    sync
    umount "$SRC"
    log "✔ $SHARE terminé"
done

# --- CREATE SNAPSHOT ---
if [ "$ANY_CHANGE" -eq 1 ]; then
    log "Création du snapshot ZFS : $ZFS_DATASET@$SNAPNAME"
    zfs snapshot "$ZFS_DATASET@$SNAPNAME" \
        || { log "❌ Échec snapshot ZFS"; exit 1; }
else
    log "Aucun changement global — snapshot ZFS ignoré"
fi

# --- SNAPSHOT ROTATION (KEEP 7) ---
log "Rotation des snapshots ZFS (garder 7)"
SNAPS=$(zfs list -t snapshot -o name -s creation | grep "^$ZFS_DATASET@")

COUNT=0
for snap in $SNAPS; do
    COUNT=$((COUNT+1))
    if [ "$COUNT" -le 7 ]; then
        continue
    fi
    log "🗑 Suppression ancien snapshot : $snap"
    zfs destroy "$snap"
done

log "✅ Backup ZFS terminé le $DATE"
