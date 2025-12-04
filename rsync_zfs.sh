#!/bin/bash
# ==========================================
# Sauvegarde NAS Synology -> Disque externe ZFS (avec snapshots)
# ==========================================

# --- CONFIGURATION ---
NAS_IP="XXX.XXX.XXX.XXX"
CREDENTIALS_FILE="/root/.nas-credentials"  # format : username=XX_XXX / password=YYYY

SHARES=("CLONEZILLA" "DIVERS" "DONNEES" "homes" "LOGICIELS" "photo" "PHOTOSYNC" "STORAGE_ANALYZER")

NAS_MOUNT_BASE="/mnt/nas"
MOUNT_POINT="/mnt/backup"
BACKUP_BASE="$MOUNT_POINT/nas_backup"
CURRENT="$BACKUP_BASE/current"

DATE=$(date +%Y-%m-%d_%H-%M)
SNAPSHOT="$BACKUP_BASE/snapshots/snap-$DATE"

LOG_FILE="$BACKUP_BASE/backup_log.txt"

# --- FONCTION DE LOG ---
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# --- VÉRIFICATION DU DISQUE EXTERNE ---
if ! mount | grep -q "$MOUNT_POINT"; then
    log "Montage du disque externe..."
    sudo mkdir -p "$MOUNT_POINT"
    sudo mount /dev/sdb1 "$MOUNT_POINT" || { log "Erreur de montage du disque externe !"; exit 1; }
fi

# --- CRÉATION DU RÉPERTOIRE ACTUEL ---
sudo mkdir -p "$CURRENT"

# --- Vérification de l'espace disponible ---
AVAIL=$(df -h "$MOUNT_POINT" | tail -1 | awk '{print $4}')
log "Espace disponible sur disque de sauvegarde : $AVAIL"

# --- MONTAGE ET SYNCHRONISATION ---
for SHARE in "${SHARES[@]}"; do
    SRC="$NAS_MOUNT_BASE/$SHARE"
    DEST="$CURRENT/$SHARE"

    log ">>> Montage de $SHARE..."
    sudo mkdir -p "$SRC" "$DEST"

    # --- MODIFICATION ICI : arrêt du script en cas d'erreur de montage ---
    sudo mount -t cifs "//$NAS_IP/$SHARE" "$SRC" -o credentials="$CREDENTIALS_FILE",rw,iocharset=utf8,vers=3.0 \
        || { log "Échec du montage de $SHARE — arrêt du script !"; exit 1; }

    log ">>> Synchronisation de $SHARE..."
    sudo rsync -aHAX --no-xattrs --delete \
        --exclude="#snapshot" --exclude="#recycle" --exclude="@eaDir/" --exclude="@recycle" \
        --exclude="@tmp" --exclude=".SynoIndex*" --exclude="@__thumb/" \
        --info=progress2 "$SRC/" "$DEST/" \
        || log "Erreur rsync sur $SHARE"

    log ">>> Démontage de $SHARE..."
    sudo umount "$SRC"
done

# --- CRÉATION DU SNAPSHOT ZFS ---
log "Création du snapshot ZFS : $SNAPSHOT"
sudo zfs snapshot backuppool/nas_backup$current@snap-$DATE || { log "Erreur lors du snapshot ZFS !"; exit 1; }

# --- ROTATION DES SNAPSHOTS (garder les 7 derniers) ---
OLD_SNAPSHOTS=$(sudo zfs list -t snapshot -o name | grep "backuppool/nas_backup$current@" | sort -r | tail -n +8)
for snap in $OLD_SNAPSHOTS; do
    log "Suppression ancien snapshot ZFS : $snap"
    sudo zfs destroy "$snap"
done

log "Sauvegarde terminée le $DATE"
