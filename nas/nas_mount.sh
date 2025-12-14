#!/bin/bash
echo 'start'
# ==========================================
# Montage du NAS
# ==========================================

# --- CONFIGURATION ---
NAS_IP="xxx.xxx.x.xxx"
CREDENTIALS_FILE="/root/.nas-credentials"  # format : username=XX_XXX / password=YYYY
SHARES=("CLONEZILLA" "DIVERS" "DONNEES" "homes" "LOGICIELS" "photo" "PHOTOSYNC" "STORAGE_ANALYZER")
NAS_MOUNT_BASE="/mnt/NAS"

# --- MONTAGE ET SYNCHRONISATION ---
for SHARE in "${SHARES[@]}"; do
    SRC="$NAS_MOUNT_BASE/$SHARE"
    echo ">>> Montage de $SHARE..."
    sudo mkdir -p "$SRC"

    if ! sudo mount -t cifs "//$NAS_IP/$SHARE" "$SRC" \
         -o credentials="$CREDENTIALS_FILE",rw,iocharset=utf8,vers=3.0,uid=1000,gid=1000; then
        
        echo "❌ Échec du montage de $SHARE"
        echo "⛔ Arrêt complet du script."
        exit 1
    fi
done

echo "✔ Tous les partages ont été montés avec succès."
