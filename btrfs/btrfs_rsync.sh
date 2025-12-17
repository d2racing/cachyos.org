#!/bin/bash
# ==========================================
# Sauvegarde NAS Synology -> Disque externe Btrfs
# Avec dry-run, confirmation utilisateur et snapshots uniformes (@auto)
# ==========================================

set -eo pipefail

# --- CONFIGURATION ---
NAS_IP="192.168.2.250"
CREDENTIALS_FILE="/root/.nas-credentials"

SHARES=("CLONEZILLA" "DIVERS" "DONNEES" "homes" "LOGICIELS" "photo" "PHOTOSYNC" "STORAGE_ANALYZER")

NAS_MOUNT_BASE="/mnt/nas"
MOUNT_POINT="/mnt/backup"
BACKUP_BASE="$MOUNT_POINT/nas_backup"
CURRENT="$BACKUP_BASE/current"

DATE=$(date +%Y-%m-%d_%H-%M)
SNAPNAME="auto-$DATE"
SNAPSHOT="$BACKUP_BASE/$SNAPNAME"

LOG_FILE="$BACKUP_BASE/backup_log.txt"

ANY_CHANGE=0
KEEP_LAST=30

# --- LOG ---
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# --- PREVIEW + CONFIRMATION ---
preview_and_confirm() {
    local SRC="$1"
    local DEST="$2"
    local SHARE="$3"

    log ">>> Dry-run rsync pour $SHARE"

    echo
    echo "========== CHANGEMENTS POUR $SHARE =========="
    echo

    PREVIEW=$(sudo rsync -aHAX --no-xattrs --delete \
        --exclude="#snapshot" --exclude="#recycle" --exclude="@eaDir/" --exclude="@recycle" \
        --exclude="@tmp" --exclude=".SynoIndex*" --exclude="@__thumb/" \
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
        o|O|y|Y) return 0 ;;
        *) log "Synchronisation annulée pour $SHARE"; return 1 ;;
    esac
}

# --- MONTAGE DISQUE EXTERNE ---
if ! mount | grep -q "$MOUNT_POINT"; then
    log "Montage du disque externe..."
    sudo mkdir -p "$MOUNT_POINT"
    sudo mount /dev/sdb1 "$MOUNT_POINT" || { log "Erreur montage disque externe"; exit 1; }
fi

# --- DOSSIER COURANT ---
sudo mkdir -p "$CURRENT"

# --- ESPACE DISQUE ---
AVAIL=$(df -h "$MOUNT_POINT" | tail -1 | awk '{print $4}')
log "Espace disponible : $AVAIL"

# --- BOUCLE PARTAGES ---
for SHARE in "${SHARES[@]}"; do
    SRC="$NAS_MOUNT_BASE/$SHARE"
    DEST="$CURRENT/$SHARE"

    log ">>> Traitement de $SHARE"

    sudo mkdir -p "$SRC" "$DEST"

    sudo mount -t cifs "//$NAS_IP/$SHARE" "$SRC" \
        -o credentials="$CREDENTIALS_FILE",rw,iocharset=utf8,vers=3.0 \
        || { log "Échec montage $SHARE — arrêt"; exit 1; }

    if preview_and_confirm "$SRC" "$DEST" "$SHARE"; then
        log ">>> Lancement rsync réel pour $SHARE"

        sudo rsync -aHAX --no-xattrs --delete \
            --exclude="#snapshot" --exclude="#recycle" --exclude="@eaDir/" --exclude="@recycle" \
            --exclude="@tmp" --exclude=".SynoIndex*" --exclude="@__thumb/" \
            --info=progress2 \
            "$SRC/" "$DEST/" \
            && ANY_CHANGE=1 \
            || log "Erreur rsync sur $SHARE"
    else
        log ">>> Aucun changement appliqué pour $SHARE"
    fi

    sudo sync
    sudo umount "$SRC"
done

# --- SNAPSHOT BTRFS ---
if [ "$ANY_CHANGE" -eq 1 ]; then
    log "Création snapshot Btrfs : $SNAPSHOT"
    sudo btrfs subvolume snapshot -r "$CURRENT" "$SNAPSHOT" \
        || { log "Erreur snapshot"; exit 1; }
else
    log "Aucun changement global — snapshot ignoré"
fi

# --- ROTATION (KEEP_LAST snapshots auto) ---
log "Rotation des snapshots Btrfs (garder $KEEP_LAST derniers)"
OLD_SNAPSHOTS=$(ls -dt "$BACKUP_BASE"/auto-* | tail -n +$((KEEP_LAST+1)))

for snap in $OLD_SNAPSHOTS; do
    log "Suppression ancien snapshot : $snap"
    sudo btrfs subvolume delete "$snap"
done

log "Sauvegarde terminée le $DATE"
