#!/bin/bash
# ============================================================
# ZFS POOL DASHBOARD — Health, Space, Snapshots, Compression
# ============================================================

POOL="backuppool"

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
BOLD="\e[1m"
NC="\e[0m"

header() {
    echo -e "\n${BOLD}${BLUE}=== $1 ===${NC}"
}

# --- Pool Health ---
header "ZFS POOL HEALTH"
zpool list $POOL
echo
zpool status $POOL | sed 's/^/  /'

# --- Dataset Usage ---
header "DATASET USAGE"
zfs list -r $POOL

# --- Snapshot Summary ---
header "SNAPSHOTS"
zfs list -t snapshot -o name,used,refer -s creation -r $POOL

# --- Space Breakdown ---
header "SPACE BREAKDOWN (used, available)"
zfs list -pHr -o name,used,available,refer,compressratio $POOL

# --- Compression ---
header "COMPRESSION RATIOS"
zfs get -o name,value -H compressratio -r $POOL

# --- Pool Warnings ---
header "WARNINGS"

HEALTH=$(zpool get -H -o value health $POOL)
if [[ "$HEALTH" != "ONLINE" ]]; then
    echo -e "${RED}⚠ Pool Health Issue: $HEALTH${NC}"
else
    echo -e "${GREEN}✔ Pool is Healthy${NC}"
fi

# Free space warning
FREE=$(zfs list -Hp -o avail,used $POOL | awk '{print $1/($1+$2)*100}')
FREE_INT=${FREE%.*}

if (( FREE_INT < 20 )); then
    echo -e "${YELLOW}⚠ Free space below 20% ($FREE_INT% remaining)${NC}"
else
    echo -e "${GREEN}✔ Sufficient free space ($FREE_INT% available)${NC}"
fi

# Error check
read READ WRITE CKSUM <<< $(zpool status $POOL | grep ONLINE | awk '{print $3, $4, $5}')

if (( READ > 0 || WRITE > 0 || CKSUM > 0 )); then
    echo -e "${RED}⚠ Errors Detected: READ=$READ WRITE=$WRITE CKSUM=$CKSUM${NC}"
else
    echo -e "${GREEN}✔ No I/O or Checksum Errors${NC}"
fi

# --- Scrub Status ---
header "SCRUB STATUS"
zpool status $POOL | grep -A2 "scan:" | sed 's/^/  /'

echo -e "\n${BOLD}Dashboard complete.${NC}\n"
