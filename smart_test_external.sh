#!/bin/bash

# sudo pacman -S smartmontools

set -euo pipefail

# ========= CONFIG =========
DISK="${1:-/dev/sdb}"   # ex: /dev/sdb
SMART_OPTS="-d sat"     # requis pour la plupart des disques USB
# ==========================

if [[ "$DISK" == "/dev/sdX" ]]; then
  echo "❌ Veuillez spécifier un disque, ex:"
  echo "   sudo $0 /dev/sdb"
  exit 1
fi

echo "======================================="
echo "🩺 Test SMART pour $DISK"
echo "======================================="

echo "🔍 Infos SMART de base"
smartctl $SMART_OPTS -i "$DISK"

echo
echo "📊 Santé SMART"
smartctl $SMART_OPTS -H "$DISK"

echo
echo "⚡ Lancement SMART SHORT test"
smartctl $SMART_OPTS -t short "$DISK"

echo "⏳ Attente 2 minutes..."
sleep 120

echo
echo "📋 Résultat SMART SHORT"
smartctl $SMART_OPTS -l selftest "$DISK"

echo
echo "🐢 Lancement SMART LONG test (peut prendre plusieurs heures)"
smartctl $SMART_OPTS -t long "$DISK"

echo
echo "ℹ️  Le test long est en cours."
echo "👉 Pour vérifier plus tard :"
echo "   smartctl $SMART_OPTS -l selftest $DISK"

echo "ℹ️  Un dernier stress test"
sudo dd if=/dev/sdb of=/dev/null bs=1M status=progress
