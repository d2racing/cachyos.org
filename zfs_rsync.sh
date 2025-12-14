#!/bin/bash
# ==========================================
# Backup Synology -> ZFS (rsync + snapshots)
# ==========================================

set -o pipefail

# --- CONFIGURATION ---
NAS_IP="XXX.XXX.XXX.XXX"
CREDENTIALS_FILE="/root/.nas-credentials"
SHARES=("CLONEZILLA" "DIVERS" "DONNEES" "homes" "LOGICIELS" "photo" "PHOTOSYNC" "STORAGE_ANALYZER")

NAS_MOUNT_BASE="/mnt/nas"
BACKUP_ROOT="/mnt/backup/nas"
CURRENT="$BACKUP_ROOT/current"

DATE=$(date +%Y-%m-%d_%H-%M)
SNAPNAME="snap-$DATE"
LOG_FILE="$BACKUP_ROOT/backup_log.txt"

# --- LOG FUNCTION ---
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# --- CHECK ZFS POOL ---
if ! zfs list backuppool >/dev/null 2>&1; then
    log "❌ Pool ZFS backuppool indisponible"
    exit 1
fi

# --- MOUNT ZFS DATASETS ---
log "Montage des datasets ZFS..."
zfs mount -a || { log "❌ Échec montage ZFS"; exit 1; }

mkdir -p "$NAS_MOUNT_BASE" "$CURRENT"

# --- CHECK FREE SPACE ---
AVAIL=$(df -h "$CURRENT" | awk 'NR==2 {print $4}')
log "Espace disponible sur disque de sauvegarde : $AVAIL"

# --- BACKUP LOOP ---
for SHARE in "${SHARES[@]}"; do
    SRC="$NAS_MOUNT_BASE/$SHARE"
    DEST="$CURRENT/$SHARE"

    log "▶ Montage SMB : $SHARE"
    mkdir -p "$SRC" "$DEST"

    if ! mount -t cifs "//$NAS_IP/$SHARE" "$SRC" \
        -o credentials="$CREDENTIALS_FILE",rw,iocharset=utf8,vers=3.0,nofail,soft; then
        log "❌ Échec montage SMB pour $SHARE"
        continue
    fi

    log "▶ rsync : $SHARE"
    if ! rsync -aH --delete \
        --exclude="#snapshot" --exclude="#recycle" --exclude="@eaDir" \
        --exclude="@recycle" --exclude="@tmp" --exclude=".SynoIndex*" \
        --exclude="@__thumb/" \
        --info=progress2 "$SRC/" "$DEST/"; then
        log "⚠️ Erreur rsync sur $SHARE"
    fi

    umount "$SRC"
    log "✔ $SHARE terminé"
done

# --- CREATE SNAPSHOT ---
log "Création du snapshot ZFS : $SNAPNAME"
zfs snapshot backuppool/nas/current@"$SNAPNAME" \
    || { log "❌ Échec snapshot ZFS"; exit 1; }

# --- SNAPSHOT ROTATION (7) ---
log "Rotation des snapshots (garder 7)"
SNAPS=$(zfs list -t snapshot -o name -s creation | grep "backuppool/nas/current@")

COUNT=0
for snap in $SNAPS; do
    COUNT=$((COUNT+1))
    if [ $COUNT -le 7 ]; then
        continue
    fi
    log "🗑 Suppression snapshot ancien : $snap"
    zfs destroy "$snap"
done

log "✅ Backup terminé le $DATE"
