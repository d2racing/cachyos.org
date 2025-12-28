#!/bin/bash
set -euo pipefail

# Nombre de snapshots @auto à garder par dataset
KEEP_LAST=${1:-5}

# Dataset principal à nettoyer
TARGET="zpcachyos/ROOT/cos"

echo "🧹 Nettoyage des snapshots @auto pour $TARGET (garder $KEEP_LAST derniers)..."

# Variables pour résumé global
TOTAL_DELETED=0
TOTAL_REMAINING=0

# Liste tous les datasets concernés (dataset principal + ses sous-datasets)
DATASETS=($(zfs list -H -o name -r "$TARGET"))

for DS in "${DATASETS[@]}"; do
    # Lister uniquement les snapshots @auto de ce dataset
    SNAPS=($(zfs list -H -t snapshot -o name -s creation "$DS" | grep "^$DS@auto" || true))

    TOTAL=${#SNAPS[@]}
    TO_DELETE=$((TOTAL - KEEP_LAST))

    if (( TO_DELETE <= 0 )); then
        echo "📂 $DS : Rien à supprimer, $TOTAL snapshots existants."
        TOTAL_REMAINING=$((TOTAL_REMAINING + TOTAL))
        continue
    fi

    echo "📂 $DS : Suppression de $TO_DELETE snapshots anciens..."

    for SNAP in "${SNAPS[@]:0:TO_DELETE}"; do
        echo "  🔥 Destruction de $SNAP..."
        zfs destroy "$SNAP"
    done

    REMAINING=$(zfs list -H -t snapshot -o name "$DS" | grep "^$DS@auto" | wc -l)
    echo "✅ $DS : Nettoyage terminé. Restent $REMAINING snapshots."

    # Mettre à jour le résumé global
    TOTAL_DELETED=$((TOTAL_DELETED + TO_DELETE))
    TOTAL_REMAINING=$((TOTAL_REMAINING + REMAINING))
done

# --- Résumé global ---
echo
echo "📊 Résumé global :"
echo "  🔥 Snapshots supprimés : $TOTAL_DELETED"
echo "  ✅ Snapshots restants : $TOTAL_REMAINING"

