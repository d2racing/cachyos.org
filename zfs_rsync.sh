#!/bin/bash
# ==========================================
# Sauvegarde NAS Synology -> Disque externe ZFS (avec snapshots)
# ==========================================

# --- CONFIGURATION ---
NAS_IP="XXX.XXX.XXX.XXX"
CREDENTIALS_FILE="/root/.nas-credentials"  # username=XXX / password=YYY
SHARES=("CLONEZILLA" "DIVERS" "DONNEES" "homes" "LOGICIELS" "photo" "PHOTOSYNC" "STORAGE_ANALYZER")

NAS_MOUNT_BASE="/mnt/nas"
BACKUP_ROOT="/mnt/backup/nas_backup"
CURRENT="$BACKUP_ROOT/current"
SNAPDIR="$BACKUP_ROOT/snapshots"

DATE=$(date +%Y-%m-%d_%H-%M)
SNAPNAME="snap-$DATE"
LOG_FILE="$BACKUP_ROOT/backup_log.txt"

# --- LOG FUNCTION ---
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# --- VERIFY & MOUNT ZFS POOL ---
if ! mountpoint -q /mnt/backup; then
    log "Montage du pool ZFS..."
    sudo zfs mount -a || { log "Erreur de montage du pool ZFS"; exit 1; }
fi

mkdir -p "$NAS_MOUNT_BASE" "$CURRENT" "$SNAPDIR"

# --- CHECK FREE SPACE ---
AVAIL=$(df -h "$BACKUP_ROOT" | tail -1 | awk '{print $4}')
log "Espace disponible sur disque de sauvegarde : $AVAIL"

# --- PROCESS EACH SHARE ---
for SHARE in "${SHARES[@]}"; do
    SRC="$NAS_MOUNT_BASE/$SHARE"
    DEST="$CURRENT/$SHARE"

    log ">>> Montage de $SHARE..."
    sudo mkdir -p "$SRC" "$DEST"

    sudo mount -t cifs "//$NAS_IP/$SHARE" "$SRC" \
        -o credentials="$CREDENTIALS_FILE",rw,iocharset=utf8,vers=3.0 \
        || { log "Échec du montage de $SHARE — arrêt !"; exit 1; }

    log ">>> Synchronisation de $SHARE..."
    sudo rsync -aHAX --no-xattrs --delete \
        --exclude="#snapshot" --exclude="#recycle" --exclude="@eaDir" \
        --exclude="@recycle" --exclude="@tmp" --exclude=".SynoIndex*" \
        --exclude="@__thumb/" \
        --info=progress2 "$SRC/" "$DEST/" \
        || log "Erreur rsync sur $SHARE"

    log ">>> Démontage de $SHARE..."
    sudo umount "$SRC"
done

# --- CREATE SNAPSHOT ---
log "Création du snapshot ZFS : $SNAPNAME"
sudo zfs snapshot backuppool/nas_backup/current@"$SNAPNAME" \
    || { log "Erreur lors du snapshot ZFS !"; exit 1; }

# --- SNAPSHOT ROTATION (keep 7) ---
log "Rotation des snapshots..."
SNAPS=$(sudo zfs list -t snapshot -o name | grep "backuppool/nas_backup/current@" | sort -r)

COUNT=0
for snap in $SNAPS; do
    COUNT=$((COUNT+1))
    if [ $COUNT -gt 7 ]; then
        log "Suppression snapshot ancien : $snap"
        sudo zfs destroy "$snap"
    fi
done

log "Sauvegarde terminée le $DATE"
