#!/bin/bash
# ============================================================
# ZFS + DISK HEALTH DASHBOARD
# Vérification complète : SMART, ZFS, espace, snapshots, scrub
# Version SAFE — sans speed test
# ============================================================

set -o pipefail

POOL="backuppool"
DISK="/dev/sdb"

# -------- Colors --------
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
BOLD="\e[1m"
NC="\e[0m"

header() {
    echo -e "\n${BOLD}${BLUE}=== $1 ===${NC}"
}

# ============================================================
# 1. SMART HEALTH
# ============================================================
header "SMART HEALTH — $DISK"

if command -v smartctl >/dev/null 2>&1; then
    smartctl -H "$DISK" 2>/dev/null || smartctl -H -d sat "$DISK"
    echo
    smartctl -A "$DISK" 2>/dev/null || smartctl -A -d sat "$DISK" \
        | grep -Ei "reallocated|pending|offline|error"
else
    echo -e "${YELLOW}SMARTCTL non installé (pacman -S smartmontools)${NC}"
fi

# ============================================================
# 2. ZPOOL HEALTH
# ============================================================
header "ZFS POOL HEALTH — $POOL"

zpool list "$POOL" || exit 1
echo
zpool status "$POOL" | sed 's/^/  /'

HEALTH=$(zpool get -H -o value health "$POOL")
if [[ "$HEALTH" != "ONLINE" ]]; then
    echo -e "${RED}⚠ Pool health: $HEALTH${NC}"
else
    echo -e "${GREEN}✔ Pool ONLINE${NC}"
fi

# ============================================================
# 3. DATASET USAGE
# ============================================================
header "DATASET USAGE"

zfs list -r "$POOL"

header "SPACE BREAKDOWN"
zfs list -pHr -o name,used,available,refer,compressratio "$POOL"

# ============================================================
# 4. SNAPSHOTS
# ============================================================
header "SNAPSHOTS"

zfs list -t snapshot -o name,used,refer -s creation -r "$POOL"

# ============================================================
# 5. COMPRESSION
# ============================================================
header "COMPRESSION RATIOS"

zfs get -H -o name,value compressratio -r "$POOL"

# ============================================================
# 6. FREE SPACE CHECK
# ============================================================
header "FREE SPACE CHECK"

FREE=$(zfs list -Hp -o avail,used "$POOL" | awk '{print $1/($1+$2)*100}')
FREE_INT=${FREE%.*}

if (( FREE_INT < 30 )); then
    echo -e "${YELLOW}⚠ Free space below 30% ($FREE_INT%) — ZFS perf may degrade${NC}"
else
    echo -e "${GREEN}✔ Free space OK ($FREE_INT%)${NC}"
fi

# ============================================================
# 7. ZFS ERROR CHECK (fiable)
# ============================================================
header "ZFS ERROR CHECK"

ERRORS=$(zpool status "$POOL" | awk '/errors:/ {print $2}')
if [[ "$ERRORS" != "No" ]]; then
    echo -e "${RED}⚠ ZFS reports errors: $ERRORS${NC}"
else
    echo -e "${GREEN}✔ No ZFS errors reported${NC}"
fi

# ============================================================
# 8. ZFS EVENTS
# ============================================================
header "ZFS EVENTS (recent)"

zpool events -v | tail -n 20 | sed 's/^/  /'

# ============================================================
# 9. SCRUB STATUS
# ============================================================
header "SCRUB STATUS"

zpool status "$POOL" | grep -A2 "scan:" | sed 's/^/  /'

# ============================================================
# 10. ZFS TUNING CHECK (backup best practices)
# ============================================================
header "ZFS DATASET TUNING"

zfs get compression,atime,recordsize,sync,xattr "$POOL"

# ============================================================
# 11. RESET ERROR COUNTERS (confirmation)
# ============================================================
header "RESET ERROR COUNTERS"

read -p "Confirmer le reset des compteurs d'erreurs ZFS ? (o/n) : " CLR
if [[ "$CLR" =~ ^[Oo]$ ]]; then
    zpool clear "$POOL"
    echo -e "${GREEN}✔ Compteurs remis à zéro${NC}"
else
    echo -e "${BLUE}✔ Reset annulé${NC}"
fi

# ============================================================
# 12. SCRUB OPTIONNEL
# ============================================================
header "SCRUB OPTION"

read -p "Lancer un scrub maintenant ? (o/n) : " REP
if [[ "$REP" =~ ^[Oo]$ ]]; then
    echo -e "${YELLOW}⚡ Scrub lancé sur $POOL${NC}"
    zpool scrub "$POOL"
else
    echo -e "${BLUE}✔ Scrub non lancé${NC}"
fi

# ============================================================
# DONE
# ============================================================
echo -e "\n${BOLD}${GREEN}✓ Dashboard terminé.${NC}\n"
