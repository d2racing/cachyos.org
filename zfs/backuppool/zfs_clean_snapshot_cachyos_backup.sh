#!/bin/bash
set -euo pipefail

############################################
# CONFIGURATION
############################################
# Nombre de snapshots @auto à garder par dataset (paramètre 1, défaut 5)
KEEP_LAST=${1:-2}
TARGET="backuppool/cachyos_backup"

echo "🧹 Nettoyage des snapshots @auto pour $TARGET (garder $KEEP_LAST derniers)..."

############################################
# VARIABLES POUR RÉSUMÉ
############################################
TOTAL_DELETED=0
TOTAL_REMAINING=0

############################################
# TRAITEMENT DES DATASETS
############################################
# Liste dataset principal + sous-datasets
DATASETS=($(zfs list -H -o name -r "$TARGET"))

for DS in "${DATASETS[@]}"; do
    # Lister les snapshots @auto triés par création
    SNAPS=($(zfs list -H -t snapshot -o name -s creation "$DS" | grep "^$DS@auto" || true))

    TOTAL=${#SNAPS[@]}
    TO_DELETE=$((TOTAL - KEEP_LAST))

    if (( TO_DELETE <= 0 )); then
        echo "📂 $DS : Rien à supprimer, $TOTAL snapshots existants."
        TOTAL_REMAINING=$((TOTAL_REMAINING + TOTAL))
        continue
    fi

    echo "📂 $DS : Suppression de $TO_DELETE snapshots anciens..."

    # Supprimer les snapshots les plus anciens
    for SNAP in "${SNAPS[@]:0:TO_DELETE}"; do
        echo "  🔥 Destruction de $SNAP..."
        zfs destroy "$SNAP"
    done

    REMAINING=$(zfs list -H -t snapshot -o name "$DS" | grep "^$DS@auto" | wc -l)
    echo "✅ $DS : Nettoyage terminé. Restent $REMAINING snapshots."

    TOTAL_DELETED=$((TOTAL_DELETED + TO_DELETE))
    TOTAL_REMAINING=$((TOTAL_REMAINING + REMAINING))
done

############################################
# RÉSUMÉ GLOBAL
############################################
echo
echo "📊 Résumé global :"
echo "  🔥 Snapshots supprimés : $TOTAL_DELETED"
echo "  ✅ Snapshots restants : $TOTAL_REMAINING"

