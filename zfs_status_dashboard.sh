#!/bin/bash
# ============================================================
# ZFS + DISK HEALTH DASHBOARD
# Vérification complète : SMART, ZFS, erreurs, usage, snapshots
# ============================================================

POOL="backuppool"
DISK="/dev/sdb"   # ton disque externe physique

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
# 1. Vérification SMART (Statut matériel du disque)
# ============================================================
header "SMART HEALTH — $DISK"

if command -v smartctl >/dev/null 2>&1; then
    smartctl -H $DISK
    echo
    smartctl -A $DISK | grep -Ei "reallocated|pending|offline|error"
else
    echo -e "${YELLOW}SMARTCTL non installé. Installe: sudo pacman -S smartmontools${NC}"
fi


# ============================================================
# 2. État général du pool ZFS
# ============================================================
header "ZFS POOL HEALTH — $POOL"

zpool list $POOL
echo
zpool status $POOL | sed 's/^/  /'

HEALTH=$(zpool get -H -o value health $POOL)

if [[ "$HEALTH" != "ONLINE" ]]; then
    echo -e "${RED}⚠ Pool Health Issue: $HEALTH${NC}"
else
    echo -e "${GREEN}✔ Pool is Healthy${NC}"
fi


# ============================================================
# 3. Espace ZFS
# ============================================================
header "DATASET USAGE"

zfs list -r $POOL


header "SPACE BREAKDOWN"
zfs list -pHr -o name,used,available,refer,compressratio $POOL


# ============================================================
# 4. Snapshots
# ============================================================
header "SNAPSHOTS"

zfs list -t snapshot -o name,used,refer -s creation -r $POOL


# ============================================================
# 5. Compression
# ============================================================
header "COMPRESSION RATIOS"

zfs get -o name,value -H compressratio -r $POOL


# ============================================================
# 6. Vérification de l'espace libre
# ============================================================
header "FREE SPACE CHECK"

FREE=$(zfs list -Hp -o avail,used $POOL | awk '{print $1/($1+$2)*100}')
FREE_INT=${FREE%.*}

if (( FREE_INT < 20 )); then
    echo -e "${YELLOW}⚠ Free space below 20% ($FREE_INT% remaining)${NC}"
else
    echo -e "${GREEN}✔ Sufficient free space ($FREE_INT% available)${NC}"
fi


# ============================================================
# 7. Vérification des erreurs (I/O, checksum)
# ============================================================
header "POOL ERROR CHECK"

READ=0; WRITE=0; CKSUM=0
read READ WRITE CKSUM <<< $(zpool status $POOL | grep ONLINE | awk '{print $3, $4, $5}')

if (( READ > 0 || WRITE > 0 || CKSUM > 0 )); then
    echo -e "${RED}⚠ Errors Detected: READ=$READ WRITE=$WRITE CKSUM=$CKSUM${NC}"
else
    echo -e "${GREEN}✔ No I/O or Checksum Errors${NC}"
fi


# ============================================================
# 8. Événements ZFS (erreurs passées)
# ============================================================
header "ZFS EVENTS (history)"

zpool events -v | sed 's/^/  /'


# ============================================================
# 9. Scrub Status
# ============================================================
header "SCRUB STATUS"

zpool status $POOL | grep -A2 "scan:" | sed 's/^/  /'


# ============================================================
# 10. Test lecture disque (non destructif)
# ============================================================
header "DISK READ TEST (dd — 2GB)"

dd if=$DISK of=/dev/null bs=1M count=2048 status=progress


# ============================================================
# 11. Reset errors (optionnel, sécurisé)
# ============================================================
header "RESET ERROR COUNTERS"

zpool clear $POOL
echo -e "${GREEN}✔ zpool clear effectué (compteurs remis à zéro)${NC}"


# ============================================================
# Done
# ============================================================
echo -e "\n${BOLD}${GREEN}✓ Dashboard complete.${NC}\n"
