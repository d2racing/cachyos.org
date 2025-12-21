#!/bin/bash
set -euo pipefail

echo "========================================"
echo " SMART TEST DISQUE DUR EXTERNE"
echo "========================================"
echo

# Liste les disques
lsblk -d -o NAME,SIZE,MODEL,TRAN
echo
read -rp "👉 Entrez le disque à tester (ex: sdb) : " DISK
DEVICE="/dev/$DISK"

if [[ ! -b "$DEVICE" ]]; then
    echo "❌ Disque invalide"
    exit 1
fi

echo
echo "🔍 Informations SMART"
echo "----------------------------------------"
smartctl -i -d sat "$DEVICE" || true

echo
echo "📊 État SMART actuel"
echo "----------------------------------------"
smartctl -H -d sat "$DEVICE" || true

echo
echo "🧪 Lancement SMART SHORT TEST"
echo "----------------------------------------"
smartctl -t short -d sat "$DEVICE"

SHORT_TIME=$(sudo smartctl -c -d sat "$DEVICE" | awk '/Short self-test routine/ {print $6}')
echo "⏳ Attente $SHORT_TIME secondes..."
sleep "${SHORT_TIME:-120}"

echo
echo "📄 Rapport après SHORT TEST"
echo "----------------------------------------"
smartctl -a -d sat "$DEVICE"

echo
read -rp "👉 Voulez-vous lancer le SMART LONG TEST ? (oui/non) : " CONFIRM

if [[ "$CONFIRM" != "oui" ]]; then
    echo "⏹ Test long annulé."
    exit 0
fi

echo
echo "🧪 Lancement SMART LONG TEST (DERNIÈRE ÉTAPE)"
echo "----------------------------------------"
smartctl -t long -d sat "$DEVICE"

LONG_TIME=$(sudo smartctl -c -d sat "$DEVICE" | awk '/Long self-test routine/ {print $6}')
echo "⏳ Attente estimée : $LONG_TIME secondes"
echo "⚠ Ne débranchez PAS le disque"
sleep "${LONG_TIME:-3600}"

echo
echo "📄 Rapport FINAL après LONG TEST"
echo "----------------------------------------"
smartctl -a -d sat "$DEVICE"

echo
echo "✅ Tests SMART terminés"
