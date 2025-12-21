#!/bin/bash
set -euo pipefail

DEVICE="/dev/sdb"
MONTAGE="/dev/sdb1"
REPERTOIRE="/mnt/backup"

mount $MONTAGE $REPERTOIRE

echo "========================================"
echo "  BTRFS SCRUB — Vérification intégrité"
echo "========================================"
echo
echo "🔎 Disque cible : $DEVICE"
echo

# Vérification du disque
if [[ ! -b "$DEVICE" ]]; then
    echo "❌ $DEVICE n'existe pas"
    exit 1
fi

# Trouver une partition Btrfs montée sur ce disque
MOUNTPOINT=$(lsblk -ln -o NAME,FSTYPE,MOUNTPOINT "$DEVICE" | \
             awk '$2=="btrfs" && $3!="" {print $3; exit}')

if [[ -z "$MOUNTPOINT" ]]; then
    echo "❌ Aucune partition Btrfs montée trouvée sur $DEVICE"
    echo "👉 Montez le disque avant de lancer le scrub"
    exit 1
fi

echo "📍 Partition Btrfs montée sur : $MOUNTPOINT"
echo

echo "🧪 Démarrage du scrub Btrfs"
echo "----------------------------------------"
sudo btrfs scrub start -B "$MOUNTPOINT"

echo
echo "📄 Rapport du scrub"
echo "----------------------------------------"
sudo btrfs scrub status "$MOUNTPOINT"

echo
echo "✅ Scrub terminé avec succès"
